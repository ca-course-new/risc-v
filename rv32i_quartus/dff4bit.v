module dff4bit(clk, rst, in, out);
input clk, rst;
input [3:0] in;
reg [3:0] out;
output [3:0] out;

always @(posedge rst, posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
