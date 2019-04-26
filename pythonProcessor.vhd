library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pythonProcessor is
    generic
    (
        DATA_WIDTH              : natural   := 8;   -- data width used in for all normal data (saved in the stack or in the normal memory)
        ONE_GENERIC             : natural   := 1;   -- used for registers with 1 bit of data width
        ADDR_WIDTH              : natural   := 12;   -- address width used to define the normal memories size (memInstr, pilha, memExt)
        ADDR_WIDTH_FUNCTIONS    : natural   := 8;   -- address width used for special memories (pilhaRetorno and pilhaFuncao)
        INSTRUCTION_WIDTH       : natural   := 16;  -- width of the instructions (8 bits for arguments and 8 bits for opCode)
        ADDR_MAX_WIDTH          : natural   := 24;   -- address width used for branch instructions, references 1 byte from the first word and 2 bytes from the second one)
        ULA_CTRL_WIDTH          : natural   := 4    -- used to set the number of bits in the ULA controller pin
    );

    port
    (
        clk_geral       : in std_logic;
        reset_geral     : in std_logic_vector((ONE_GENERIC-1) downto 0);
        overflow_geral  : out std_logic_vector((ONE_GENERIC-1) downto 0)
    );
end entity;

architecture arc_pythonProcessor of pythonProcessor is
------------------------------------------------------- SIGNALS ---------------------------------
--extra signals
signal signal_zero  : integer   := 0;
signal signal_one   : integer   := 1;
signal zero_std_vector, one_std_vector  : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- control
signal reset_ctrl   : std_logic_vector((ONE_GENERIC-1) downto 0);
signal adder_ctrl   : std_logic;
signal regArg_ctrl, regComp_ctrl, regEnd_ctrl, regInstr_ctrl, regOp1_ctrl, regOp2_ctrl, muxPc_ctrl, muxTos_ctrl  : std_logic;
signal regOverflow_ctrl, regJump_ctrl, regPc_ctrl, regTos_ctrl, regTosFuncao_ctrl, regDataReturn_ctrl : std_logic;
signal pilha_ctrl, pilhaFuncao_ctrl, pilhaRetorno_ctrl, memExt_ctrl : std_logic;
signal regMemExt_ctrl, regPilha_ctrl, muxOp1_ctrl, muxOp2_ctrl, muxPilha_ctrl    : std_logic_vector(1 downto 0);
signal ula_ctrl : std_logic_vector((ULA_CTRL_WIDTH-1) downto 0);
-- memExt
signal w_memExt_in, w_memExt_out    : std_logic_vector((DATA_WIDTH-1) downto 0);
-- memInstr
signal w_memInstr_fullWord : std_logic_vector((INSTRUCTION_WIDTH-1) downto 0);
-- muxPilha
signal w_muxPilha_in_01 : std_logic_vector((DATA_WIDTH-1) downto 0);         -- receive 8 bits from the external memory
signal w_muxPilha_out   : std_logic_vector((DATA_WIDTH-1) downto 0);
-- pilha
signal w_pilha_in, w_pilha_out  : std_logic_vector((DATA_WIDTH-1) downto 0);
-- pilhaFuncao // pilhaRetorno
signal w_pilhaFuncao_out, w_pilhaRetorno_out    : std_logic_vector((ADDR_WIDTH-1) downto 0);
-- regArg
signal w_regArg_in, w_regArg_out    : std_logic_vector((DATA_WIDTH-1) downto 0);
-- regComp
signal w_regComp_out    : std_logic_vector((ONE_GENERIC-1) downto 0);
signal w_regDataReturn_in, w_regDataReturn_out  : std_logic_vector((DATA_WIDTH-1) downto 0);
-- regEnd
signal w_regEnd_out     : std_logic_vector((ADDR_WIDTH-1) downto 0);
-- regInstr
signal w_regInstr_in, w_regInstr_out    : std_logic_vector((DATA_WIDTH-1) downto 0);
-- regJump
signal w_regJump_out    : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- regOp1
signal w_regOp1_out : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- regOp2
signal w_regOp2_out : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- regOverflow
signal w_regOverflow_in, w_regOverflow_out  : std_logic_vector((ONE_GENERIC-1) downto 0);

