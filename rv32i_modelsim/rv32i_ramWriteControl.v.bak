//Each of data memories (4K, 2K or 1K) has four 8-bit chips connected in parallel to provide a maximum 32-bit width
//However, each 8-bit chip can be write-enabled separately, making SB and SH possible without having to write a full word
module rv32i_ramWriteControl(WE_IN, funct3, cpuAddr, dataIn, WE_OUT4K, WE_OUT2K, dataOut);
input WE_IN; //WE must be set to enable write to any memory chip 
input[2:0] funct3; //bit14-bit12 from instruction to set the store mode as SB, SH, or SW
input[31:0] cpuAddr; //cpuAddr to select from 4K, 2K and 1K memories
input[31:0] dataIn;

output reg[3:0] WE_OUT4K, WE_OUT2K;

output reg[31:0] dataOut;

always @(WE_IN, funct3, cpuAddr)
begin
	if(~WE_IN) //if not a store instruction at all, disable all the write-enable signals
	begin
		WE_OUT4K <= 4'b0000;
		WE_OUT2K <= 4'b0000;
		dataOut <= 32'h00000000;
	end
	else
	begin
		if(cpuAddr[31:14]==18'h00002) //address space of dram4K 32'h00008000 to 32'h0000BFFF, 2^14 bytes (16 KB or 4KW)
		begin
			WE_OUT2K <= 4'b0000;	
			case(funct3)
			3'b000: //SB
			begin
				if(cpuAddr[1:0]==2'b00)
				begin
					WE_OUT4K <= 4'b0001;
					dataOut <= {24'h000000, dataIn[7:0]};
				end
				else if(cpuAddr[1:0]==2'b01)
				begin
					WE_OUT4K <= 4'b0010;
					dataOut <= {16'h0000, dataIn[7:0], 8'h00};
				end
				else if(cpuAddr[1:0]==2'b10)
				begin
					WE_OUT4K <= 4'b0100;
					dataOut <= {8'h00, dataIn[7:0], 16'h0000};
				end
				else
				begin
					WE_OUT4K <= 4'b1000;
					dataOut <= {dataIn[7:0], 24'h000000};
				end				
			end
			3'b001: //SH
			begin
				if(cpuAddr[1:0]==2'b00) //write to lower half
				begin
					WE_OUT4K <= 4'b0011;
					dataOut <= {16'h0000, dataIn[15:0]};
				end
				else if(cpuAddr[1:0]==2'b10) //write to upper half
				begin
					WE_OUT4K <= 4'b1100;
					dataOut <= {dataIn[15:0], 16'h0000};
				end
				else //unaligned SH
				begin
					WE_OUT4K <= 4'b0000;
					dataOut <= 32'h00000000;
				end
			end
			3'b010: //SW
			begin
				WE_OUT4K <= 4'b1111;
				dataOut <= dataIn;
			end
			default: //illegal funct3
			begin
				WE_OUT4K <= 4'b0000;
				dataOut <= 32'h00000000;		
			end
			endcase
		end		
		else if(cpuAddr[31:13]==19'h00006) //address space of dram2K 32'h0000C000 to 32'h0000DFFF, 2^13 bytes (8 KB or 2KW)
		begin
			WE_OUT4K <= 4'b0000;	
			case(funct3)
			3'b000: //SB
			begin
				if(cpuAddr[1:0]==2'b00)
				begin
					WE_OUT2K <= 4'b0001;
					dataOut <= {24'h000000, dataIn[7:0]};
				end
				else if(cpuAddr[1:0]==2'b01)
				begin
					WE_OUT2K <= 4'b0010;
					dataOut <= {16'h0000, dataIn[7:0], 8'h00};
				end
				else if(cpuAddr[1:0]==2'b10)
				begin
					WE_OUT2K <= 4'b0100;
					dataOut <= {8'h00, dataIn[7:0], 16'h0000};
				end
				else
				begin
					WE_OUT2K <= 4'b1000;
					dataOut <= {dataIn[7:0], 24'h000000};
				end				
			end
			3'b001: //SH
			begin
				if(cpuAddr[1:0]==2'b00) //write to lower half
				begin
					WE_OUT2K <= 4'b0011;
					dataOut <= {16'h0000, dataIn[15:0]};
				end
				else if(cpuAddr[1:0]==2'b10) //write to upper half
				begin
					WE_OUT2K <= 4'b1100;
					dataOut <= {dataIn[15:0], 16'h0000};
				end
				else //unaligned SH
				begin
					WE_OUT2K <= 4'b0000;
					dataOut <= 32'h00000000;
				end
			end
			3'b010: //SW
			begin
				WE_OUT2K <= 4'b1111;
				dataOut <= dataIn;
			end
			default: //illegal funct3
			begin
				WE_OUT2K <= 4'b0000;
				dataOut <= 32'h00000000;		
			end
			endcase	
		end		
		else //illegal write address provided
		begin
			WE_OUT4K <= 4'b0000;
			WE_OUT2K <= 4'b0000;
			dataOut <= 32'h00000000;
		end
	end
end

endmodule

