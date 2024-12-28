module rv32i_irom8k_ver4(data_a, data_b, address_a, address_b, we_a, we_b, clk, q_a, q_b);
parameter dwidth = 32;
parameter awidth = 12;

input [dwidth-1:0] data_a, data_b;
input [awidth-1:0] address_a, address_b;
input we_a, we_b, clk;
output reg [dwidth-1:0] q_a, q_b;

reg [dwidth-1:0] mem [2**awidth-1:0];

always @(posedge clk)
begin
    if(we_a) 
	 begin
		mem[address_a] <= data_a;
		q_a <= data_a;
	 end
	 else
	 begin 
		q_a <= mem[address_a];
	 end
end

always @(posedge clk)
begin
    if(we_b) 
	 begin
		mem[address_b] <= data_b;
		q_b <= data_b;
	 end
	 else
	 begin 
		q_b <= mem[address_b];
	 end
end

initial
begin
    $readmemh("rv32i_machine.hex", mem);
end

endmodule