library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;

entity memory is
	generic
	(
		DATA_WIDTH_IN	:	natural;
		ADDR_WIDTH_IN	:	natural
	);

	port
	(
		clk			   	: in std_logic;
		ctrl_in		    : in std_logic;
		addr_in	      	: in std_logic_vector((ADDR_WIDTH_IN-1) downto 0);
		data_in       	: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_out		: out std_logic_vector((DATA_WIDTH_IN-1) downto 0)
	);
end entity;

architecture arc of memory is
subtype word_t is std_logic_vector((DATA_WIDTH_IN-1) downto 0);
type memory_t is array(2**ADDR_WIDTH_IN-1 downto 0) of word_t;
signal pilha		: memory_t;
--attribute pilha_init_file	: string;
--attribute pilha_init_file of pilha	: signal is "iniciarPilha.mif";

signal addr	: natural range 0 to 2**ADDR_WIDTH_IN-1;


begin
	addr <= to_integer(unsigned(addr_in));


	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in='1') then
				pilha(addr) <= data_in;
			end if;
		end if;
	end process;

	data_out <= pilha(addr);		
end arc;
