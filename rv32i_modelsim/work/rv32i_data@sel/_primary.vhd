library verilog;
use verilog.vl_types.all;
entity rv32i_dataSel is
    port(
        ins             : in     vl_logic_vector(31 downto 0);
        regData1        : in     vl_logic_vector(31 downto 0);
        regData2        : in     vl_logic_vector(31 downto 0);
        pc              : in     vl_logic_vector(31 downto 0);
        sel1            : in     vl_logic_vector(3 downto 0);
        sel2            : in     vl_logic_vector(3 downto 0);
        out1            : out    vl_logic_vector(31 downto 0);
        out2            : out    vl_logic_vector(31 downto 0)
    );
end rv32i_dataSel;
