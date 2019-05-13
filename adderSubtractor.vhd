library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

entity adderSubtractor is
	generic
	(
		DATA_WIDTH_IN	: natural	:= 8
	);

	port
	(
		sel_in    		: in std_logic;
		data_in			: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_out		: out std_logic_vector((DATA_WIDTH_IN-1) downto 0)
	);
end entity;

architecture arc of adderSubtractor is
signal s_add, s_sub	: std_logic_vector((DATA_WIDTH_IN-1) downto 0);
-- signal one  : integer   := 1;
begin
	s_add		<= data_in + std_logic_vector(to_unsigned(1, DATA_WIDTH_IN));
	s_sub		<= data_in - std_logic_vector(to_unsigned(1, DATA_WIDTH_IN));



	data_out <= s_add when (sel_in='0') else
						  s_sub;

end arc;
