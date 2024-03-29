library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;

entity arith_unit is
	generic
	(
		DATA_WIDTH_IN_PROC		: natural;
		DATA_WIDTH_IN_ULA	    : natural;
        ULA_CTRL_WIDTH_IN       : natural
	);

	port
	(
		sel_Ula				: in std_logic_vector((ULA_CTRL_WIDTH_IN-1) downto 0);
		data_in_1			: in std_logic_vector((DATA_WIDTH_IN_ULA-1) downto 0);
		data_in_2			: in std_logic_vector((DATA_WIDTH_IN_ULA-1) downto 0);
		out_result		    : out std_logic_vector((DATA_WIDTH_IN_ULA-1) downto 0);
		out_comp		    : out std_logic;
		out_overflow	    : out std_logic
	);
end entity;

architecture arc_ula of arith_unit is
-- signal signal_zero  : integer   := 0;
-- signal signal_one	: integer	:= 1;
-- signal signal_two	: integer	:= 2;
signal s_add, s_sub, saida_interna, s_div	: std_logic_vector((DATA_WIDTH_IN_ULA-1) downto 0);
signal s_plusZeroD1, s_plusZeroD2, s_plusOne, s_lessOne, s_plusTwo	: std_logic_vector((DATA_WIDTH_IN_ULA-1) downto 0);
signal s_not, s_and, s_or, s_xor	: std_logic_vector((DATA_WIDTH_IN_ULA-1) downto 0);
signal saida_comparacao, saida_overflow	: std_logic;
signal s_igual, s_menor, s_maior  : std_logic;
signal s_mult 	: std_logic_vector(((DATA_WIDTH_IN_ULA*2)-1) downto 0); -- PARA MULTIPLIÇÃO, DOBRO DE DATA_WIDTH_IN_ULA

begin

	s_add		<= std_logic_vector(unsigned(data_in_2) + unsigned(data_in_1));
	s_sub		<= std_logic_vector(unsigned(data_in_2) - unsigned(data_in_1));
	s_mult	    <= std_logic_vector(unsigned(data_in_2) * unsigned(data_in_1));
	s_div		<= std_logic_vector(to_unsigned(7, DATA_WIDTH_IN_ULA));--std_logic_vector(unsigned(data_in_2) / unsigned(data_in_1));

	s_plusZeroD1 <= data_in_1;
	s_plusZeroD2 <= data_in_2;
	s_plusOne <= std_logic_vector(unsigned(data_in_2) + to_unsigned(1, DATA_WIDTH_IN_ULA));
	s_lessOne <= std_logic_vector(unsigned(data_in_2) - to_unsigned(1, DATA_WIDTH_IN_ULA));
	s_plusTwo <= std_logic_vector(unsigned(data_in_2) + to_unsigned(2, DATA_WIDTH_IN_ULA));

	s_not <= NOT data_in_1;
	s_and <= data_in_1 AND data_in_2;
	s_or <= data_in_1 OR data_in_2;
	s_xor <= data_in_1 XOR data_in_2;

	s_igual <= '1' when (data_in_2=data_in_1) else
	           '0';
	s_menor <= '1' when (data_in_2<data_in_1) else
	           '0';
	s_maior <= '1' when (data_in_2>data_in_1) else
	           '0';


	saida_interna <= s_add when (sel_Ula="0000") else
					 s_sub when (sel_Ula="0001") else
					 s_mult((DATA_WIDTH_IN_ULA-1) downto 0) when (sel_Ula="0010") else
					 s_div((DATA_WIDTH_IN_ULA-1) downto 0) when (sel_Ula="0011") else
					 s_plusZeroD1 when (sel_Ula="0100") else
					 s_plusZeroD2 when (sel_Ula="0101") else
					 s_plusOne when (sel_Ula="0110") else
					 s_lessOne when (sel_Ula="0111") else
					 s_plusTwo when (sel_Ula="1000") else
					 s_not when (sel_Ula="1100") else
					 s_and when (sel_Ula="1101") else
					 s_or when (sel_Ula="1110") else
					 s_xor when (sel_Ula="1111") else
					 std_logic_vector(to_unsigned(0, DATA_WIDTH_IN_ULA));
	saida_comparacao <= s_igual when (sel_Ula="1001") else
	                    s_menor when (sel_Ula="1010") else
	                    s_maior when (sel_Ula="1011") else
	                    '0';
	saida_overflow <= '1' when ((sel_Ula="0000") AND ((unsigned(data_in_2)+unsigned(data_in_1))>to_unsigned(255, DATA_WIDTH_IN_ULA))) else  -- add
	 				  '1' when ((sel_Ula="0001") AND (s_sub<std_logic_vector(to_unsigned(0, DATA_WIDTH_IN_ULA)))) else  -- sub
					  '1' when ((sel_Ula="0010") AND s_mult(((DATA_WIDTH_IN_ULA*2)-1) downto DATA_WIDTH_IN_PROC)>std_logic_vector(to_unsigned(0, (DATA_WIDTH_IN_ULA*2-DATA_WIDTH_IN_PROC)))) else  -- multiply
					  '1' when ((sel_Ula="0011") AND (s_div<std_logic_vector(to_unsigned(0, DATA_WIDTH_IN_ULA)))) else  -- div
					  '0';
	---------------------------
	---------------------------------------------------------------

	out_comp <= saida_comparacao;

	out_result <= saida_interna;

	out_overflow <= saida_overflow;

end arc_ula;