-- regPilha
signal w_regPilha_out   : std_logic_vector((DATA_WIDTH-1) downto 0);
-- regPc
signal w_regPc_out  : std_logic_vector((ADDR_WIDTH-1) downto 0);
signal w_regPc_in   : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- regTos
signal w_regTos_out  : std_logic_vector((ADDR_WIDTH-1) downto 0);
signal w_regTos_in   : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- regTosFuncao
signal w_regTosFuncao_in, w_regTosFuncao_out    : std_logic_vector((DATA_WIDTH-1) downto 0);
-- ula
signal w_ula_out_result : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
signal w_ula_out_comp   : std_logic_vector((ONE_GENERIC-1) downto 0);
signal w_ula_in_op1, w_ula_in_op2   : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
------------------------------------------------------- COMPONENTS ------------------------------
component control is
	generic
	(
		DATA_WIDTH_IN	    : natural	:= 8;
		ULA_CTRL_WIDTH_IN	: natural	:= 2;
        ONE_GENERIC_IN      : natural   := 1
	);
	port
    (
        -- basics
        clk						: in std_logic;
        reset_in    			: in std_logic_vector((ONE_GENERIC_IN-1) downto 0);
        -- from registers
        entrada_regInstr		: in std_logic_vector((DATA_WIDTH-1) downto 0);
        entrada_regArg			: in std_logic_vector((DATA_WIDTH-1) downto 0);
		entrada_regComp		    : in std_logic_vector((ONE_GENERIC-1) downto 0);
		entrada_regOverflow	    : in std_logic_vector((ONE_GENERIC-1) downto 0);
        -- ===================================================
        -- basics
        saida_reset 			: out std_logic_vector((ONE_GENERIC-1) downto 0);
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
        sel_ula					: out std_logic_vector((ULA_CTRL_WIDTH-1) downto 0)
	);
end component;
-- ////////////////////////////////
component reg_1_1 is
	generic
	(
		DATA_WIDTH_IN	: natural	:= 16;
        DATA_WIDTH_OUT  : natural   := 16
	);

	port
	(
		clk					  : in std_logic;
		ctrl_in	              : in std_logic;
		data_in	              : in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_out              : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end component;

component reg_2_1 is
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
end component;

component reg_2_2 is
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
end component;
-- ////////////////////////////////
component mux_2_1 is
    generic
    (
        DATA_WIDTH_IN_1     : natural   := 8;
        DATA_WIDTH_IN_2     : natural   := 8;
        DATA_WIDTH_OUT      : natural   := 8
    );
    port
    (
        sel_in      : in std_logic;
        data_in_1   : in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
        data_in_2   : in std_logic_vector((DATA_WIDTH_IN_2-1) downto 0);
        data_out    : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
    );
end component;

component mux_4_1 is
    generic
    (
        DATA_WIDTH_IN_1     : natural   := 8;
        DATA_WIDTH_IN_2     : natural   := 8;
        DATA_WIDTH_IN_3     : natural   := 8;
        DATA_WIDTH_IN_4     : natural   := 8;
        DATA_WIDTH_OUT      : natural   := 8
    );
    port
    (
        sel_in      : in std_logic_vector(1 downto 0);
        data_in_1   : in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
        data_in_2   : in std_logic_vector((DATA_WIDTH_IN_2-1) downto 0);
        data_in_3   : in std_logic_vector((DATA_WIDTH_IN_3-1) downto 0);
        data_in_4   : in std_logic_vector((DATA_WIDTH_IN_4-1) downto 0);
        data_out    : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
    );
end component;
-- ///////////////////////////////
component memory is
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
end component;

component instr_memory is
	generic
	(
		INSTRUCTION_WIDTH_IN	: natural	:= 16;
		ADDR_WIDTH_IN	: natural	:= 16;
		DATA_WIDTH_IN	: natural	:= 8
	);

	port
	(
		addr_in		     : in std_logic_vector((ADDR_WIDTH_IN-1) downto 0);
		opCode_out	     : out std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		opArg_out		 : out std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		fullWord_out	 : out std_logic_vector((INSTRUCTION_WIDTH_IN-1) downto 0)
	);
end component;

-- ///////////////////////////////

component adderSubtractor is
	generic
	(
		DATA_WIDTH_IN	: natural	:= 8
	);

	port
	(
		sel_in    		: in std_logic;
		data_in			: in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_out		: out std_logic_vector((DATA_WIDTH_IN-1) downto 0)
	);
end component;

component arith_unit is
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
end component;

-------------------------------------------------------------------------------------------------
begin
    overflow_geral <= w_regOverflow_out;
    zero_std_vector <= std_logic_vector(to_unsigned(signal_zero, ADDR_MAX_WIDTH));
    one_std_vector <= std_logic_vector(to_unsigned(signal_one, ADDR_MAX_WIDTH));

    regArg   : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            DATA_WIDTH_OUT => DATA_WIDTH
        )

        port map
        (
            clk => clk_geral,
            ctrl_in => regArg_ctrl,
            data_in => w_regArg_in,
            data_out => w_regArg_out
        );

    regComp : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => ONE_GENERIC,
            DATA_WIDTH_OUT => ONE_GENERIC
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regComp_ctrl,
            data_in => w_ula_out_comp,
            data_out => w_regComp_out
        );

    regDataReturn   : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            DATA_WIDTH_OUT => DATA_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regDataReturn_ctrl,
            data_in => w_regDataReturn_in,
            data_out => w_regDataReturn_out
        );

    regEnd  : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => ADDR_MAX_WIDTH,
            DATA_WIDTH_OUT => ADDR_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regEnd_ctrl,
            data_in => w_regJump_out,
            data_out => w_regEnd_out
        );

    regInstr    : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            DATA_WIDTH_OUT => DATA_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regInstr_ctrl,
            data_in => w_regInstr_in,
            data_out => w_regInstr_out
        );

    regOp1    : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            DATA_WIDTH_OUT => ADDR_MAX_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regOp1_ctrl,
            data_in => w_regPilha_out,
            data_out => w_regOp1_out
        );

    regOp2     : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            DATA_WIDTH_OUT => ADDR_MAX_WIDTH         -- ula data width
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regOp2_ctrl,
            data_in => w_regPilha_out,
            data_out => w_regOp2_out
        );

    regOverflow    : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => ONE_GENERIC,
            DATA_WIDTH_OUT => ONE_GENERIC
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regOverflow_ctrl,
            data_in => w_regOverflow_in,
            data_out => w_regOverflow_out
        );

