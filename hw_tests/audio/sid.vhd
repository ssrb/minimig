--
-- hello_world.vhd
--
-- The ’Hello World’ example for FPGA programming.
--
-- Author: Martin Schoeberl (martin@jopdesign.com)
--
-- 2006-08-04 created
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sid is
	port (
		clk : in std_logic;
		led1 : out std_logic;
		led2 : out std_logic;
		led3 : out std_logic;
		led4 : out std_logic
	);
end sid;

architecture rtl of sid is

	constant CLK_FREQ : integer := 50000000;
	constant BLINK_FREQ : integer := 1;
	constant CNT_MAX : integer := CLK_FREQ/BLINK_FREQ/2-1;

	signal cnt : unsigned(24 downto 0);
	signal blink : std_logic;

	begin	process(clk)
		begin	if rising_edge(clk) then
			if cnt = CNT_MAX then
				cnt <= (others => '0');
				blink <= not blink;
			else
				cnt <= cnt + 1;
			end if;
		end if;
	end process;
	
	led1 <= blink;
	led2 <= blink;
	led3 <= blink;
	led4 <= blink;
	
end rtl;