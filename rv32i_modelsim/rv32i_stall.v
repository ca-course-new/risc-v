module rv32i_stall(FD_rs1, FD_rs2, DE_rd, EM_rd, MW_rd, FD_OP, DE_OP, EM_OP, MW_OP, stall, stallN, forward);
input[4:0] FD_rs1, FD_rs2, DE_rd, EM_rd, MW_rd;
input[6:0] FD_OP, DE_OP, EM_OP, MW_OP;
output reg stall, stallN;
output reg[1:0] forward;

always @(FD_rs1, FD_rs2, DE_rd, EM_rd, MW_rd, FD_OP, DE_OP, EM_OP, MW_OP)
begin
	if(FD_OP!=7'b1100111) //not a JALR in the ID stage
	begin
		if(DE_OP==7'b0000011)//possible for a load-use hazard
		begin
			if((FD_OP==7'b1100011)||(FD_OP==7'b0100011)||(FD_OP==7'b0110011)) //Branch, Store or OP have two consumers
			begin
				if(((FD_rs1==DE_rd)||(FD_rs2==DE_rd))&&(DE_rd!=0)) //stall if any of the two consumers depends on the previous load
				begin
					stall<=1;
					stallN<=0;
					forward<=2'b00;
				end
				else
				begin
				   stall<=0;
					stallN<=1;
					forward<=2'b00;
				end
			end
			else if((FD_OP==7'b0010011)||(FD_OP==7'b0000011)) //Load or OP-IMM has just one consumer
			begin
				if((FD_rs1==DE_rd)&&(DE_rd!=0)) //stall if there is data dependence to the previous load
				begin
				   stall<=1;
					stallN<=0;
					forward<=2'b00;
				end
				else
				begin
				   stall<=0;
					stallN<=1;
					forward<=2'b00;
				end
			end
			else //illgal opcode of the instruction in the ID stage
			begin
			   stall<=0;
				stallN<=1;
				forward<=2'b00;
			end
		end
		else //impossible for a load-use hazard since load is not in the EX stage
		begin
		   stall<=0;
			stallN<=1;
			forward<=2'b00;
		end
	end
	else //A JALR in the ID stage
	begin
		if(((DE_OP==7'b0110111)||(DE_OP==7'b0010111)||(DE_OP==7'b0000011)||(DE_OP==7'b0010011)||(DE_OP==7'b0110011))&&(DE_rd!=0)&&(DE_rd==FD_rs1)) //1st preceding
		begin
		   stall<=1;
			stallN<=0;
			forward<=2'b00;
		end
		else if(((EM_OP==7'b0110111)||(EM_OP==7'b0010111)||(EM_OP==7'b0010011)||(EM_OP==7'b0110011))&&(EM_rd!=0)&&(EM_rd==FD_rs1)) //2nd preceding non-load
		begin
		   stall<=0;
			stallN<=1;
			forward<=2'b01; //forward from EX/MEM
		end
		else if((EM_OP==7'b0000011)&&(EM_rd!=0)&&(EM_rd==FD_rs1)) //2nd preceding load
		begin
		   stall<=1;
			stallN<=0; //another stall must be inserted even if load is two cycles ahead of JALR
			forward<=2'b00;
		end
      else if(((MW_OP==7'b0110111)||(MW_OP==7'b0010111)||(MW_OP==7'b0000011)||(MW_OP==7'b0010011)||(MW_OP==7'b0110011))&&(MW_rd!=0)&&(MW_rd==FD_rs1))
      begin
			stall<=0;
			stallN<=1;
			forward<=2'b10; //forward from MEM/WB
		end
		else //all other cases no stall, no forwarding
		begin
			stall<=0;
			stallN<=1;
			forward<=2'b00;
		end
	end	
end

endmodule