--=========================================================
    regJump     : entity work.reg_2_1(regJump)
        generic map
        (
            DATA_WIDTH_IN_1 => DATA_WIDTH,      -- coming from argument register
            DATA_WIDTH_IN_2 => INSTRUCTION_WIDTH,      -- coming from instruction memory
            DATA_WIDTH_OUT  => ADDR_MAX_WIDTH    -- both input pin together
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regJump_ctrl,
            data_in_1 => w_regArg_out,
            data_in_2 => w_memInstr_fullWord,
            data_out => w_regJump_out
        );

    regPc     : entity work.reg_2_1(arc_reg)
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,    -- receive from ula out (24 bits)
            DATA_WIDTH_IN_2 => ONE_GENERIC,       -- reset
            DATA_WIDTH_OUT => ADDR_WIDTH          -- only pass forward the length of the address
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regPc_ctrl,
            data_in_1 => w_regPc_in,
            data_in_2 => reset_ctrl,
            data_out => w_regPc_out
        );

    regTos     : entity work.reg_2_1(arc_reg)
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,   -- ula result
            DATA_WIDTH_IN_2 => ONE_GENERIC,  -- reset
            DATA_WIDTH_OUT => ADDR_WIDTH       -- stack address length
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regTos_ctrl,
            data_in_1 => w_regTos_in,
            data_in_2 => reset_ctrl,
            data_out => w_regTos_out
        );

    regTosFuncao     : entity work.reg_2_1(arc_reg)
        generic map
        (
            DATA_WIDTH_IN_1 => DATA_WIDTH,       -- it has its own alu
            DATA_WIDTH_IN_2 => ONE_GENERIC,
            DATA_WIDTH_OUT => DATA_WIDTH        -- same width from the input pin because already gets the data with the correct width
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regTosFuncao_ctrl,
            data_in_1 => w_regTosFuncao_in,
            data_in_2 => reset_ctrl,
            data_out => w_regTosFuncao_out
        );

