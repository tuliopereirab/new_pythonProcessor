library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

entity arith_unit is
	generic
	(
		DATA_WIDTH_IN	        : natural := 24;
        ULA_CTRL_WIDTH_IN       : natural := 3;
        ONE_GENERIC_IN          : natural := 1
	);

	port
	(
		sel_Ula				: in std_logic_vector((ULA_CTRL_WIDTH_IN-1) downto 0);
		data_in_1			: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_in_2			: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		out_result		    : out std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		out_comp		    : out std_logic_vector((ONE_GENERIC_IN-1) downto 0);
		out_overflow	    : out std_logic_vector((ONE_GENERIC_IN-1) downto 0)
	);
end entity;

architecture arc_ula of arith_unit is
signal signal_zero  : integer   := 0;
signal s_add, s_sub, saida_interna	: std_logic_vector((DATA_WIDTH_IN-1) downto 0);
signal saida_comparacao, saida_overflow	: std_logic_vector((ONE_GENERIC_IN-1) downto 0);
signal s_igual, s_menor, s_maior  : std_logic_vector((ONE_GENERIC_IN-1) downto 0);
signal s_mult, s_div 	: std_logic_vector(((DATA_WIDTH_IN*2)-1) downto 0); -- PARA MULTIPLIÇÃO, DOBRO DE DATA_WIDTH_IN
begin
	s_add		<= data_in_2 + data_in_1;
	s_sub		<= data_in_2 - data_in_1;
	s_mult	    <= data_in_2 * data_in_1;
	--s_div		<= std_logic_vector(to_unsigned(signal_zero, DATA_WIDTH_IN)); -- data_in_1 / data_in_2;     ERRO DIVISÃO!


	s_igual <= "1" when (data_in_2=data_in_1) else
	           "0";
	s_menor <= "1" when (data_in_2<data_in_1) else
	           "0";
	s_maior <= "1" when (data_in_2>data_in_1) else
	           "0";


	saida_interna <= s_add when (sel_Ula="000") else
					 s_sub when (sel_Ula="001") else
					 s_mult((DATA_WIDTH_IN-1) downto 0) when (sel_Ula="010") else
					 s_div((DATA_WIDTH_IN-1) downto 0) when (sel_Ula="011") else
					 std_logic_vector(to_unsigned(signal_zero, DATA_WIDTH_IN));     -- 24 bits
	saida_comparacao <= s_igual when (sel_Ula="100") else
	                    s_menor when (sel_Ula="101") else
	                    s_maior when (sel_Ula="110") else
	                    std_logic_vector(to_unsigned(signal_zero, ONE_GENERIC_IN));
	saida_overflow <= "1" when ((sel_Ula="010") AND (s_mult((DATA_WIDTH_IN-1) downto 8)/=std_logic_vector(to_unsigned(signal_zero, DATA_WIDTH_IN/3)))) else		-- controle de overflow para multiplicação
					  "1" when ((data_in_2>data_in_1) AND (sel_Ula="001")) else       -- controle de overflow para subtração
					  std_logic_vector(to_unsigned(signal_zero, ONE_GENERIC_IN));

	---------------------------------------------------------------

	out_comp <= saida_comparacao when (sel_Ula(2)='1') else
					 std_logic_vector(to_unsigned(signal_zero, ONE_GENERIC_IN));

	out_result <= saida_interna when (sel_Ula(2)='0') else
				  std_logic_vector(to_unsigned(signal_zero, DATA_WIDTH_IN));

	out_overflow <= saida_overflow;

end arc_ula;
