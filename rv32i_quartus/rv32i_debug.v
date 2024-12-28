module rv32i_debug(rst, clk, cs, we, addr, buttonIn, diodeIn, buttonOut, diodeOut);
input clk, rst, cs, we;
input[31:0] addr;
input[31:0] buttonIn, diodeIn;
output reg[31:0] buttonOut, diodeOut;

always @(posedge rst, posedge clk) //CPU read the button values using LW
begin
	if(rst)
	begin
		buttonOut<=32'bz;
	end
	else
	begin
		if(cs&&~we&&(addr[31:16]==16'hE001)) //address range E0010000~E001FFFF reserved for debugging purpose
		begin
			case(addr[15:0])
			16'h0000: buttonOut<=buttonIn; //sample the button value
			16'h0004: buttonOut<=32'hA1B2C3D4; //read a constant value for debugging purpose 
			default: buttonOut<=32'bz;
			endcase
		end
		else buttonOut<=32'bz;
	end
end

always @(posedge rst, posedge clk) //turn on/off LEDs through the diode port 
begin
	if(rst) diodeOut<=0; //turn off all LEDs after reset
	else
	begin
		if(cs&&we&&(addr[31:16]==16'hE001))
		begin
			case(addr[15:0])
			16'h0000: diodeOut<=diodeIn; //change diode status
			default: diodeOut<=diodeOut;//keep diode status
			endcase
		end
		else diodeOut<=diodeOut;
	end
end

endmodule

