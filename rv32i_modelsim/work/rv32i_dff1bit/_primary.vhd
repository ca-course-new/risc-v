library verilog;
use verilog.vl_types.all;
entity rv32i_dff1bit is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        \in\            : in     vl_logic;
        en              : in     vl_logic;
        clr             : in     vl_logic;
        \out\           : out    vl_logic
    );
end rv32i_dff1bit;
