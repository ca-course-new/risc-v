module rv32i_irom8k_ver2(clock_a, address_a, clock_b, address_b, q_a, q_b);
parameter dwidth = 32;
parameter awidth = 13;

input [awidth-1:0] address_a, address_b;
input clock_a, clock_b;
output reg [dwidth-1:0] q_a, q_b;

reg [dwidth-1:0] mem [2**awidth-1:0];

always @(posedge clock_a)
begin
	q_a <= mem[address_a];
end

always @(posedge clock_b)
begin
	q_b <= mem[address_b];
end

initial
begin
    $readmemh("rv32i_machine.hex", mem);
end

endmodule