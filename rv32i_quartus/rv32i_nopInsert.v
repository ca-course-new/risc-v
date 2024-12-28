module rv32i_nopInsert(rst, clk, jal, jalr, br, br_ex, stallN, sel);
input rst, clk, jal, jalr, br, br_ex, stallN;
output reg sel;


always @(posedge rst, posedge clk)
begin
	if(rst) sel<=1;
	else
	begin
		if((jal||jalr||br||br_ex)&&stallN) sel<=0;
		else sel<=1;
	end
end

endmodule
