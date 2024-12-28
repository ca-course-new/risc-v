library verilog;
use verilog.vl_types.all;
entity rv32i_forwarding is
    port(
        DE_rs1          : in     vl_logic_vector(4 downto 0);
        DE_rs2          : in     vl_logic_vector(4 downto 0);
        EM_rd           : in     vl_logic_vector(4 downto 0);
        MW_rd           : in     vl_logic_vector(4 downto 0);
        WB_rd           : in     vl_logic_vector(4 downto 0);
        EM_RegWrite     : in     vl_logic;
        MW_RegWrite     : in     vl_logic;
        WB_RegWrite     : in     vl_logic;
        DE_OP           : in     vl_logic_vector(6 downto 0);
        EM_OP           : in     vl_logic_vector(6 downto 0);
        MW_OP           : in     vl_logic_vector(6 downto 0);
        WB_OP           : in     vl_logic_vector(6 downto 0);
        forwardA        : out    vl_logic_vector(1 downto 0);
        forwardB        : out    vl_logic_vector(1 downto 0);
        forwardC        : out    vl_logic_vector(1 downto 0)
    );
end rv32i_forwarding;
