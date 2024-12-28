library verilog;
use verilog.vl_types.all;
entity rv32i_control is
    port(
        ins             : in     vl_logic_vector(31 downto 0);
        JAL             : out    vl_logic;
        JALR            : out    vl_logic;
        JumpRegWrite    : out    vl_logic;
        ALUOP           : out    vl_logic_vector(5 downto 0);
        ALUSRC1         : out    vl_logic_vector(3 downto 0);
        ALUSRC2         : out    vl_logic_vector(3 downto 0);
        Branch          : out    vl_logic;
        MemWrite        : out    vl_logic;
        MemEnable       : out    vl_logic;
        RegWrite        : out    vl_logic;
        MemToReg        : out    vl_logic
    );
end rv32i_control;
