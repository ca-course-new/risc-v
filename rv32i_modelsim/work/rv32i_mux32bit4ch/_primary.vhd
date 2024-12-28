library verilog;
use verilog.vl_types.all;
entity rv32i_mux32bit4ch is
    port(
        in0             : in     vl_logic_vector(31 downto 0);
        in1             : in     vl_logic_vector(31 downto 0);
        in2             : in     vl_logic_vector(31 downto 0);
        in3             : in     vl_logic_vector(31 downto 0);
        sel             : in     vl_logic_vector(1 downto 0);
        val             : out    vl_logic_vector(31 downto 0)
    );
end rv32i_mux32bit4ch;
