library ieee;
use ieee.std_logic_1164.all;

entity reg_2_2 is
	generic
	(
		DATA_WIDTH_IN_OUT_1	      : natural	:= 8; -- same size of read
    	DATA_WIDTH_IN_OUT_2	      : natural	:= 8 -- same size for write

	);

	port
	(
		clk						  : in std_logic;
		ctrl_in               	  : in std_logic_vector(1 downto 0);
		data_in_1				  : in std_logic_vector((DATA_WIDTH_IN_OUT_1-1) downto 0);	-- input read
		data_in_2			      : in std_logic_vector((DATA_WIDTH_IN_OUT_2-1) downto 0);   -- input write
		data_out_1		          : out std_logic_vector((DATA_WIDTH_IN_OUT_1-1) downto 0);  -- output read
		data_out_2				  : out std_logic_vector((DATA_WIDTH_IN_OUT_2-1) downto 0)   -- output write
	);
end entity;

architecture arc_reg of reg_2_2 is
begin
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in(0)='1') then
				data_out_1 <= data_in_1;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in(1)='1') then
				data_out_2 <= data_in_2;
			end if;
		end if;
	end process;
end arc_reg;
