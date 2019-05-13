library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_arith.all;

entity memory is
	generic
	(
		DATA_WIDTH_IN	:	natural	:= 8;
		ADDR_WIDTH_IN	:	natural	:= 16
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

architecture arc_memory of memory is
subtype word_t is std_logic_vector((DATA_WIDTH_IN-1) downto 0);
type memory_t is array(2**ADDR_WIDTH_IN-1 downto 0) of word_t;
signal pilha		: memory_t;
--attribute pilha_init_file	: string;
--attribute pilha_init_file of pilha	: signal is "iniciarPilha.mif";

signal addr_reg	: natural range 0 to 2**ADDR_WIDTH_IN-1;
signal endereco_read	: natural range 0 to 2**ADDR_WIDTH_IN-1;

signal end_write	:	natural range 0 to 2**ADDR_WIDTH_IN-1;

begin
	endereco_read <= to_integer(unsigned(addr_in));
	end_write <= endereco_read + 0;


	process(clk)
	begin
		if(rising_edge(clk)) then
			if(ctrl_in='1') then
				pilha(end_write) <= data_in;
			end if;
		end if;
	end process;

	data_out <= pilha(end_write);
end arc_memory;