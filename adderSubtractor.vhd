library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adderSubtractor is
	generic
	(
		DATA_WIDTH_IN	: natural
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
	s_add		<=  std_logic_vector(unsigned(data_in) + 1);
	s_sub		<=  std_logic_vector(unsigned(data_in) - 1);



	data_out <= s_add when (sel_in='0') else
						  s_sub;

end arc;
