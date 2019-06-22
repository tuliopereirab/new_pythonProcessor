library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity somador is
	generic
	(
		DATA_WIDTH_IN_1	: natural;
		DATA_WIDTH_IN_2 : natural;
		DATA_WIDTH_OUT	: natural
	);

	port
	(
		data_in_1			: in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
		data_in_2			: in std_logic_vector((DATA_WIDTH_IN_2-1) downto 0);
		data_out			: out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end entity;

architecture arc of somador is
signal s_add	: std_logic_vector((DATA_WIDTH_OUT-1) downto 0);
-- signal one  : integer   := 1;
begin
	s_add		<= std_logic_vector(unsigned(data_in_1) + unsigned(data_in_2));
	data_out <= s_add;

end arc;
