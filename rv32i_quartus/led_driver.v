module led_driver(rst, clk, out);
input rst, clk;
output out;

reg[25:0] count;
assign out=count[25];

always @(posedge rst, posedge clk)
begin
	if(rst) count<=26'b0;
	else count<=count+1;
end

endmodule
