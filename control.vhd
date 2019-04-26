library ieee;
use ieee.std_logic_1164.all;

entity control is
	generic
	(
		DATA_WIDTH_IN		: natural	:= 8;
		ULA_CTRL_WIDTH_IN	: natural	:= 2;
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
type state_type is (first, sAUX, lc1, lc1_AUX, lc2, lc3, lf1, lf2, lf2_AUX, lf3, lf4, sf1, sf2, sf3, sf3_AUX, sf4, sf5, pj_jump, pj_stay, pj_end, co1, co2, co3, co4, co4_AUX, co5_1, co5_2, co5_3, co5_AUX, co6, co7, co7_AUX, co8, jf1, jf2, b1, b2, b3, b3_AUX, b4_1, b4_2, b4_3, b4_4, b4_AUX, b5, b6, ja1, ja2, cf1, cf2, cf3, cf4, rv1, rv2, rv3, rv4, rv5, rv6);
signal atual 	: state_type;
signal verif_muxOp1, verif_muxOp2	: std_logic_vector(1 downto 0);
--signal sEntrada_regComp, sEntrada_regOverflow	: std_logic;
signal sEntrada_regInstr, sEntrada_regArg 	: std_logic_vector(7 downto 0);

begin
end arc_control;
