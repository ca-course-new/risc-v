module rv32i_jAddrCalc(pc, ins, rs1, JAL_Addr, JALR_Addr);
input[31:0] pc, ins, rs1;
output[31:0] JAL_Addr, JALR_Addr;
wire[31:0] temp;

assign JAL_Addr = pc + {(ins[31])?11'h7FF:11'h000, ins[31], ins[19:12], ins[20], ins[30:21], 1'b0};

assign temp = rs1 + {(ins[31])?20'hFFFFF:20'h00000, ins[31:20]};

assign JALR_Addr = {temp[31:1], 1'b0};

endmodule
