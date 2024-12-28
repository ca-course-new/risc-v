library verilog;
use verilog.vl_types.all;
entity rv32i_ramSel is
    port(
        irData          : in     vl_logic_vector(31 downto 0);
        drData4K        : in     vl_logic_vector(31 downto 0);
        drData2K        : in     vl_logic_vector(31 downto 0);
        cpuAddr         : in     vl_logic_vector(31 downto 0);
        funct3          : in     vl_logic_vector(2 downto 0);
        \out\           : out    vl_logic_vector(31 downto 0)
    );
end rv32i_ramSel;
