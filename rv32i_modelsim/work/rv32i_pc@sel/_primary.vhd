library verilog;
use verilog.vl_types.all;
entity rv32i_pcSel is
    port(
        in0             : in     vl_logic_vector(31 downto 0);
        in1             : in     vl_logic_vector(31 downto 0);
        in2             : in     vl_logic_vector(31 downto 0);
        in3             : in     vl_logic_vector(31 downto 0);
        s1              : in     vl_logic;
        s2              : in     vl_logic;
        s3              : in     vl_logic;
        \out\           : out    vl_logic_vector(31 downto 0)
    );
end rv32i_pcSel;
