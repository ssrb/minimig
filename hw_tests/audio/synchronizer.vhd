library ieee;
use ieee.std_logic_1164.all;

entity synchronizer is
port (
	clk, reset: in std_logic;
	input: in std_logic;
	output: out std_logic
);
end synchronizer;

architecture arch of synchronizer is
	signal ff1, ff2: std_logic;
begin
	process(clk, reset)
	begin
		if reset = '1' then
			ff1 <= '1';
			ff2 <= '1';
			output <= '1';
		elsif clk'event and clk='1' then
			ff1 <= input;
			ff2 <= ff1;
			output <= ff2;
		end if;
	end process;
end arch;
