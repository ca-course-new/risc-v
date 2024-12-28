module dff2bit(clk, rst, in, out);
input clk, rst;
input [1:0] in;
output reg [1:0] out;

always @(posedge rst, posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
