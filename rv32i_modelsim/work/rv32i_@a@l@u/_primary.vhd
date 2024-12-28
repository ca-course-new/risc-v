library verilog;
use verilog.vl_types.all;
entity rv32i_ALU is
    generic(
        width           : integer := 32;
        opw             : integer := 6
    );
    port(
        a               : in     vl_logic_vector;
        b               : in     vl_logic_vector;
        op              : in     vl_logic_vector;
        res             : out    vl_logic_vector;
        taken           : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of width : constant is 1;
    attribute mti_svvh_generic_type of opw : constant is 1;
end rv32i_ALU;
