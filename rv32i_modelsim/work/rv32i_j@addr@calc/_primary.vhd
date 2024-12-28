library verilog;
use verilog.vl_types.all;
entity rv32i_jAddrCalc is
    port(
        pc              : in     vl_logic_vector(31 downto 0);
        ins             : in     vl_logic_vector(31 downto 0);
        rs1             : in     vl_logic_vector(31 downto 0);
        JAL_Addr        : out    vl_logic_vector(31 downto 0);
        JALR_Addr       : out    vl_logic_vector(31 downto 0)
    );
end rv32i_jAddrCalc;
