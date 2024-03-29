library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pythonProcessor is
    generic
    (
        DATA_WIDTH              : natural   := 8;   -- data width used in for all normal data (saved in the stack or in the normal memory)
        ADDR_WIDTH              : natural   := 12;   -- address width used to define the normal memories size (memInstr, pilha, memExt)
        ADDR_WIDTH_FUNCTIONS    : natural   := 8;   -- address width used for special memories (pilhaRetorno and pilhaFuncao)
        INSTRUCTION_WIDTH       : natural   := 16;  -- width of the instructions (8 bits for arguments and 8 bits for opCode)
        ADDR_MAX_WIDTH          : natural   := 24;   -- address width used for branch instructions, references 1 byte from the first word and 2 bytes from the second one)
        ULA_CTRL_WIDTH          : natural   := 4    -- used to set the number of bits in the ULA controller pin
    );

    port
    (
        osc_clk                     : in std_logic;
        --reset_n                     : in std_logic;
        button                      : in std_logic_vector(3 downto 0);
        memExt_read_out             : out std_logic_vector((DATA_WIDTH-1) downto 0);
        error_out                   : out std_logic_vector((DATA_WIDTH-1) downto 0);
        instr_out                   : out std_logic_vector((ADDR_WIDTH_FUNCTIONS-1) downto 0);
        led                         : out std_logic_vector(3 downto 0)
    );
end entity;

