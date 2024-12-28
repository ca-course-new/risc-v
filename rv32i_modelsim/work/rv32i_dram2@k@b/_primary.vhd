library verilog;
use verilog.vl_types.all;
entity rv32i_dram2KB is
    generic(
        awidth          : integer := 11;
        dwidth          : integer := 8
    );
    port(
        data            : in     vl_logic_vector;
        wren            : in     vl_logic;
        address         : in     vl_logic_vector;
        clock           : in     vl_logic;
        q               : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of awidth : constant is 1;
    attribute mti_svvh_generic_type of dwidth : constant is 1;
end rv32i_dram2KB;
