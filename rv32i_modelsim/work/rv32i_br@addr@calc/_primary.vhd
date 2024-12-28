library verilog;
use verilog.vl_types.all;
entity rv32i_brAddrCalc is
    port(
        ins             : in     vl_logic_vector(31 downto 0);
        pc              : in     vl_logic_vector(31 downto 0);
        brAddr          : out    vl_logic_vector(31 downto 0)
    );
end rv32i_brAddrCalc;
