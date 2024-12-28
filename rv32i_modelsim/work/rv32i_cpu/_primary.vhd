library verilog;
use verilog.vl_types.all;
entity rv32i_cpu is
    generic(
        dwidth          : integer := 32;
        awidth          : integer := 13;
        awidth4         : integer := 12;
        awidth2         : integer := 11;
        awidth_mirror   : integer := 14;
        dwidth4         : integer := 8;
        dwidth2         : integer := 8
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of dwidth : constant is 1;
    attribute mti_svvh_generic_type of awidth : constant is 1;
    attribute mti_svvh_generic_type of awidth4 : constant is 1;
    attribute mti_svvh_generic_type of awidth2 : constant is 1;
    attribute mti_svvh_generic_type of awidth_mirror : constant is 1;
    attribute mti_svvh_generic_type of dwidth4 : constant is 1;
    attribute mti_svvh_generic_type of dwidth2 : constant is 1;
end rv32i_cpu;
