library verilog;
use verilog.vl_types.all;
entity rv32i_meminfo_display is
    port(
        MemToReg        : in     vl_logic;
        MemEnable       : in     vl_logic;
        MemAddrIn       : in     vl_logic_vector(31 downto 0);
        MemDataIn       : in     vl_logic_vector(31 downto 0);
        MemAddrOut      : out    vl_logic_vector(31 downto 0);
        MemDataOut      : out    vl_logic_vector(31 downto 0)
    );
end rv32i_meminfo_display;
