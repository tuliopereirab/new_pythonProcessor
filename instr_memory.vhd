library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instr_memory is
	generic
	(
		INSTRUCTION_WIDTH_IN	: natural	:= 16;
		ADDR_WIDTH_IN	: natural	:= 16;
		DATA_WIDTH_IN	: natural	:= 8
	);

	port
	(
		clk				 : in std_logic;
		addr_in		     : in std_logic_vector((ADDR_WIDTH_IN-1) downto 0);
		opCode_out	     : out std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		opArg_out		 : out std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		fullWord_out	 : out std_logic_vector((INSTRUCTION_WIDTH_IN-1) downto 0)
	);
end entity;

architecture arc_instr_memory of instr_memory is
subtype word_t is std_logic_vector((INSTRUCTION_WIDTH_IN-1) downto 0);   -- largura palavra
type memory_t is array(2**ADDR_WIDTH_IN-1 downto 0) of word_t;   -- largura do endereço (criação do array)
signal memInstr		: memory_t;
attribute ram_init_file	: string;
attribute ram_init_file of memInstr	: signal is "iniciarMemInstr.mif";

signal addr_reg	: natural range 0 to 2**ADDR_WIDTH_IN-1;
signal endereco_convert	: natural range 0 to 2**ADDR_WIDTH_IN-1;

signal instrFull	: std_logic_vector((INSTRUCTION_WIDTH_IN-1) downto 0);
begin
	endereco_convert <= to_integer(unsigned(addr_in));
	instrFull <= memInstr(endereco_convert);

	process(clk)
	begin
		if(rising_edge(clk)) then
			opArg_out <= instrFull(INSTRUCTION_WIDTH_IN-1 downto DATA_WIDTH_IN);
			opCode_out <= instrFull(DATA_WIDTH_IN-1 downto 0); -- MODELO DE INSTRUÇÃO: OPARG + OPCODE
		end if;
	end process;

	fullWord_out <= instrFull(INSTRUCTION_WIDTH_IN-1 downto 0);
end arc_instr_memory;
