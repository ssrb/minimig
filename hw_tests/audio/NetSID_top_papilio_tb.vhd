--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   00:09:05 07/25/2011
-- Design Name:   
-- Module Name:   C:/Users/alex/workspace/NetSID/build/NetSID_tb.vhd
-- Project Name:  NetSID
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: NetSID
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use IEEE.std_logic_textio.all;

library std;
	use std.textio.all;

entity netsid_tb is
	generic(stim_file: string :="..\src\stim.txt");
end netsid_tb;

architecture behavior of netsid_tb is 

	-- component declaration for the unit under test (uut)

	component netsid
	port(
		i_reset   : in  std_logic;
		clk_in    : in  std_logic;
		led       : out std_logic;
		o_audio_l : out std_logic;
		o_audio_r : out std_logic;
		usb_txd   : in  std_logic;
		usb_rxd   : out std_logic
	);
	end component;

	-- Inputs
	file stimulus: text open read_mode is stim_file;
	signal i_reset    : std_logic := '1';
	signal clk_in     : std_logic := '0';
	signal usb_txd    : std_logic := '1';
	signal button     : std_logic := '1';

	-- Outputs
	signal o_audio_l  : std_logic := '0';
	signal o_audio_r  : std_logic := '0';
	signal usb_rxd    : std_logic := '1';
	signal led        : std_logic := '0';

	signal clock      : std_logic := '1';
	signal baud_run   : std_logic := '0';
	constant clock_period : time := 31.25 ns;
	constant baud_period  : time := 500 ns; -- 2Mbps
begin

	-- Instantiate the Unit Under Test (UUT)
	uut: netsid port map (
		i_reset 	 => i_reset,
		clk_in 	 => clock,
		o_audio_l => o_audio_l,
		o_audio_r => o_audio_r,
		led 		 => led,
		usb_txd   => usb_txd,
		usb_rxd   => usb_rxd
	);

	-- Clock process definitions
	clock_process :process
	begin
		clock <= not clock;
		wait for clock_period/2;
	end process;

  serial_in : process
		variable inline : line;
		variable bv : std_logic_vector(7 downto 0);
	begin
		if baud_run = '1' then
			while not endfile(stimulus) loop
				readline(stimulus, inline);		-- read a line
				for byte in 0 to 3 loop				-- 4 bytes per line
					hread(inline, bv);					-- convert hex byte to vector
					usb_txd <= '0';							-- start bit
					wait for baud_period;
					for i in 0 to 7 loop				-- bits 0 to 7
						usb_txd <= bv(i);
						wait for baud_period;
					end loop;
					usb_txd <= '1';							-- stop bit
					wait for baud_period;
				end loop;
			end loop;
		else
			wait for baud_period;
		end if;
	end process;

	-- Stimulus process
	stim_proc: process
	begin		
		i_reset <= '1';
		baud_run <= '0';
		wait for clock_period*5;
		i_reset <= '0';
		wait for clock_period*10;
		baud_run <= '1';
		wait;
	end process;

end;
