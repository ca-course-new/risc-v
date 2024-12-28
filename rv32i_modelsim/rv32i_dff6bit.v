module rv32i_dff6bit(clk, rst, in, en, clr, out);
input clk, rst;
input [5:0] in;
input en;
input clr;
output reg [5:0] out;

always @(posedge rst, posedge clk)
begin
if(rst) out<=0;
else 
begin
	if(clr) out<=0;
	else out<=(en)?in:out;
end
end

endmodule
