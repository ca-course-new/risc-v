module rv32i_pcSel(in0, in1, in2, in3, s1, s2, s3, out);
input[31:0] in0, in1, in2, in3;
input s1, s2, s3;
output reg[31:0] out;

always @(s1, s2, s3)
begin
	case({s3, s2, s1})
	3'b001: //Branch is given highest priority
	begin
	out<=in1;
	end
	3'b011: //Branch is given highest priority
	begin
	out<=in1;
	end
	3'b101: //Branch is given highest priority
	begin
	out<=in1;
	end
	3'b111: //Branch is given highest priority
	begin
	out<=in1;
	end
	3'b010: //JAL
	begin
	out<=in2;
	end
	3'b100: //JALR
	begin
	out<=in3;
	end
	default: //PC+4
	begin
	out<=in0;
	end
	endcase
end

endmodule
