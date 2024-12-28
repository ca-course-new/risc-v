module rv32i_dff1bit(clk, rst, in, en, clr, out);
input clk, rst;
input in;
input en;
input clr;
reg out;
output out;

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
