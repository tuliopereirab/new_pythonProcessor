library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control is
	generic
	(
		DATA_WIDTH_IN		: natural	:= 8;
		ULA_CTRL_WIDTH_IN	: natural	:= 4;
        ONE_GENERIC_IN      : natural   := 1
	);
	port
    (
        -- basics
        clk						: in std_logic;
        reset_in    			: in std_logic_vector((ONE_GENERIC_IN-1) downto 0);
        -- from registers
        entrada_regInstr		: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
        entrada_regArg			: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		entrada_regComp		    : in std_logic_vector((ONE_GENERIC_IN-1) downto 0);
		entrada_regOverflow	    : in std_logic_vector((ONE_GENERIC_IN-1) downto 0);
        -- ===================================================
        -- basics
        saida_reset 			: out std_logic_vector((ONE_GENERIC_IN-1) downto 0);
        -- registers
		ctrl_regDataReturn	    : out std_logic;
		ctrl_pilhaRetorno		: out std_logic;
		ctrl_regTosFuncao		: out std_logic;
		ctrl_regOp1				: out std_logic;
		ctrl_regOp2				: out std_logic;
		ctrl_regPc				: out std_logic;
		ctrl_regComp			: out std_logic;
		ctrl_regOverflow		: out std_logic;
		ctrl_regTos				: out std_logic;
		ctrl_regInstr			: out std_logic;
		ctrl_regArg				: out std_logic;
		ctrl_regEnd				: out std_logic;
        ctrl_regJump			: out std_logic;
		ctrl_regPilha 		    : out std_logic_vector(1 downto 0);
		ctrl_regMemExt    		: out std_logic_vector(1 downto 0);
        -- memories
		ctrl_pilha				: out std_logic;
        ctrl_pilhaFuncao		: out std_logic;
		ctrl_memExt				: out std_logic;
        -- muxes
        sel_muxPc				: out std_logic;
		sel_muxTos				: out std_logic;
        sel_MuxOp1				: out std_logic_vector(1 downto 0);
        sel_MuxOp2				: out std_logic_vector(1 downto 0);
        sel_MuxPilha			: out std_logic_vector(1 downto 0);
        -- arithmetic
        sel_soma_sub			: out std_logic;
        sel_ula					: out std_logic_vector((ULA_CTRL_WIDTH_IN-1) downto 0)
	);
end entity;

architecture arc_control of control is

-- lc (LOAD_CONST), lf (LOAD_FAST), sf (STORE_FAST), co (COMPARE_OP), ja (JUMP_ABSOLUTE), jf (JUMP_FORWARD), b (BINARY_), pj_stay (FICA!), pj_jump (PULA!), pj_end (FINALIZA)
type state_type is (first, AUX, cf1, cf2, cf3, cf4, lc1, lc2, lc3, lc4, lf1, lf2, lf3, lf4, lf5, lf6, lf7, lf8, b1, b2, b3, b4, b5_1, b5_2, b5_3, b5_4, b6, b7, b8, sf1, sf2, sf3, sf4, sf5, sf6, sf7, sf8, co1, co2, co3, co4, co5, co6_1, co6_2, co6_3, co7, co8, co9, co10, co11, jf1, jf2, jf3, jf4, rv1, rv2, rv3, rv4, rv5, ja1, ja2, ja3, ja4, pj_FICA, pj_PULA1, pj_PULA2, pj_PULA3, pj_FIM);
signal atual 	: state_type;
signal signal_one	: integer	:= 1;
signal signal_zero	: integer := 0;
signal verif_muxOp1, verif_muxOp2	: std_logic_vector(1 downto 0);
--signal sEntrada_regComp, sEntrada_regOverflow	: std_logic;
signal sEntrada_regInstr, sEntrada_regArg 	: std_logic_vector(7 downto 0);

