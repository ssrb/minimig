library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity NetSID is
	generic(
		-- Default setting :
		-- 1000000 baud, 8 data bits, 1 stop bit, 2^2 FIFO
		DBIT: integer := 8; 		-- #data bits
		SB_TICK: integer := 16; -- #ticks for stop bits, 16/24/32
										-- for 1/1.5/2 stopbits
		DVSR: integer := 3; 	-- baudrate divisor (1MBaud)
										-- DVSR = 50M / (16 * baudrate)
		DVSR_BIT: integer := 2 -- #bits of DVSR
	);
	port (
		reset_n : in  std_logic;	-- active low reset
		clk : in  std_logic;	-- main clock 50Mhz
		O_AUDIO_L : out std_logic;	-- PWM audio out
		O_AUDIO_R : out std_logic;	-- PWM audio out
		
		led_fifo_full_n, led_fifo_almost_full_n, led_fifo_almost_empty_n, led_fifo_empty_n	: out std_logic;

		rx	: in  std_logic;	-- RS232 data to FPGA
		tx	: out std_logic	-- RS232 data from FPGA
		);
	end;

architecture RTL of NetSID is

	type RAMtoSIDState is (
		stInit,
		stDelay1,
		stDelay2,
		stSync,
		stWait1,
		stWait2,
		stAddr,
		stData,
		stWrite,
		stIdle
	);

	signal reset: std_logic;
	
	signal clk_1MHz					: std_logic := '0';	--  1 Mhz
	signal clk_4MHz					: std_logic := '0';	--  4 Mhz

	signal srx						: std_logic;
	
	signal tx_data					: std_logic_vector(7 downto 0) := (others => '1');
	signal rx_data					: std_logic_vector(7 downto 0) := (others => '1');
	signal tx_full					: std_logic := '0';
	signal write_to_uart			: std_logic := '0';
	signal rx_data_present		: std_logic := '0';

	signal sid_state_reg, sid_state_next : RAMtoSIDState;
	signal sid_addr_reg, sid_addr_next : std_logic_vector( 4 downto 0) := (others => '0');
	signal sid_din_reg, sid_din_next	: std_logic_vector( 7 downto 0) := (others => '0');
	signal sid_we_reg, sid_we_next : std_logic;
	signal sid_audio : std_logic_vector(17 downto 0) := (others => '0');

	signal cycle_cnt_reg, cycle_cnt_next : std_logic_vector(20 downto 0) := (others => '0');

	signal audio_pwm				: std_logic := '0';
	
	signal fifo_data_out			: std_logic_vector( 7 downto 0);
	signal fifo_read_ack			: std_logic;
	signal fifo_empty				: std_logic;
	signal fifo_full				: std_logic;
	signal fifo_almost_empty_last : std_logic;
	signal fifo_almost_full_last : std_logic;
	signal fifo_almost_empty	: std_logic;
	signal fifo_almost_full		: std_logic;

	signal tick: std_logic;
	
begin

	reset <= not reset_n;
	
	O_AUDIO_L		<= audio_pwm;
	O_AUDIO_R		<= audio_pwm;

	-- M => 50M / (16 * baudrate)
	baud_gen_unit: entity work.mod_m_counter(arch)
	generic map(M => DVSR, N => DVSR_BIT)
	port map(clk => clk, reset => reset, q => open, max_tick => tick);
	
	clk01_unit: entity work.mod_m_counter(arch)
	generic map(M => 50, N => 6)
	port map(clk => clk, reset => reset, q => open, max_tick => clk_1MHz);
	
	clk04_unit: entity work.mod_m_counter(arch)
	generic map(M => 12, N => 4)
	port map(clk => clk, reset => reset, q => open, max_tick => clk_4MHz);
	
	uart_tx_unit: entity work.uart_tx(arch)
		generic map(DBIT => DBIT, SB_TICK => SB_TICK)
		port map(clk => clk, reset => reset, tx_start => write_to_uart,
					s_tick => tick, din => tx_data, tx_done_tick => open, tx => tx);

	rx_synchronizer: entity work.synchronizer(arch)
		port map(clk => clk, reset => reset, input => rx, output => srx);
					
	uart_rx_unit: entity work.uart_rx(arch)
		generic map(DBIT => DBIT, SB_TICK => SB_TICK)
		port map(clk => clk, reset => reset, rx => srx, s_tick => tick,
					rx_done_tick => rx_data_present, dout => rx_data);


