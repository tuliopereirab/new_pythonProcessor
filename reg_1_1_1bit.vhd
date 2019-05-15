library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_1_1_1bit is
	port
	(
		clk					  : in std_logic;
		ctrl_in	              : in std_logic;
		data_in	              : in std_logic;
		data_out              : out std_logic
	);
end entity;

architecture arc_op	of reg_1_1_1bit is
signal integer_in	: integer;
begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in='1') then
				data_out <= data_in;
			end if;
		end if;
	end process;
end arc_op;

-- architecture arc_reg of reg_1_1 is
-- begin
-- 	process(clk)
-- 	begin
-- 		if(rising_edge(clk)) then
-- 			if(ctrl_in='1') then
-- 				data_out <= data_in;
-- 			end if;
-- 		end if;
-- 	end process;
-- end arc_reg;
