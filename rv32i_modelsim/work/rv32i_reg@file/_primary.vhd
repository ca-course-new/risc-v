library verilog;
use verilog.vl_types.all;
entity rv32i_regFile is
    port(
        rst             : in     vl_logic;
        clk             : in     vl_logic;
        readReg1        : in     vl_logic_vector(4 downto 0);
        readReg2        : in     vl_logic_vector(4 downto 0);
        writeReg1       : in     vl_logic_vector(4 downto 0);
        we1             : in     vl_logic;
        writeData1      : in     vl_logic_vector(31 downto 0);
        writeReg2       : in     vl_logic_vector(4 downto 0);
        we2             : in     vl_logic;
        writeData2      : in     vl_logic_vector(31 downto 0);
        readData1       : out    vl_logic_vector(31 downto 0);
        readData2       : out    vl_logic_vector(31 downto 0)
    );
end rv32i_regFile;