architecture arc of pythonProcessor is
------------------------------------------------------- SIGNALS ---------------------------------
--extra signals
-- signal signal_zero  : integer   := 0;
-- signal signal_one   : integer   := 1;
signal clk_geral, reset_geral   : std_logic;
signal zero_std_vector, one_std_vector  : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
-- control
signal reset_ctrl   : std_logic;
signal adder_ctrl   : std_logic;
signal regArg_ctrl, regComp_ctrl, regEnd_ctrl, regInstr_ctrl, regOp1_ctrl, regOp2_ctrl, muxPc_ctrl, muxTos_ctrl  : std_logic;
signal regOverflow_ctrl, regJump_ctrl, regPc_ctrl, regTos_ctrl, regTosFuncao_ctrl, regDataReturn_ctrl : std_logic;
signal pilha_ctrl, pilhaFuncao_ctrl, pilhaRetorno_ctrl, memExt_ctrl : std_logic;
signal regMemExt_ctrl, regPilha_ctrl, muxOp1_ctrl, muxOp2_ctrl, muxPilha_ctrl    : std_logic_vector(1 downto 0);
signal ula_ctrl : std_logic_vector((ULA_CTRL_WIDTH-1) downto 0);
signal regError_ctrl    : std_logic;
signal w_regError_in, w_regError_out    : std_logic_vector((DATA_WIDTH-1) downto 0);
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
signal w_regComp_out    : std_logic;
signal w_regDataReturn_out  : std_logic_vector((DATA_WIDTH-1) downto 0);
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
signal w_regOverflow_in, w_regOverflow_out  : std_logic;

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
signal w_ula_out_comp   : std_logic;
signal w_ula_in_op1, w_ula_in_op2   : std_logic_vector((ADDR_MAX_WIDTH-1) downto 0);
------------------------------------------------------- COMPONENTS ------------------------------
component control is
	generic
	(
		DATA_WIDTH_IN	    : natural;
        ADDR_WIDTH_IN       : natural;
		ULA_CTRL_WIDTH_IN	: natural
	);
	port
    (
        -- basics
        clk						: in std_logic;
        reset_in    			: in std_logic;
        -- from registers
        entrada_regInstr		: in std_logic_vector((DATA_WIDTH-1) downto 0);
        entrada_regArg			: in std_logic_vector((DATA_WIDTH-1) downto 0);
		entrada_regComp		    : in std_logic;
		entrada_regOverflow	    : in std_logic;
		-- error verification
		entrada_regTos			: in std_logic_vector((ADDR_WIDTH_IN-1) downto 0);
        -- ===================================================
        -- error verification
        regError_out            : out std_logic_vector((DATA_WIDTH_IN-1) downto 0);
        -- basics
        saida_reset 			: out std_logic;
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
		ctrl_regError			: out std_logic;
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
		DATA_WIDTH_IN	: natural;
        DATA_WIDTH_OUT  : natural
	);

	port
	(
		clk					  : in std_logic;
		ctrl_in	              : in std_logic;
		data_in	              : in std_logic_vector((DATA_WIDTH_IN-1) downto 0);
		data_out              : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end component;

component reg_1_1_1bit is
	port
	(
		clk					  : in std_logic;
		ctrl_in	              : in std_logic;
		data_in	              : in std_logic;
		data_out              : out std_logic
	);
end component;

component reg_2_1 is
	generic
	(
		DATA_WIDTH_IN_1   	: natural;
        DATA_WIDTH_IN_2     : natural;
        DATA_WIDTH_OUT      : natural
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

component reg_2_1_reset is
	generic
	(
		DATA_WIDTH_IN_1   	: natural;
        DATA_WIDTH_OUT      : natural
	);

	port
	(
		clk               : in std_logic;
		ctrl_in           : in std_logic;
		reset_in          : in std_logic;
		data_in_1         : in std_logic_vector((DATA_WIDTH_IN_1-1) downto 0);
		data_out          : out std_logic_vector((DATA_WIDTH_OUT-1) downto 0)
	);
end component;

component reg_2_2 is
	generic
	(
		DATA_WIDTH_IN_OUT_1	      : natural; -- same size of read
    	DATA_WIDTH_IN_OUT_2	      : natural -- same size for write

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
        DATA_WIDTH_IN_1     : natural;
        DATA_WIDTH_IN_2     : natural;
        DATA_WIDTH_OUT      : natural
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
        DATA_WIDTH_IN_1     : natural;
        DATA_WIDTH_IN_2     : natural;
        DATA_WIDTH_IN_3     : natural;
        DATA_WIDTH_IN_4     : natural;
        DATA_WIDTH_OUT      : natural
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
end component;

component instr_memory is
	generic
	(
		INSTRUCTION_WIDTH_IN	: natural;
		ADDR_WIDTH_IN	        : natural;
		DATA_WIDTH_IN	        : natural
	);

	port
	(
		clk		 : in std_logic;
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
		DATA_WIDTH_IN	: natural
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
end component;

-------------------------------------------------------------------------------------------------
begin
    instr_out <= w_regInstr_out;
    led <= NOT w_regPc_out(3 downto 0);
    memExt_read_out <= w_memExt_out;
    error_out <= w_regError_out;
    clk_geral <= osc_clk;
    --reset_geral <= reset_n;
    reset_geral <= NOT button(0);
    zero_std_vector <= std_logic_vector(to_unsigned(0, ADDR_MAX_WIDTH));
    one_std_vector <= std_logic_vector(to_unsigned(1, ADDR_MAX_WIDTH));

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
            data_in => w_regPilha_out,
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

    regError    : reg_1_1
        generic map
        (
            DATA_WIDTH_IN => DATA_WIDTH,
            DATA_WIDTH_OUT => DATA_WIDTH
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regError_ctrl,
            data_in => w_regError_in,
            data_out => w_regError_out
        );
--=========================================================

    regOverflow    : reg_1_1_1bit
        port map
        (
            clk => clk_geral,
            ctrl_in => regOverflow_ctrl,
            data_in => w_regOverflow_in,
            data_out => w_regOverflow_out
        );


    regComp : reg_1_1_1bit
        port map
        (
            clk => clk_geral,
            ctrl_in => regComp_ctrl,
            data_in => w_ula_out_comp,
            data_out => w_regComp_out
        );
--=========================================================
    regJump     : reg_2_1
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

--=========================================================

    regPc     : reg_2_1_reset
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,    -- receive from ula out (24 bits)
            DATA_WIDTH_OUT => ADDR_WIDTH          -- only pass forward the length of the address
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regPc_ctrl,
            reset_in => reset_ctrl,
            data_in_1 => w_regPc_in,
            data_out => w_regPc_out
        );

    regTos     : reg_2_1_reset
        generic map
        (
            DATA_WIDTH_IN_1 => ADDR_MAX_WIDTH,   -- ula result
            DATA_WIDTH_OUT => ADDR_WIDTH       -- stack address length
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regTos_ctrl,
            reset_in => reset_ctrl,
            data_in_1 => w_regTos_in,
            data_out => w_regTos_out
        );

    regTosFuncao     : reg_2_1_reset
        generic map
        (
            DATA_WIDTH_IN_1 => DATA_WIDTH,       -- it has its own alu
            DATA_WIDTH_OUT => DATA_WIDTH        -- same width from the input pin because already gets the data with the correct width
        )
        port map
        (
            clk => clk_geral,
            ctrl_in => regTosFuncao_ctrl,
            reset_in => reset_ctrl,
            data_in_1 => w_regTosFuncao_in,
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
            data_in_1 => zero_std_vector,       -- desnecessário
            data_in_2 => one_std_vector,        -- desnecessário
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
            clk => clk_geral,
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
            ADDR_WIDTH_IN => ADDR_WIDTH,
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
            -- error verification
            entrada_regTos => w_regTos_out,
            -- ===================================================
            -- error verification
            regError_out => w_regError_in,
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
            ctrl_regError => regError_ctrl,
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
            DATA_WIDTH_IN_PROC => DATA_WIDTH,
            DATA_WIDTH_IN_ULA => ADDR_MAX_WIDTH,
            ULA_CTRL_WIDTH_IN => ULA_CTRL_WIDTH
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
end arc;
