module dff1bit(clk, rst, in, out);
input clk, rst;
input in;
output reg out;

always @(posedge rst, posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