begin
	sEntrada_regArg <= entrada_regArg;
	sEntrada_regInstr <= entrada_regInstr;

	saida_reset <= reset_in;


	process(clk, reset_in, entrada_regComp, sEntrada_regArg, sEntrada_regInstr, entrada_regOverflow)
	begin
		if(reset_in=std_logic_vector(to_unsigned(signal_one, ONE_GENERIC_IN))) then
			atual <= first;
		elsif(rising_edge(clk)) then
			case atual is
				when first =>
					atual <= AUX;
				when AUX =>
					case sEntrada_regInstr is
						when "00001100" =>		-- LOAD_CONST
							atual <= lc1;
						when "00001101" =>		-- LOAD_FAST
							atual <= lf1;
						when "00001111" =>		-- STORE_FAST
							atual <= sf1;
						when "00000010" =>		-- COMPARE_OP
							atual <= co1;
						when "00110000" =>         -- POP_JUMP_IF_FALSE
							if(entrada_regComp=std_logic_vector(to_unsigned(signal_zero,  ONE_GENERIC_IN))) then
								atual <= pj_PULA1;
							else
								atual <= pj_FICA;
							end if;
						when "00110001" =>		-- POP_JUMP_IF_TRUE
							if(entrada_regComp=std_logic_vector(to_unsigned(signal_one, ONE_GENERIC_IN))) then
								atual <= pj_PULA1;
							else
								atual <= pj_FICA;
							end if;
						when "00110010" =>		-- JUMP_FORWARD
							atual <= jf1;
						when "00110011" =>		-- JUMP_ABSOLUTE
							atual <= ja1;
						when "00100000" =>		-- BINARY_ADD
							atual <= b1;
						when "00100001" =>		-- BINARY_SUBTRACT
							atual <= b1;
						when "00100010" =>		-- BINARY_MULTIPLY
							atual <= b1;
						when "00100011" =>		-- BINARY_DIVIDE
							atual <= b1;
						when "01100000" =>		-- CALL_FUNCTION
							atual <= cf1;
						when "01100001" =>		-- RETURN VALUE
							atual <= rv1;
						when others =>
							atual <= first;
						end case;

			-- ====================================
			-- LOAD_CONST
				when lc1 =>
					atual <= lc2;
				when lc2 =>
					atual <= lc3;
				when lc3 =>
					atual <= lc4;
				when lc4 =>
					atual <= first;
				-- ====================================
				-- LOAD_FAST
				when lf1 =>
					atual <= lf2;
				when lf2 =>
					atual <= lf3;
				when lf3 =>
					atual <= lf4;
				when lf4 =>
					atual <= lf5;
				when lf5 =>
					atual <= lf6;
				when lf6 =>
					atual <= lf7;
				when lf7 =>
					atual <= lf8;
				when lf8 =>
					atual <= first;
				-- ====================================
				-- STORE_FAST
				when sf1 =>
					atual <= sf2;
				when sf2 =>
					atual <= sf3;
				when sf3 =>
					atual <= sf4;
				when sf4 =>
					atual <= sf5;
				when sf5 =>
					atual <= sf6;
				when sf6 =>
					atual <= sf7;
				when sf7 =>
					atual <= sf8;
				when sf8 =>
					atual <= first;
				-- ====================================
				-- BINARY_
				when b1 =>
					atual <= b2;
				when b2 =>
					atual <= b3;
				when b3 =>
					atual <= b4;
				when b4 =>
					if(sEntrada_regInstr="00100000") then
						atual <= b5_1;
					elsif(sEntrada_regInstr="00100001") then
						atual <= b5_2;
					elsif(sEntrada_regInstr="00100010") then
						atual <= b5_3;
					elsif(sEntrada_regInstr="00100011") then
						atual <= b5_4;
					else
						atual <= b5_1;         -- caso haja um erro, executará uma soma
					end if;
				when b5_1 =>
					atual <= b6;
				when b5_2 =>
					atual <= b6;
				when b5_3 =>
					atual <= b6;
				when b5_4 =>
					atual <= b6;
				when b6 =>
					atual <= b7;
				when b7 =>
					atual <= b8;
				when b8 =>
					atual <= first;
				-- ====================================
				-- COMPARE_OP
				when co1 =>
					atual <= co2;
				when co2 =>
					atual <= co3;
				when co3 =>
					atual <= co4;
				when co4 =>
					atual <= co5;
				when co5 =>
					if(sEntrada_regArg="00011000") then  -- igual
						atual <= co6_3;
					elsif(sEntrada_regArg="00011001") then -- menor que
						atual <= co6_1;
					elsif(sEntrada_regArg="00011010") then -- maior que
						atual <= co6_2;
					else
						atual <= co6_3;      -- executa igual
					end if;
				when co6_1 =>
					atual <= co7;
				when co6_2 =>
					atual <= co7;
				when co6_3 =>
					atual <= co7;
				when co7 =>
					atual <= co8;
				when co8 =>
					atual <= co9;
				when co9 =>
					atual <= co10;
				when co10 =>
					atual <= co11;
				when co11 =>
					atual <= first;
				-- ====================================
				-- JUMP_FORWARD
				when jf1 =>
					atual <= jf2;
				when jf2 =>
					atual <= jf3;
				when jf3 =>
					atual <= jf4;
				when jf4 =>
					atual <= first;
				-- ====================================
				-- JUMP_ABSOLUTE
				when ja1 =>
					atual <= ja2;
				when ja2 =>
					atual <= ja3;
				when ja3 =>
					atual <= ja4;
				when ja4 =>
					atual <= first;
				-- ====================================
				-- POP_JUMP_
				when pj_FICA =>
					atual <= pj_FIM;
				when pj_PULA1 =>
					atual <= pj_PULA2;
				when pj_PULA2 =>
					atual <= pj_PULA3;
				when pj_PULA3 =>
					atual <= pj_FIM;
				when pj_FIM =>
					atual <= first;
				-- ====================================
				-- CALL_FUNCTION
				when cf1 =>
					atual <= cf2;
				when cf2 =>
					atual <= cf3;
				when cf3 =>
					atual <= cf4;
				when cf4 =>
					atual <= first;
				-- ====================================
				-- RETURN_VALUE
				when rv1 =>
					atual <= rv2;
				when rv2 =>
					atual <= rv3;
				when rv3 =>
					atual <= rv4;
				when rv4 =>
					atual <= rv5;
				when rv5 =>
					atual <= first;
				when others =>
					atual <= first;
			end case;
		end if;
	end process;

		-- ================================================================================================================================================
end arc_control;
