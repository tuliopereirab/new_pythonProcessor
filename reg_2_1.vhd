library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reg_2_1 is
	generic
	(
		DATA_WIDTH_IN_1   	: natural   := 8;
        DATA_WIDTH_IN_2     : natural   := 8;
        DATA_WIDTH_OUT      : natural := 16
	);

	port
	(
		clk               : in std_logic;
		ctrl_in           : in std_logic;
		data_in_1         : in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
		data_in_2         : in std_logic_vector((DATA_WIDTH_IN_2-1) downto 0);
		data_out          : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end entity;

architecture regJump of reg_2_1 is
begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in='1') then
				data_out <= data_in_1 & data_in_2;
			end if;
		end if;
	end process;
end regJump;

architecture arc_reg of reg_2_1 is
signal reset_sig    : integer   := 0;
signal comp_1		: integer 	:= 1;
signal comp_Used	: std_logic_vector((DATA_WIDTH_IN_2-1) downto 0);
begin
	comp_Used <= std_logic_vector(to_unsigned(comp_1, DATA_WIDTH_IN_2));
    process(clk)
    begin
        if(rising_edge(clk)) then
            if(data_in_2=comp_Used) then
                data_out <= std_logic_vector(to_unsigned(reset_sig, DATA_WIDTH_OUT));
            elsif(ctrl_in='1') then
                data_out <= data_in_1((DATA_WIDTH_OUT-1) downto 0);
            end if;
        end if;
    end process;
end arc_reg;
