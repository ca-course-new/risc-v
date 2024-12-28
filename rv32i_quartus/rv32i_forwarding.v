module rv32i_forwarding(DE_rs1, DE_rs2, EM_rd, MW_rd, WB_rd, EM_RegWrite, MW_RegWrite, WB_RegWrite, 
DE_OP, EM_OP, MW_OP, WB_OP, forwardA, forwardB, forwardC);
input[4:0] DE_rs1, DE_rs2, EM_rd, MW_rd, WB_rd;
input EM_RegWrite, MW_RegWrite, WB_RegWrite;
input[6:0] DE_OP, EM_OP, MW_OP, WB_OP;
output reg[1:0] forwardA, forwardB, forwardC;

always @(DE_rs1, DE_rs2, EM_rd, MW_rd, WB_rd, EM_RegWrite, MW_RegWrite, WB_RegWrite, DE_OP, EM_OP, MW_OP, WB_OP)
begin
	//rs1 forwarding
	//Branch, Load, Store, OP-imm, and OP instructions must read rs1 and possibly need forwarding
	//These instructions need rs1 no later than the beginning of EX
	if((DE_OP==7'b1100011)||(DE_OP==7'b0000011)||(DE_OP==7'b0100011)||(DE_OP==7'b0010011)||(DE_OP==7'b0110011)) 
	begin
		if((EM_RegWrite==1)&&(EM_rd!=0)&&(EM_rd==DE_rs1)&&(EM_OP!=7'b0000011)) //the instruction in MEM cannot be a load
		begin
			forwardA <= 2'b01; //forward from EX/MEM
		end
		else if((MW_RegWrite==1)&&(MW_rd!=0)&&(MW_rd==DE_rs1))
		begin
			forwardA <= 2'b10; //forward from MEM/WB
		end
		else if((WB_RegWrite==1)&&(WB_rd!=0)&&(WB_rd==DE_rs1))
		begin
			forwardA <= 2'b11; //forward from Write Buffer
		end
		else
		begin
			forwardA <= 2'b00; //default: no forwarding
		end
	end
	else //LUI, AUIPC, JAL and JALR do not need any forwarding for their EX stage
	begin
		forwardA <= 2'b00;
	end

	//rs2 forwarding
	//Branch, OP must read rs2 and possibly need forwarding
   //Branch and OP can use rs2 no later than the beginning of EX
	if((DE_OP==7'b1100011)||(DE_OP==7'b0110011))
	begin
		if((EM_RegWrite==1)&&(EM_rd!=0)&&(EM_rd==DE_rs2)&&(EM_OP!=7'b0000011)) //the instruction in MEM cannot be a load
		begin
			forwardB <= 2'b01; //forward from EX/MEM
		end
		else if((MW_RegWrite==1)&&(MW_rd!=0)&&(MW_rd==DE_rs2))
		begin
			forwardB <= 2'b10; //forward from MEM/WB
		end
		else if((WB_RegWrite==1)&&(WB_rd!=0)&&(WB_rd==DE_rs2))
		begin
			forwardB <= 2'b11; //forward from Write Buffer
		end
		else
		begin
			forwardB <= 2'b00; //default: no forwarding
		end	
	end
	else
	begin
		forwardB <= 2'b00;
	end
	
	//rs2 forwarding for Store instruction
	//Store needs rs2 no later than the beginning of MEM, however, we simplify the design by requiring
   //rs2 to be available in EX stage.
	//For future optimizations, consider moving the following as a separate forwarding unit for store
	//into the MEM stage
	if(DE_OP==7'b0100011)
	begin
		if((EM_RegWrite==1)&&(EM_rd!=0)&&(EM_rd==DE_rs2)&&(EM_OP!=7'b0000011)) //the instruction in MEM cannot be a load
		begin
			forwardC <= 2'b01; //forward from EX/MEM
		end
		else if((MW_RegWrite==1)&&(MW_rd!=0)&&(MW_rd==DE_rs2))
		begin
			forwardC <= 2'b10; //forward from MEM/WB
		end
		else if((WB_RegWrite==1)&&(WB_rd!=0)&&(WB_rd==DE_rs2))
		begin
			forwardC <= 2'b11; //forward from Write Buffer
		end
		else
		begin
			forwardC <= 2'b00; //default: no forwarding
		end	
	end
	else
	begin
		forwardC <= 2'b00;
	end	
end

endmodule
