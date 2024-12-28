module dff16bit(clk, rst, in, out);
input clk, rst;
input [15:0] in;
reg [15:0] out;
output [15:0] out;

always @(posedge rst, posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
