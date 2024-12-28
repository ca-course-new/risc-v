module rv32i_control(ins, JAL, JALR, JumpRegWrite, ALUOP, ALUSRC1, ALUSRC2, Branch, MemWrite, MemEnable, RegWrite, MemToReg);
input[31:0] ins;
output reg JAL, JALR, JumpRegWrite, Branch, MemWrite, MemEnable, RegWrite, MemToReg;
output reg[5:0] ALUOP; //ALU operation mode setup bits
output reg[3:0] ALUSRC1, ALUSRC2;

always @(ins)
begin
		case(ins[6:0])
		7'b0110011: //OP for R-type instructions
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			case(ins[14:12])
			3'b000: //SUB or ADD
			begin
				ALUOP <= (ins[30])?6'b000010:6'b000001;
				RegWrite <= 1;	
			end
			3'b001: //SLL
			begin
				ALUOP <= 6'b001110;
				RegWrite <= 1;			
			end
			3'b010: //SLT
			begin
				ALUOP <= 6'b000011;
				RegWrite <= 1;			
			end
			3'b011: //SLTU
			begin
				ALUOP <= 6'b000100;
				RegWrite <= 1;			
			end
			3'b100: //XOR
			begin
				ALUOP <= 6'b001101;
				RegWrite <= 1;			
			end
			3'b101: //SRA or SRL
			begin
				ALUOP <= (ins[30])?6'b010000:6'b001111;
				RegWrite <= 1;			
			end
			3'b110: //OR
			begin
				ALUOP <= 6'b001100;
				RegWrite <= 1;			
			end
			3'b111: //AND
			begin
				ALUOP <= 6'b001011;
				RegWrite <= 1;			
			end
			default:
			begin
				ALUOP <= 6'b000000;
				RegWrite <= 0; //illegal funct3 fields, the instruction cannot change any register
			end
			endcase
			ALUSRC1 <= 4'b0000;
			ALUSRC2 <= 4'b0000;
			Branch <= 0;
			MemWrite <= 0;
			MemEnable <= 0;
			MemToReg <= 0;
		end
		7'b0010011: //OP-IMM for I-type instructions
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			case(ins[14:12])
			3'b000: //ADDI
			begin
				ALUOP <= 6'b000001;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //choose sign extended 12-bit as the 2nd operand
			end
			3'b001: //SLLI
			begin
				ALUOP <= 6'b001110;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0010; //choose shmnt (bit24-20) as the 2nd operand		
			end
			3'b010: //SLTI
			begin
				ALUOP <= 6'b000011;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //choose sign extended 12-bit as the 2nd operand		
			end
			3'b011: //SLTIU
			begin
				ALUOP <= 6'b000100;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //choose sign extended 12-bit as the 2nd operand (sign extended first but treated as an unsigned)		
			end
			3'b100: //XORI
			begin
				ALUOP <= 6'b001101;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //choose sign extended 12-bit as the 2nd operand		
			end
			3'b101: //SRAI or SRLI
			begin
				ALUOP <= (ins[30])?6'b010000:6'b001111;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0010; //choose shmnt (bit24-20) as the 2nd operand
			end
			3'b110: //ORI
			begin
				ALUOP <= 6'b001100;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //choose sign extended 12-bit as the 2nd operand			
			end
			3'b111: //ANDI
			begin
				ALUOP <= 6'b001011;
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //choose sign extended 12-bit as the 2nd operand			
			end
			default:
			begin
				ALUOP <= 6'b000000;
				RegWrite <= 0; //illegal funct3 fields, the instruction cannot change any register
				ALUSRC2 <= 4'b0000;
			end
			endcase
			ALUSRC1 <= 4'b0000;
			Branch <= 0;
			MemWrite <= 0;
			MemEnable <= 0;
			MemToReg <= 0;
		end
		7'b1101111: //JAL
		begin
			JAL <= 1;
			JALR <= 0;
			JumpRegWrite <= 1;
			ALUOP <= 6'b000000; //jump does not use ALU
			RegWrite <= 0; //no need to write any register in the WB stage
			ALUSRC1 <= 4'b0000;
			ALUSRC2 <= 4'b0000;
			Branch <= 0;
			MemWrite <= 0;
			MemEnable <= 0;
			MemToReg <= 0;
		end
		7'b1100111: //JALR
		begin
			JAL <= 0;
			JALR <= 1;
			JumpRegWrite <= 1;
			ALUOP <= 6'b000000; //jump does not use ALU
			RegWrite <= 0; //no need to write any register in the WB stage
			ALUSRC1 <= 4'b0000;
			ALUSRC2 <= 4'b0000;
			Branch <= 0;
			MemWrite <= 0;
			MemEnable <= 0;
			MemToReg <= 0;		
		end
		7'b1100011: //BRANCH
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			case(ins[14:12])
			3'b000: //BEQ
			begin
				ALUOP <= 6'b000101;
				Branch <= 1;
			end
			3'b001: //BNE
			begin
				ALUOP <= 6'b000110;
				Branch <= 1;		
			end
			3'b100: //BLT
			begin
				ALUOP <= 6'b000111;
				Branch <= 1;
			end
			3'b101: //BGE
			begin
				ALUOP <= 6'b001000;
				Branch <= 1;
			end
			3'b110: //BLTU
			begin
				ALUOP <= 6'b001001;
				Branch <= 1;
			end
			3'b111: //BGEU
			begin
				ALUOP <= 6'b001010;
				Branch <= 1;
			end
			default: //not a branch instruction
			begin
				ALUOP <= 6'b000000;
				Branch <= 0;
			end
			endcase
			RegWrite <= 0; //no need to write any register in the WB stage
			ALUSRC1 <= 4'b0000;
			ALUSRC2 <= 4'b0000;
			MemWrite <= 0;
			MemEnable <= 0;
			MemToReg <= 0;		
		end
		7'b0000011: //LOAD instructions
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			ALUSRC1 <= 4'b0000; //base address uses rs1
			Branch <= 0;
			MemWrite <= 0;
			if((ins[14:12]!=3'b011)&&(ins[14:12]!=3'b110)&&(ins[14:12]!=3'b111))
			begin
				ALUOP <= 6'b000001; //use ALU addition mode to calculate data memory address
				RegWrite <= 1;
				ALUSRC2 <= 4'b0001; //offset uses sign extended 12 bits (b31-20)
				MemEnable <= 1;
				MemToReg <= 1;
			end
			else //invalid load
			begin
				ALUOP <= 6'b000000; //use ALU addition mode to calculate data memory address
				RegWrite <= 0;
				ALUSRC2 <= 4'b0000; //offset uses sign extended 12 bits (b31-20)
				MemEnable <= 0;
				MemToReg <= 0;		
			end
		end
		7'b0100011: //STORE instructions
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			ALUSRC1 <= 4'b0000; //base address uses rs1
			Branch <= 0;
			RegWrite <= 0;
			MemToReg <= 0;
			if((ins[14:12]==3'b000)||(ins[14:12]==3'b001)||(ins[14:12]==3'b010))
			begin
				ALUOP <= 6'b000001; //use ALU addition mode to calculate data memory address
				ALUSRC2 <= 4'b0011; //offset uses sign extended 12 bits (b31-25, b11-7), different from load!
				MemWrite <= 1;
				MemEnable <= 1;
			end
			else //invalid store
			begin
				ALUOP <= 6'b000000; //use ALU addition mode to calculate data memory address
				ALUSRC2 <= 4'b0000; //offset uses sign extended 12 bits (b31-20)
				MemWrite <= 0;
				MemEnable <= 0;	
			end	
		end
		7'b0010111: //AUIPC
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			ALUSRC1 <= 4'b0001; //PC as ALU's first source
			Branch <= 0;
			RegWrite <= 1;
			MemToReg <= 0;
			ALUOP <= 6'b000001; //use ALU addition mode to calculate PC + Upper Immediate for AUIPC
			ALUSRC2 <= 4'b0100; //imm20 bits (bit31-12) as the upper immediate for the second source of ALU
			MemWrite <= 0;
			MemEnable <= 0;
		end
		7'b0110111: //LUI
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			ALUSRC1 <= 4'b0010; //0 as ALU's first source
			Branch <= 0;
			RegWrite <= 1;
			MemToReg <= 0;
			ALUOP <= 6'b000001; //use ALU addition mode to calculate 0 + upper immediate
			ALUSRC2 <= 4'b0100; //imm20 bits (bit31-12) as the upper immediate for the second source of ALU
			MemWrite <= 0;
			MemEnable <= 0;	
		end
		default: //illegal opcode
		begin
			JAL <= 0;
			JALR <= 0;
			JumpRegWrite <= 0;
			ALUSRC1 <= 4'b0000; 
			Branch <= 0;
			RegWrite <= 0;
			MemToReg <= 0;
			ALUOP <= 6'b000000; 
			ALUSRC2 <= 4'b0000;
			MemWrite <= 0;
			MemEnable <= 0;	
		end
		endcase	
end

endmodule
