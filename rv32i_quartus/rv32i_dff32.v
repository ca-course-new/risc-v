module rv32i_dff32(clk, rst, in, out);
input clk, rst;
input[31:0] in;
output reg[31:0] out;

always @(posedge rst, posedge clk)
begin
	if(rst) out<=0;
	else out<=in;
end

endmodule