library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux_2_1 is
    generic
    (
        DATA_WIDTH_IN_1     : natural;
        DATA_WIDTH_IN_2     : natural;
        DATA_WIDTH_OUT      : natural
    );
    port
    (
        sel_in      : in std_logic;
        data_in_1   : in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
        data_in_2   : in std_logic_vector((DATA_WIDTH_IN_2-1) downto 0);
        data_out    : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
    );
end entity;

architecture arc_mux of mux_2_1 is
signal int_input_1, int_input_2     : integer;
begin
    int_input_1 <= to_integer(unsigned(data_in_1));
    int_input_2 <= to_integer(unsigned(data_in_2));
    data_out <= std_logic_vector(to_unsigned(int_input_1, DATA_WIDTH_OUT)) when (sel_in='0') else
                std_logic_vector(to_unsigned(int_input_2, DATA_WIDTH_OUT));
end arc_mux;
