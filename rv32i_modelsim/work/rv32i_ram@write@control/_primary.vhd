library verilog;
use verilog.vl_types.all;
entity rv32i_ramWriteControl is
    port(
        WE_IN           : in     vl_logic;
        funct3          : in     vl_logic_vector(2 downto 0);
        cpuAddr         : in     vl_logic_vector(31 downto 0);
        dataIn          : in     vl_logic_vector(31 downto 0);
        WE_OUT4K        : out    vl_logic_vector(3 downto 0);
        WE_OUT2K        : out    vl_logic_vector(3 downto 0);
        dataOut         : out    vl_logic_vector(31 downto 0)
    );
end rv32i_ramWriteControl;