--=========================================================
    regMemExt   : reg_2_2
        generic map
        (
            DATA_WIDTH_IN_OUT_1 => DATA_WIDTH,
            DATA_WIDTH_IN_OUT_2 => DATA_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regMemExt_ctrl,
            data_in_1 => w_memExt_out,
            data_in_2 => w_regPilha_out,
            data_out_1 => w_muxPilha_in_01,
            data_out_2 => w_memExt_in
        );

    regPilha   : reg_2_2
        generic map
        (
            DATA_WIDTH_IN_OUT_1 => DATA_WIDTH,
            DATA_WIDTH_IN_OUT_2 => DATA_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regPilha_ctrl,
            data_in_1 => w_pilha_out,
            data_in_2 => w_muxPilha_out,
            data_out_1 => w_regPilha_out,
            data_out_2 => w_pilha_in
        );

--=========================================================
    muxOp1  : mux_4_1
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,    -- ZERO
            DATA_WIDTH_IN_2 => ADDR_MAX_WIDTH,    -- ONE
            DATA_WIDTH_IN_3 => ADDR_MAX_WIDTH,
            DATA_WIDTH_IN_4 => ADDR_MAX_WIDTH,
            DATA_WIDTH_OUT => ADDR_MAX_WIDTH
        )
        port map
        (
            sel_in => muxOp1_ctrl,
            data_in_1 => zero_std_vector,
            data_in_2 => one_std_vector,
            data_in_3 => w_regJump_out,
            data_in_4 => w_regOp1_out,
            data_out => w_ula_in_op1
        );

    muxOp2  : mux_4_1
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_WIDTH,
            DATA_WIDTH_IN_2 => ADDR_WIDTH,
            DATA_WIDTH_IN_3 => DATA_WIDTH,
            DATA_WIDTH_IN_4 => ADDR_MAX_WIDTH,
            DATA_WIDTH_OUT => ADDR_MAX_WIDTH
        )
        port map
        (
            sel_in => muxOp2_ctrl,
            data_in_1 => w_regPc_out,
            data_in_2 => w_regTos_out,
            data_in_3 => w_regArg_out,
            data_in_4 => w_regOp2_out,
            data_out => w_ula_in_op2
        );

    muxPilha  : mux_4_1
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,
            DATA_WIDTH_IN_2 => DATA_WIDTH,
            DATA_WIDTH_IN_3 => DATA_WIDTH,
            DATA_WIDTH_IN_4 => DATA_WIDTH,
            DATA_WIDTH_OUT => DATA_WIDTH
        )
        port map
        (
            sel_in => muxPilha_ctrl,
            data_in_1 => w_ula_out_result,
            data_in_2 => w_muxPilha_in_01,     -- regMemExt
            data_in_3 => w_regDataReturn_out,
            data_in_4 => w_regArg_out,
            data_out => w_muxPilha_out
        );

--=========================================================
    muxPc   : mux_2_1
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,
            DATA_WIDTH_IN_2 => ADDR_WIDTH,
            DATA_WIDTH_OUT => ADDR_MAX_WIDTH
        )
        port map
        (
            sel_in => muxPc_ctrl,
            data_in_1 => w_ula_out_result,
            data_in_2 => w_pilhaFuncao_out,
            data_out => w_regPc_in
        );

    muxTos   : mux_2_1
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,
            DATA_WIDTH_IN_2 => ADDR_WIDTH,
            DATA_WIDTH_OUT => ADDR_MAX_WIDTH
        )
        port map
        (
            sel_in => muxTos_ctrl,
            data_in_1 => w_ula_out_result,
            data_in_2 => w_pilhaRetorno_out,
            data_out => w_regTos_in
        );

