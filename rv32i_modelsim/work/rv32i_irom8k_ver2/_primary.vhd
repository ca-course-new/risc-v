library verilog;
use verilog.vl_types.all;
entity rv32i_irom8k_ver2 is
    generic(
        dwidth          : integer := 32;
        awidth          : integer := 13
    );
    port(
        clock_a         : in     vl_logic;
        address_a       : in     vl_logic_vector;
        clock_b         : in     vl_logic;
        address_b       : in     vl_logic_vector;
        q_a             : out    vl_logic_vector;
        q_b             : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of dwidth : constant is 1;
    attribute mti_svvh_generic_type of awidth : constant is 1;
end rv32i_irom8k_ver2;
