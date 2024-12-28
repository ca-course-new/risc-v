module dff1bit(clk, rst, in, out);
input clk, rst;
input in;
reg out;
output out;

always @(posedge rst, posedge clk)
begin
if(rst) out<=0;
else out<=in;
end

endmodule
