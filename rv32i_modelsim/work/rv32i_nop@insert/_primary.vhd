library verilog;
use verilog.vl_types.all;
entity rv32i_nopInsert is
    port(
        rst             : in     vl_logic;
        clk             : in     vl_logic;
        jal             : in     vl_logic;
        jalr            : in     vl_logic;
        br              : in     vl_logic;
        br_ex           : in     vl_logic;
        stallN          : in     vl_logic;
        sel             : out    vl_logic
    );
end rv32i_nopInsert;
