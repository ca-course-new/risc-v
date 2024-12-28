module dff8bit(clk, rst, in, out);
input clk, rst;
input [7:0] in;
reg [7:0] out;
output [7:0] out;

always @(posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
