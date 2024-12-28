module rv32i_dff32bit(clk, rst, in, en, clr, out);
input clk, rst;
input [31:0] in;
input en;
input clr;
reg [31:0] out;
output [31:0] out;

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
