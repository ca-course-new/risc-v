module rv32i_mux32bit4ch(in0, in1, in2, in3, sel, val);

input [31:0] in0;
input [31:0] in1;
input [31:0] in2;
input [31:0] in3;
input [1:0] sel;
output reg[31:0] val;

always @(sel, in0, in1, in2, in3)
begin
	case(sel)
	2'b00: val<=in0;
	2'b01: val<=in1;
	2'b10: val<=in2;
	2'b11: val<=in3;
	endcase
end

endmodule
