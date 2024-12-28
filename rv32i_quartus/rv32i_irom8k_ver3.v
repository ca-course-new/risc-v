module rv32i_irom8k_ver3(address_a, clock_a, enable_a, q_a);
parameter dwidth = 32;
parameter awidth = 12;

input [awidth-1:0] address_a;
input clock_a, enable_a;
output reg [dwidth-1:0] q_a;

reg [dwidth-1:0] mem [2**awidth-1:0];

always @(posedge clock_a)
begin
    if(enable_a) q_a <= mem[address_a];
end

initial
begin
    $readmemh("rv32i_machine.hex", mem);
end

endmodule