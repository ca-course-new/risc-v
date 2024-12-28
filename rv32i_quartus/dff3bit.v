module dff3bit(clk, rst, in, out);
input clk, rst;
input [2:0] in;
reg [2:0] out;
output [2:0] out;

always @(posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
