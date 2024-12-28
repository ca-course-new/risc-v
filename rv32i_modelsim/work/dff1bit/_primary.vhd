library verilog;
use verilog.vl_types.all;
entity dff1bit is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        \in\            : in     vl_logic;
        \out\           : out    vl_logic
    );
end dff1bit;
