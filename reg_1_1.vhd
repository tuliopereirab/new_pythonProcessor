library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_1_1 is
	generic
	(
		DATA_WIDTH_IN	: natural;
		DATA_WIDTH_OUT	: natural
	);

	port
	(
		clk					  : in std_logic;
		ctrl_in	              : in std_logic;
		data_in	              : in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_out              : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end entity;

architecture arc_op	of reg_1_1 is
signal integer_in	: integer;
begin
	integer_in <= to_integer(unsigned(data_in));
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in='1') then
				data_out <= std_logic_vector(to_unsigned(integer_in, DATA_WIDTH_OUT));
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
