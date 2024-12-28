//Little Endian
//instruction memory only support read
module rv32i_ramSel(irData, drData4K, drData2K, cpuAddr, funct3, out);

input[31:0] irData, drData4K, drData2K;
input[31:0] cpuAddr;
input[2:0] funct3;

output reg [31:0] out;

always @(cpuAddr, funct3)
begin
	if(cpuAddr[31:15]==17'h00000) //address space of iram 32'h00000000 to 32'h00007FFF, 2^15 bytes (32KB or 8KW)
	begin
		case(funct3)
		3'b000://LB
		begin
			case(cpuAddr[1:0])
			2'b00: //right most byte
			begin
				out<=(irData[7])?{24'hFFFFFF, irData[7:0]}:{24'h000000, irData[7:0]};
			end
			2'b01: //middle right byte
			begin
				out<=(irData[15])?{24'hFFFFFF, irData[15:8]}:{24'h000000, irData[15:8]};
			end
			2'b10: //middle left byte
			begin
				out<=(irData[23])?{24'hFFFFFF, irData[23:16]}:{24'h000000, irData[23:16]};
			end
			2'b11: //left most byte
			begin
				out<=(irData[31])?{24'hFFFFFF, irData[31:24]}:{24'h000000, irData[31:24]};
			end
			endcase
		end
		3'b001://LH: alignment is required
		begin
			if(cpuAddr[1]==0)//lower half
			begin
				out<=(irData[15])?{16'hFFFF, irData[15:0]}:{16'h0000, irData[15:0]};
			end
			else//upper half
			begin
				out<=(irData[31])?{16'hFFFF, irData[31:16]}:{16'h0000, irData[31:16]};
			end
		end
		3'b010://LW: alignment is required
		begin
			out<=irData;
		end
		3'b100://LBU
		begin
			case(cpuAddr[1:0])
			2'b00: //right most byte
			begin
				out<={24'h000000, irData[7:0]};
			end
			2'b01: //middle right byte
			begin
				out<={24'h000000, irData[15:8]};
			end
			2'b10: //middle left byte
			begin
				out<={24'h000000, irData[23:16]};
			end
			2'b11: //left most byte
			begin
				out<={24'h000000, irData[31:24]};
			end
			endcase			
		end
		3'b101://LHU
		begin
			if(cpuAddr[1]==0)//lower half
			begin
				out<={16'h0000, irData[15:0]};
			end
			else//upper half
			begin
				out<={16'h0000, irData[31:16]};
			end
		end
		default: //illegal load
		begin
			out<=32'bz;
		end
		endcase
	end
	else if(cpuAddr[31:14]==18'h00002) //address space of dram4K 32'h00008000 to 32'h0000BFFF, 2^14 bytes (16 KB or 4KW)
	begin
		case(funct3)
		3'b000://LB
		begin
			case(cpuAddr[1:0])
			2'b00: //right most byte
			begin
				out<=(drData4K[7])?{24'hFFFFFF, drData4K[7:0]}:{24'h000000, drData4K[7:0]};
			end
			2'b01: //middle right byte
			begin
				out<=(drData4K[15])?{24'hFFFFFF, drData4K[15:8]}:{24'h000000, drData4K[15:8]};
			end
			2'b10: //middle left byte
			begin
				out<=(drData4K[23])?{24'hFFFFFF, drData4K[23:16]}:{24'h000000, drData4K[23:16]};
			end
			2'b11: //left most byte
			begin
				out<=(drData4K[31])?{24'hFFFFFF, drData4K[31:24]}:{24'h000000, drData4K[31:24]};
			end
			endcase
		end
		3'b001://LH: alignment is required
		begin
			if(cpuAddr[1]==0)//lower half
			begin
				out<=(drData4K[15])?{16'hFFFF, drData4K[15:0]}:{16'h0000, drData4K[15:0]};
			end
			else//upper half
			begin
				out<=(drData4K[31])?{16'hFFFF, drData4K[31:16]}:{16'h0000, drData4K[31:16]};
			end
		end
		3'b010://LW: alignment is required
		begin
			out<=drData4K;
		end
		3'b100://LBU
		begin
			case(cpuAddr[1:0])
			2'b00: //right most byte
			begin
				out<={24'h000000, drData4K[7:0]};
			end
			2'b01: //middle right byte
			begin
				out<={24'h000000, drData4K[15:8]};
			end
			2'b10: //middle left byte
			begin
				out<={24'h000000, drData4K[23:16]};
			end
			2'b11: //left most byte
			begin
				out<={24'h000000, drData4K[31:24]};
			end
			endcase			
		end
		3'b101://LHU
		begin
			if(cpuAddr[1]==0)//lower half
			begin
				out<={16'h0000, drData4K[15:0]};
			end
			else//upper half
			begin
				out<={16'h0000, drData4K[31:16]};
			end
		end
		default: //illegal load
		begin
			out<=32'bz;
		end
		endcase
	end
	else if(cpuAddr[31:13]==19'h00006) //address space of dram2K 32'h0000C000 to 32'h0000DFFF, 2^13 bytes (8 KB or 2KW)
	begin
		case(funct3)
		3'b000://LB
		begin
			case(cpuAddr[1:0])
			2'b00: //right most byte
			begin
				out<=(drData2K[7])?{24'hFFFFFF, drData2K[7:0]}:{24'h000000, drData2K[7:0]};
			end
			2'b01: //middle right byte
			begin
				out<=(drData2K[15])?{24'hFFFFFF, drData2K[15:8]}:{24'h000000, drData2K[15:8]};
			end
			2'b10: //middle left byte
			begin
				out<=(drData2K[23])?{24'hFFFFFF, drData2K[23:16]}:{24'h000000, drData2K[23:16]};
			end
			2'b11: //left most byte
			begin
				out<=(drData2K[31])?{24'hFFFFFF, drData2K[31:24]}:{24'h000000, drData2K[31:24]};
			end
			endcase
		end
		3'b001://LH: alignment is required
		begin
			if(cpuAddr[1]==0)//lower half
			begin
				out<=(drData2K[15])?{16'hFFFF, drData2K[15:0]}:{16'h0000, drData2K[15:0]};
			end
			else//upper half
			begin
				out<=(drData2K[31])?{16'hFFFF, drData2K[31:16]}:{16'h0000, drData2K[31:16]};
			end
		end
		3'b010://LW: alignment is required
		begin
			out<=drData2K;
		end
		3'b100://LBU
		begin
			case(cpuAddr[1:0])
			2'b00: //right most byte
			begin
				out<={24'h000000, drData2K[7:0]};
			end
			2'b01: //middle right byte
			begin
				out<={24'h000000, drData2K[15:8]};
			end
			2'b10: //middle left byte
			begin
				out<={24'h000000, drData2K[23:16]};
			end
			2'b11: //left most byte
			begin
				out<={24'h000000, drData2K[31:24]};
			end
			endcase			
		end
		3'b101://LHU
		begin
			if(cpuAddr[1]==0)//lower half
			begin
				out<={16'h0000, drData2K[15:0]};
			end
			else//upper half
			begin
				out<={16'h0000, drData2K[31:16]};
			end
		end
		default: //illegal load
		begin
			out<=32'bz;
		end
		endcase
	end
	else
	begin
		out<=32'bz;
	end	
end

endmodule
