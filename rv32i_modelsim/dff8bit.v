module dff8bit(clk, rst, in, out);
input clk, rst;
input [7:0] in;
output reg [7:0] out;

always @(posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
