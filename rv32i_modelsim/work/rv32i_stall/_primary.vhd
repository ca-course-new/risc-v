library verilog;
use verilog.vl_types.all;
entity rv32i_stall is
    port(
        FD_rs1          : in     vl_logic_vector(4 downto 0);
        FD_rs2          : in     vl_logic_vector(4 downto 0);
        DE_rd           : in     vl_logic_vector(4 downto 0);
        EM_rd           : in     vl_logic_vector(4 downto 0);
        MW_rd           : in     vl_logic_vector(4 downto 0);
        FD_OP           : in     vl_logic_vector(6 downto 0);
        DE_OP           : in     vl_logic_vector(6 downto 0);
        EM_OP           : in     vl_logic_vector(6 downto 0);
        MW_OP           : in     vl_logic_vector(6 downto 0);
        stall           : out    vl_logic;
        stallN          : out    vl_logic;
        forward         : out    vl_logic_vector(1 downto 0)
    );
end rv32i_stall;
