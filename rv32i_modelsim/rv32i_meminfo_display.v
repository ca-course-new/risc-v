//This module lets memory access 
module rv32i_meminfo_display(MemToReg, MemEnable, MemAddrIn, MemDataIn, MemAddrOut, MemDataOut);
input MemToReg, MemEnable;
input[31:0] MemAddrIn, MemDataIn;
output[31:0] MemAddrOut, MemDataOut;

assign MemAddrOut = (MemEnable==1)?MemAddrIn:0;
assign MemDataOut = ((MemEnable==1)&&(MemToReg==0))?MemDataIn:0;

endmodule