rx_fifo: entity work.fifo_generator_v9_3
  PORT MAP (
    clk => clk,
    rst => reset,
    din => rx_data,
    wr_en => rx_data_present,
    rd_en => fifo_read_ack,
    dout => fifo_data_out,
    full => fifo_full,
    almost_full => fifo_almost_full,
    empty => fifo_empty,
    almost_empty => fifo_almost_empty
 );

	--rx_fifo: entity work.altera_fifo
	--port map(
	--	clock => clk,
	--	aclr => reset,
	--	data => rx_data,
	--	rdreq	=> fifo_read_ack,
	--	wrreq => rx_data_present,
	--	almost_empty => fifo_almost_empty,
	--	almost_full	=> fifo_almost_full,
	--	empty	=> fifo_empty,
	--	full 	=> fifo_full,
	--	q		=> fifo_data_out,
	--	usedw	=> open
	--);					

  -----------------------------------------------------------------------------
  -- SID 6581
  -----------------------------------------------------------------------------
	--
	-- Implementation of SID sound chip
	--
  u_sid6581 : entity work.sid6581
	port map (
		clk_1mhz			=> clk_1MHz,		-- main SID clock
		clk32				=> clk,				-- main clock signal
		reset				=> reset,			-- active high reset signal
		cs					=> '1',			-- active high  chip select
		we					=> sid_we_reg,		-- active high write enable
		addr				=> sid_addr_reg,	-- address lines 5 bits
		di					=> sid_din_reg,		-- data to chip, 8 bits
		do					=> open,			-- data from chip, 8 bits
		pot_x				=> x"00",		-- paddle input-X 8 bits
		pot_y				=> x"00",		-- paddle input-Y 8 bits
		audio_data		=> sid_audio	-- audio out 18 bits
	);


	-- copy data from FIFO to SID at cycle accurate rate
	fifo_to_sid : process (clk, reset)
	begin
		if reset = '1' then
			sid_state_reg	<= stInit;
			sid_addr_reg <= (others => '0');
			sid_din_reg <= (others => '0');
			sid_we_reg <= '0';
			
			cycle_cnt_reg <= (others => '0');
		elsif rising_edge(clk) then
			sid_state_reg <= sid_state_next;
			sid_addr_reg <= sid_addr_next;
			sid_din_reg <= sid_din_next;
			sid_we_reg <= sid_we_next;
			
			cycle_cnt_reg <= cycle_cnt_next;
		end if;
	end process;
	
	process (sid_state_reg, sid_addr_reg, sid_din_reg, sid_we_reg, cycle_cnt_reg, fifo_data_out, fifo_empty, clk_4MHz)
	begin
			fifo_read_ack <= '0';
			
			sid_state_next <= sid_state_reg;
			sid_addr_next <= sid_addr_reg;
			sid_din_next <= sid_din_reg;
			sid_we_next <= '0';
			
			cycle_cnt_next <= cycle_cnt_reg;
			
			case sid_state_reg is
				when stInit =>
					cycle_cnt_next	<= (others => '0');
					sid_state_next	<= stDelay1;
				when stDelay1 =>
					if fifo_empty = '0' then
						cycle_cnt_next(17 downto 10) <= fifo_data_out;	-- delay high
						fifo_read_ack	<= '1';
						sid_state_next	<= stDelay2;
					end if;
				when stDelay2 =>
					if fifo_empty = '0' then
						cycle_cnt_next(9 downto 2)  <= fifo_data_out;	-- delay low
						sid_state_next	<= stAddr;
						fifo_read_ack	<= '1';
					end if;
				when stAddr =>
					if fifo_empty = '0' then
						sid_addr_next <= fifo_data_out(4 downto 0);	-- address
						sid_state_next	<= stData;
						fifo_read_ack <= '1';
					end if;
				when stData =>
					if fifo_empty = '0' then
						sid_din_next <= fifo_data_out;					-- value
						sid_state_next	<= stSync;
						fifo_read_ack	<= '1';
					end if;
				when stSync =>
					if clk_4MHz = '1' then
						if cycle_cnt_reg = x"0000" then
							sid_state_next <= stWrite;
						else
							cycle_cnt_next <= cycle_cnt_reg - 1;		-- wait cycles x4 (since this runs at clk04)
							sid_state_next <= stSync;
						end if;
					end if;
				when stWrite =>
					sid_we_next		<= '1';
					sid_state_next	<= stDelay1;
				when others		=> null;
			end case;
	end process;
	
	u_dac: entity work.dac
	port map(
		clk_i				=> clk,
		reset				=> reset,
		dac_i				=> sid_audio(17 downto 8),
		dac_o				=> audio_pwm
	);
	
	-- debug test points
	led_fifo_full_n <= not fifo_full;
	led_fifo_almost_full_n <= not fifo_almost_full;
	led_fifo_almost_empty_n <= not fifo_almost_empty;
	led_fifo_empty_n <= not fifo_empty;
	
	process(clk, reset)
	begin
		if reset = '1' then
			fifo_almost_full_last <= '0';
			fifo_almost_empty_last <= '0';
		elsif rising_edge(clk) then
			fifo_almost_full_last <= fifo_almost_full;
			fifo_almost_empty_last <= fifo_almost_empty;
		end if;
	end process;

	write_to_uart <= (fifo_almost_full and not fifo_almost_full_last) or (fifo_almost_empty and not fifo_almost_empty_last);
	tx_data <= x"45" when fifo_almost_full = '1' else 
					x"53" when fifo_almost_empty = '1' else
					x"00";

end RTL;
