library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_2_1_reset is
	generic
	(
		DATA_WIDTH_IN_1   	: natural;
        DATA_WIDTH_OUT      : natural
	);

	port
	(
		clk               : in std_logic;
		ctrl_in           : in std_logic;
		reset_in          : in std_logic;
		data_in_1         : in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
		data_out          : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end entity;

architecture arc_reg of reg_2_1_reset is
-- signal reset_sig    : integer   := 0;
-- signal comp_1		: integer 	:= 1;
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(reset_in='1') then
                data_out <= std_logic_vector(to_unsigned(0, DATA_WIDTH_OUT));
            elsif(ctrl_in='1') then
                data_out <= data_in_1((DATA_WIDTH_OUT-1) downto 0);
            end if;
        end if;
    end process;
end arc_reg;