--=========================================================
    pilha   : memory
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            ADDR_WIDTH_IN => ADDR_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => pilha_ctrl,
            addr_in => w_regTos_out,
            data_in => w_pilha_in,
            data_out => w_pilha_out
        );

    pilhaFuncao   : memory
        generic map
        (
            DATA_WIDTH_IN => ADDR_WIDTH,       -- this stack save the memInstr addresses
            ADDR_WIDTH_IN => DATA_WIDTH        -- 2^8 words
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => pilhaFuncao_ctrl,
            addr_in => w_regTosFuncao_out,
            data_in => w_regPc_out,
            data_out => w_pilhaFuncao_out
        );
    pilhaRetorno   : memory
        generic map
        (
            DATA_WIDTH_IN => ADDR_WIDTH,    -- this stack save the main stack (pilha) addresses
            ADDR_WIDTH_IN => DATA_WIDTH     -- 2^8 words
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => pilhaRetorno_ctrl,
            addr_in => w_regTosFuncao_out,
            data_in => w_regTos_out,
            data_out => w_pilhaRetorno_out
        );

    memExt   : memory
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,        -- save variables coming from the main stack (pilha)
            ADDR_WIDTH_IN => ADDR_WIDTH         -- default size, the same as memInstr and pilha
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => memExt_ctrl,
            addr_in => w_regEnd_out,
            data_in => w_memExt_in,
            data_out => w_memExt_out
        );

--=========================================================
    memInstr    : instr_memory
        generic map
        (
            INSTRUCTION_WIDTH_IN => INSTRUCTION_WIDTH,
            ADDR_WIDTH_IN => ADDR_WIDTH,
            DATA_WIDTH_IN => DATA_WIDTH
        )
        port map
        (
            addr_in => w_regPc_out,
            opCode_out => w_regInstr_in,
            opArg_out => w_regArg_in,
            fullWord_out => w_memInstr_fullWord
        );

--=========================================================
    controller  : control
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
    		ULA_CTRL_WIDTH_IN => ULA_CTRL_WIDTH
        )
        port map
        (
            -- basics
            clk	=> clk_geral,
            reset_in => reset_geral,
            -- from registers
            entrada_regInstr => w_regInstr_out,
            entrada_regArg => w_regArg_out,
            entrada_regComp => w_regComp_out,
            entrada_regOverflow => w_regOverflow_out,
            -- ===================================================
            -- basics
            saida_reset => reset_ctrl,
            -- registers
            ctrl_regDataReturn => regDataReturn_ctrl,
            ctrl_pilhaRetorno => pilhaRetorno_ctrl,
            ctrl_regTosFuncao => regTosFuncao_ctrl,
            ctrl_regOp1 => regOp1_ctrl,
            ctrl_regOp2 => regOp2_ctrl,
            ctrl_regPc => regPc_ctrl,
            ctrl_regComp => regComp_ctrl,
            ctrl_regOverflow => regOverflow_ctrl,
            ctrl_regTos => regTos_ctrl,
            ctrl_regInstr => regInstr_ctrl,
            ctrl_regArg => regArg_ctrl,
            ctrl_regEnd => regEnd_ctrl,
            ctrl_regJump => regJump_ctrl,
    		ctrl_regPilha => regPilha_ctrl,
    		ctrl_regMemExt => regMemExt_ctrl,
            -- memories
            ctrl_pilha => pilha_ctrl,
            ctrl_pilhaFuncao => pilhaFuncao_ctrl,
            ctrl_memExt => memExt_ctrl,
            -- muxes
            sel_muxPc => muxPc_ctrl,
            sel_muxTos => muxTos_ctrl,
            sel_MuxOp1 => muxOp1_ctrl,
            sel_MuxOp2 => muxOp2_ctrl,
            sel_MuxPilha => muxPilha_ctrl,
            -- arithmetic
            sel_soma_sub => adder_ctrl,
            sel_ula => ula_ctrl
        );

--=========================================================
    adder_subtract  : adderSubtractor
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH
        )
        port map
        (
            sel_in => adder_ctrl,
            data_in => w_regTosFuncao_out,
            data_out => w_regTosFuncao_in
        );

    ula : arith_unit
        generic map
        (
            DATA_WIDTH_IN => ADDR_MAX_WIDTH,
            ULA_CTRL_WIDTH_IN => ULA_CTRL_WIDTH,
            ONE_GENERIC_IN => ONE_GENERIC
        )
        port map
        (
            sel_Ula => ula_ctrl,
            data_in_1 => w_ula_in_op1,
            data_in_2 => w_ula_in_op2,
            out_result => w_ula_out_result,
            out_comp => w_ula_out_comp,
            out_overflow => w_regOverflow_in
        );
end arc_pythonProcessor;
