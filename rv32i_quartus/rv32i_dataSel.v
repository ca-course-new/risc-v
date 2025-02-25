module rv32i_dataSel(ins, regData1, regData2, pc, sel1, sel2, out1, out2);
input[31:0] ins, regData1, regData2, pc;
input[3:0] sel1, sel2;
output reg[31:0] out1, out2;

always @(sel1)
begin
	case(sel1)
	4'b0000: //regular instructions use RS1 as the first input to the ALU
	begin
		out1 <= regData1;
	end
	4'b0001: //AUIPC uses PC as the first input to the ALU
	begin
		out1 <= pc; 
	end
	4'b0010: //LUI uses 0 as the first input to the ALU
	begin
		out1 <= 32'b0;
	end
	default: //illegal source
	begin
		out1 <= 32'b0;
	end
	endcase
end

always @(sel2)
begin
	case(sel2)
	4'b0000: //use RS2 as the second input to the ALU
	begin
		out2 <= regData2;
	end
	4'b0001: //sign extend bit31-bit20 (imm[11:0]) to be the second input to the ALU
	begin
		out2 <= (ins[31])?{20'hFFFFF, ins[31:20]}:{20'h00000, ins[31:20]}; 
	end
	4'b0010: //5-bit shift amount as the second input to the ALU
	begin
		out2 <= {27'b0, ins[24:20]};
	end
	4'b0011: //sign extend bit31-bit25, bit11-bit7 to be the second input to the ALU
	begin
		out2 <= (ins[31])?{20'hFFFFF, ins[31:25], ins[11:7]}:{20'h00000, ins[31:25], ins[11:7]};
	end
	4'b0100: //Upper immediate bit31-bit12 (imm31-imm12) to be the second input to the ALU
   begin
		out2 <= {ins[31:12], 12'h000};
	end
	default: //illegal source 
	begin
		out2 <= 32'b0;
	end
	endcase
end

endmodule
