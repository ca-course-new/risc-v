module rv32i_regFile(rst, clk, readReg1, readReg2, writeReg1, we1, writeData1, writeReg2, we2, writeData2, readData1, readData2);
input rst;
input clk;
input [4:0] readReg1;
input [4:0] readReg2;
input [4:0] writeReg1;
input we1; //write enable for WB stage
input [31:0] writeData1;
input [4:0] writeReg2;
input we2; //write enable for ID stage: JAL and JALR write return address into a register
input [31:0] writeData2;
output [31:0] readData1;
output [31:0] readData2;

//general-purppose registers, reset by the rst input
reg [31:0] genRegs [31:0]; 

//GPR names. In RISC-V ISA, registers no longer have specific names.
//Although there are still traditions about the typical function of each register
localparam X0 = 0;
localparam X1 = 1;
localparam X2 = 2;
localparam X3 = 3;
localparam X4 = 4;
localparam X5 = 5;
localparam X6 = 6;
localparam X7 = 7;
localparam X8 = 8;
localparam X9 = 9;
localparam X10 = 10;
localparam X11 = 11;
localparam X12 = 12;
localparam X13 = 13;
localparam X14 = 14;
localparam X15 = 15;
localparam X16 = 16;
localparam X17 = 17;
localparam X18 = 18;
localparam X19 = 19;
localparam X20 = 20;
localparam X21 = 21;
localparam X22 = 22;
localparam X23 = 23;
localparam X24 = 24;
localparam X25 = 25;
localparam X26 = 26;
localparam X27 = 27;
localparam X28 = 28;
localparam X29 = 29;
localparam X30 = 30;
localparam X31 = 31;

//The two read ports are not controlled by the clock input to the register file
//If required, the two outputs can only be buffered by external dffs
assign readData1 = genRegs[readReg1];
assign readData2 = genRegs[readReg2];

always @(posedge rst, posedge clk)
begin
	if(rst==1)
	begin
		genRegs[X0]<=0; //always be zero
		genRegs[X1]<=0;
		genRegs[X2]<=0;
		genRegs[X3]<=0;
		genRegs[X4]<=0;
		genRegs[X5]<=0;
		genRegs[X6]<=0;
		genRegs[X7]<=0;
		genRegs[X8]<=0;
		genRegs[X9]<=0;
		genRegs[X10]<=0;
		genRegs[X11]<=0;
		genRegs[X12]<=0;
		genRegs[X13]<=0;
		genRegs[X14]<=0;
		genRegs[X15]<=0;
		genRegs[X16]<=0;
		genRegs[X17]<=0;
		genRegs[X18]<=0;
		genRegs[X19]<=0;
		genRegs[X20]<=0;
		genRegs[X21]<=0;
		genRegs[X22]<=0;
		genRegs[X23]<=0;
		genRegs[X24]<=0;
		genRegs[X25]<=0;
		genRegs[X26]<=0;
		genRegs[X27]<=0;
		genRegs[X28]<=0;
		genRegs[X29]<=0;
		genRegs[X30]<=0;
		genRegs[X31]<=0;
	end
	else
	begin
		if(we1==1) //WB stage write
		begin
			if(writeReg1!=5'b00000) //no effect if writing to X0
			genRegs[writeReg1] <= writeData1;
		end
		if(we2==1) //ID stage: jal and jalr write
		begin
			if(writeReg2!=5'b00000) //no effect if writing to X0
			genRegs[writeReg2] <= writeData2;  	
		end
	end
end
endmodule