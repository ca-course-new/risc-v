module rv32i_imem(clkA, addrA, addrB, dataOutA, dataOutB);
parameter dwidth = 32;
parameter awidth = 7;

input clkA;
input [awidth-1:0] addrA, addrB;
output reg [dwidth-1:0] dataOutA, dataOutB;

reg [dwidth-1:0] mem[2**awidth-1:0];


always @(posedge clkA)
begin
	dataOutA <= mem[addrA];
end

always @(posedge clkA)
begin
	dataOutB <= mem[addrB];
end

initial
begin
	$readmemh("test1.hex", mem);
end

endmodule