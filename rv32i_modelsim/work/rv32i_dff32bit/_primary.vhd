library verilog;
use verilog.vl_types.all;
entity rv32i_dff32bit is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        \in\            : in     vl_logic_vector(31 downto 0);
        en              : in     vl_logic;
        clr             : in     vl_logic;
        \out\           : out    vl_logic_vector(31 downto 0)
    );
end rv32i_dff32bit;
