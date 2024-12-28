// The top-level Verilog HDL file to simulate a 5-stage pipelined RV32I CPU
// Debugging ports are added
// For debugging purpose in computer architecture courses without actual FPGA Hardware
// Version: 1.0
// Author: Ming Li

`timescale 1ns/1ns

module rv32i_cpu;
reg clk, rst; //input

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////// CPU Schematics Described with Verilog HDL ///////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////
//////////////////////// IF stage /////////////////////////
///////////////////////////////////////////////////////////
wire [31:0] pc_or_plus4, br_addr, jal_addr, jalr_addr;
wire br, jal, jalr;
wire [31:0] pc_src;
//1. PC target selector
rv32i_pcSel inst40(pc_or_plus4, br_addr, jal_addr, jalr_addr, br, jal, jalr, pc_src);

wire stalln;
wire [31:0] pc;
//2. PC register
rv32i_dff32bit inst82(clk, rst, pc_src, stalln, 1'b0, pc);


wire [31:0] res_mem;
reg [31:0] ins_src, iromdata;
//3. Instruction Memory - Read Only
//rv32i_irom8k_ver2 inst23(clk, pc[14:2], clk, res_mem[14:2], ins_src, iromdata);

//3. Instruction Memory - Built In Here
parameter dwidth = 32;
parameter awidth = 13;
parameter awidth4 = 12;
parameter awidth2 = 11;
parameter awidth_mirror = 14;
reg [dwidth-1:0] imem [2**awidth-1:0];


always @(posedge clk)
begin
  ins_src <= imem[pc[14:2]];
end

always @(posedge clk)
begin
  iromdata <= imem[res_mem[14:2]];
end

initial
begin
    $readmemh("rv32i_machine.hex", imem);
end
///////////////////////////////

wire stall_input;
wire stall_output;
//4-5. Stall Signal Locker
assign stall_input = (~rst)&stalln; //inst8 and inst70
dff1bit inst28(clk, rst, stall_input, stall_output);

wire [31:0] pre_ins, next_ins;
//6. Instruction Stall Selector
rv32i_mux32 inst30(pre_ins, ins_src, stall_output, next_ins);

//7. Inst Buffer
dff32bit inst31(clk, rst, ins_src, pre_ins);

wire [31:0] pcplus4;
//8. PC plus 4 adder
rv32i_adder32bit inst14(32'h00000004, pc, pcplus4);

wire branch, branch_ex;
wire pc_freezer_sel;
//9-10. PC freezer
assign pc_freezer_sel = ~(branch | branch_ex | jal | jalr); //nor4, inst33
rv32i_mux32 inst34(pc, pcplus4, pc_freezer_sel, pc_or_plus4);
 
wire nopinsertn;
//11. NOP Inserter
rv32i_nopInsert inst20(rst, clk, jal, jalr, branch, branch_ex, stalln, nopinsertn);

wire [31:0] ins;
//12. Instruction Nullifier
rv32i_mux32 inst18(32'b0, next_ins, nopinsertn, ins);


////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// IF/ID pipeline registers ///////////////////////
////////////////////////////////////////////////////////////////////////////////////
wire [31:0] pcplus4id, pcid;
//13-14. pcPlus4_IF_ID relay, pc_IF_ID relay
rv32i_dff32bit inst79(clk, rst, pcplus4, stalln, 1'b0, pcplus4id);
rv32i_dff32bit inst80(clk, rst, pc, stalln, 1'b0, pcid);

///////////////////////////////////////////////////////////////////////////////////
/////////////////////////// ID stage //////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////   

wire jumpregwrite, memwrite, memenable, regwrite, memtoreg;
wire [5:0] aluop;
wire [3:0] alusrc1, alusrc2;
//15. main control unit
rv32i_control inst21(ins, jal, jalr, jumpregwrite, aluop, alusrc1, alusrc2, branch, 
memwrite, memenable, regwrite, memtoreg);


wire [31:0] br_addr_id;
//16. branch address calculator
rv32i_brAddrCalc inst71(ins, pcid, br_addr_id);


wire [31:0] ins_wb; //instruction relayed into the WB stage
wire regwrite_wb; //register write signal relayed into the WB stage
wire [31:0] writedata; //data to be written into a register, prepared in the WB stage
wire [31:0] regdata1, regdata2; //original outputs from the register file
//general-purppose registers, reset by rst
reg [31:0] genregs [31:0];
wire[31:0] gpr_zero, gpr_ra, gpr_sp, gpr_gp, gpr_tp, gpr_t0, gpr_t1, gpr_t2, gpr_s0, gpr_s1;
wire[31:0] gpr_a0, gpr_a1, gpr_a2, gpr_a3, gpr_a4, gpr_a5, gpr_a6, gpr_a7, gpr_s2, gpr_s3;
wire[31:0] gpr_s4, gpr_s5, gpr_s6, gpr_s7, gpr_s8, gpr_s9, gpr_s10, gpr_s11, gpr_t3, gpr_t4, gpr_t5, gpr_t6;
//17. register file 
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
//in case debugging needs to use naming convention to track register values
assign gpr_zero = genregs[X0];
assign gpr_ra = genregs[X1];
assign gpr_sp = genregs[X2];
assign gpr_gp = genregs[X3];
assign gpr_tp = genregs[X4];
assign gpr_t0 = genregs[X5];
assign gpr_t1 = genregs[X6];
assign gpr_t2 = genregs[X7];
assign gpr_s0 = genregs[X8];
assign gpr_s1 = genregs[X9];
assign gpr_a0 = genregs[X10];
assign gpr_a1 = genregs[X11];
assign gpr_a2 = genregs[X12];
assign gpr_a3 = genregs[X13];
assign gpr_a4 = genregs[X14];
assign gpr_a5 = genregs[X15];
assign gpr_a6 = genregs[X16];
assign gpr_a7 = genregs[X17];
assign gpr_s2 = genregs[X18];
assign gpr_s3 = genregs[X19];
assign gpr_s4 = genregs[X20];
assign gpr_s5 = genregs[X21];
assign gpr_s6 = genregs[X22];
assign gpr_s7 = genregs[X23];
assign gpr_s8 = genregs[X24];
assign gpr_s9 = genregs[X25];
assign gpr_s10 = genregs[X26];
assign gpr_s11 = genregs[X27];
assign gpr_t3 = genregs[X28];
assign gpr_t4 = genregs[X29];
assign gpr_t5 = genregs[X30];
assign gpr_t6 = genregs[X31];
//The two read ports are not controlled by the clock input to the register file
//If required, the two outputs can only be buffered by external dffs
assign regdata1 = genregs[ins[19:15]];
assign regdata2 = genregs[ins[24:20]];
always @(posedge rst, posedge clk)
begin
	if(rst==1)
	begin
		genregs[X0]<=0; //always be zero
		genregs[X1]<=0;
		genregs[X2]<=0;
		genregs[X3]<=0;
		genregs[X4]<=0;
		genregs[X5]<=0;
		genregs[X6]<=0;
		genregs[X7]<=0;
		genregs[X8]<=0;
		genregs[X9]<=0;
		genregs[X10]<=0;
		genregs[X11]<=0;
		genregs[X12]<=0;
		genregs[X13]<=0;
		genregs[X14]<=0;
		genregs[X15]<=0;
		genregs[X16]<=0;
		genregs[X17]<=0;
		genregs[X18]<=0;
		genregs[X19]<=0;
		genregs[X20]<=0;
		genregs[X21]<=0;
		genregs[X22]<=0;
		genregs[X23]<=0;
		genregs[X24]<=0;
		genregs[X25]<=0;
		genregs[X26]<=0;
		genregs[X27]<=0;
		genregs[X28]<=0;
		genregs[X29]<=0;
		genregs[X30]<=0;
		genregs[X31]<=0;
	end
	else
	begin
		if(regwrite_wb==1) //WB stage write
		begin
			if(ins_wb[11:7]!=5'b00000) //no effect if writing to X0
			genregs[ins_wb[11:7]] <= writedata;
		end
		if(jumpregwrite==1) //ID stage: jal and jalr write
		begin
			if(ins[11:7]!=5'b00000) //no effect if writing to X0
			genregs[ins[11:7]] <= pcplus4id;  	
		end
	end
end

wire[31:0] data1, data2;
//18. ALU input setter
rv32i_dataSel inst35(ins, regdata1, regdata2, pcid, alusrc1, alusrc2, data1, data2);

wire[31:0] ins_ex, ins_mem;
wire stall;
wire[1:0] jalr_forward;
//19. stall signal generator
rv32i_stall inst69(ins[19:15], ins[24:20], ins_ex[11:7], ins_mem[11:7], ins_wb[11:7], ins[6:0], 
ins_ex[6:0], ins_mem[6:0], ins_wb[6:0], stall, stalln, jalr_forward);

wire[31:0] regdata1_jalr;
//20. jump base setter
rv32i_mux32bit4ch inst63(regdata1, res_mem, writedata, regdata1, jalr_forward, regdata1_jalr);

//21. jump target address calculator
rv32i_jAddrCalc inst39(pcid, ins, regdata1_jalr, jal_addr, jalr_addr);


//////////////////////////////////////////////////////////////////
///////////////////// ID/EX Pipeline Registers ///////////////////
//////////////////////////////////////////////////////////////////

wire memwrite_ex, memenable_ex, regwrite_ex, memtoreg_ex;
wire[5:0] aluop_ex;
wire[31:0] data1_ex, data2_ex, regdata2_ex, pcid_ex;
//22-27. 32bit buffers
rv32i_dff32bit inst84(clk, rst, br_addr_id, 1'b1, stall, br_addr);
rv32i_dff32bit inst93(clk, rst, data1, 1'b1, stall, data1_ex);
rv32i_dff32bit inst94(clk, rst, data2, 1'b1, stall, data2_ex);
rv32i_dff32bit inst95(clk, rst, ins, 1'b1, stall, ins_ex);
rv32i_dff32bit inst96(clk, rst, regdata2, 1'b1, stall, regdata2_ex);
rv32i_dff32bit inst5(clk, rst, pcid, 1'b1, stall, pcid_ex);
//28-32. 1bit buffers 
rv32i_dff1bit inst86(clk, rst, branch, 1'b1, stall, branch_ex);
rv32i_dff1bit inst87(clk, rst, memwrite, 1'b1, stall, memwrite_ex);
rv32i_dff1bit inst88(clk, rst, memenable, 1'b1, stall, memenable_ex);
rv32i_dff1bit inst89(clk, rst, regwrite, 1'b1, stall, regwrite_ex);
rv32i_dff1bit inst90(clk, rst, memtoreg, 1'b1, stall, memtoreg_ex);
//33. 6bit buffers
rv32i_dff6bit inst92(clk, rst, aluop, 1'b1, stall, aluop_ex);



///////////////////////////////////////////////
//////////////////// EX stage //////////////////
///////////////////////////////////////////////

wire taken;
//34. branch signal gate
assign br = branch_ex & taken; //inst41, and2

wire[31:0] alu_a, alu_b, res;
//35. Arithmetic Logic Unit (ALU)
rv32i_ALU inst12(alu_a, alu_b, aluop_ex, res, taken);

wire[31:0] ins_buffer;
wire regwrite_mem, regwrite_buffer;
wire[1:0] sel_a, sel_b, sel_c;
//36. forwarding selector
rv32i_forwarding inst60(ins_ex[19:15], ins_ex[24:20], ins_mem[11:7], ins_wb[11:7], ins_buffer[11:7], regwrite_mem, regwrite_wb, 
regwrite_buffer, ins_ex[6:0], ins_mem[6:0], ins_wb[6:0], ins_buffer[6:0], sel_a, sel_b, sel_c);

wire[31:0] writedata_buffer;
//37. ALU Source A
rv32i_mux32bit4ch inst57(data1_ex, res_mem, writedata, writedata_buffer, sel_a, alu_a);

//38. ALU Source B
rv32i_mux32bit4ch inst58(data2_ex, res_mem, writedata, writedata_buffer, sel_b, alu_b);


wire[31:0] store_source;
//39. Store Source
rv32i_mux32bit4ch inst59(regdata2_ex, res_mem, writedata, writedata_buffer, sel_c, store_source);



/////////////////////////////////////////////////////////////////
//////////////////// EX/MEM pipeline registers //////////////////
/////////////////////////////////////////////////////////////////

wire memtoreg_mem, memwrite_mem, memenable_mem;
wire[31:0] savedata_mem, pcid_mem, alu_a_mem, alu_b_mem; 
//40-43. 1bit buffers  
dff1bit inst51(clk, rst, regwrite_ex, regwrite_mem);
dff1bit inst54(clk, rst, memtoreg_ex, memtoreg_mem);
dff1bit inst43(clk, rst, memwrite_ex, memwrite_mem);
dff1bit inst44(clk, rst, memenable_ex, memenable_mem);
//44-49. 32bit buffers
dff32bit inst42(clk, rst, res, res_mem);
dff32bit inst47(clk, rst, store_source, savedata_mem);
dff32bit inst49(clk, rst, ins_ex, ins_mem);
dff32bit inst16(clk, rst, pcid_ex, pcid_mem);
dff32bit inst22(clk, rst, alu_a, alu_a_mem);
dff32bit inst25(clk, rst, alu_b, alu_b_mem);
 


/////////////////////////////////////////////////////////////////////
//////////////////////// MEM stage //////////////////////////////////
/////////////////////////////////////////////////////////////////////

wire[31:0] savedata;
wire[3:0] we4k, we2k;
//50. Data RAM Store Controller
rv32i_ramWriteControl inst17(memwrite_mem, ins_mem[14:12], res_mem, savedata_mem, we4k, we2k, savedata);

reg[31:0] dram4k;
//51-54. 4KW Data RAM - Built-in

//parameter awidth4 = 12;
parameter dwidth4 = 8;
reg [dwidth4-1:0] dmem4KB_byte3 [2**awidth4-1:0];
reg [dwidth4-1:0] dmem4KB_byte2 [2**awidth4-1:0];
reg [dwidth4-1:0] dmem4KB_byte1 [2**awidth4-1:0];
reg [dwidth4-1:0] dmem4KB_byte0 [2**awidth4-1:0];



always @(posedge clk)
begin
		if(we4k[3])
		begin
			dmem4KB_byte3[res_mem[13:2]] <= savedata[31:24];
			dram4k[31:24] <= savedata[31:24];
		end
		else
		begin
			dram4k[31:24] <= dmem4KB_byte3[res_mem[13:2]];
		end
		
		if(we4k[2])
		begin
			dmem4KB_byte2[res_mem[13:2]] <= savedata[23:16];
			dram4k[23:16] <= savedata[23:16];
		end
		else
		begin
			dram4k[23:16] <= dmem4KB_byte2[res_mem[13:2]];
		end
		
		if(we4k[1])
		begin
			dmem4KB_byte1[res_mem[13:2]] <= savedata[15:8];
			dram4k[15:8] <= savedata[15:8];
		end
		else
		begin
			dram4k[15:8] <= dmem4KB_byte1[res_mem[13:2]];
		end
		
		if(we4k[0])
		begin
			dmem4KB_byte0[res_mem[13:2]] <= savedata[7:0];
			dram4k[7:0] <= savedata[7:0];
		end
		else
		begin
			dram4k[7:0] <= dmem4KB_byte0[res_mem[13:2]];
		end
end

////////////////////////////

reg[31:0] dram2k;
//55-58. 2KW Data RAM - built-in

parameter dwidth2 = 8;
reg [dwidth2-1:0] dmem2KB_byte3 [2**awidth2-1:0];
reg [dwidth2-1:0] dmem2KB_byte2 [2**awidth2-1:0];
reg [dwidth2-1:0] dmem2KB_byte1 [2**awidth2-1:0];
reg [dwidth2-1:0] dmem2KB_byte0 [2**awidth2-1:0];

always @(posedge clk)
begin
		if(we2k[3])
		begin
			dmem2KB_byte3[res_mem[12:2]] <= savedata[31:24];
			dram2k[31:24] <= savedata[31:24];
		end
		else
		begin
			dram2k[31:24] <= dmem2KB_byte3[res_mem[12:2]];
		end
		
		if(we2k[2])
		begin
			dmem2KB_byte2[res_mem[12:2]] <= savedata[23:16];
			dram2k[23:16] <= savedata[23:16];
		end
		else
		begin
			dram2k[23:16] <= dmem2KB_byte2[res_mem[12:2]];
		end
		
		if(we2k[1])
		begin
			dmem2KB_byte1[res_mem[12:2]] <= savedata[15:8];
			dram2k[15:8] <= savedata[15:8];
		end
		else
		begin
			dram2k[15:8] <= dmem2KB_byte1[res_mem[12:2]];
		end
		
		if(we2k[0])
		begin
			dmem2KB_byte0[res_mem[12:2]] <= savedata[7:0];
			dram2k[7:0] <= savedata[7:0];
		end
		else
		begin
			dram2k[7:0] <= dmem2KB_byte0[res_mem[12:2]];
		end
end
////////////////////////////

//mirror memory here for debugging purpose
//show the contents of all memory
//map the 8KW imem, 4KW dmem and 2KW dmem to a unified memory space for convenience of debugging
reg [dwidth-1:0] mirror_mem [2**awidth_mirror-1:0]; //note: awidth_mirror is twice as large as the instruction memory
integer ix, iy, iz;

always @(posedge clk)
begin
  for(ix=0; ix<2**awidth; ix=ix+1)
  begin
    mirror_mem[ix] <= imem[ix];
  end
  for(iy=0; iy<2**awidth4; iy=iy+1)//the 4KW dmem is on the top of the 8KW imem in the unified address space
  begin
    mirror_mem[2**awidth+iy] <= {dmem4KB_byte3[iy], dmem4KB_byte2[iy], dmem4KB_byte1[iy], dmem4KB_byte0[iy]};
  end
  for(iz=0; iz<2**awidth2; iz=iz+1)//the 2KW dmem is on the top of the 4KW dmem in the unified address space
  begin
    mirror_mem[2**awidth+2**awidth4+iz] <= {dmem2KB_byte3[iz], dmem2KB_byte2[iz], dmem2KB_byte1[iz], dmem2KB_byte0[iz]};
  end
end

////////////////////////////////////////////////////////////////////////////
///////////////////////// MEM/WB pipeline registers ////////////////////////
////////////////////////////////////////////////////////////////////////////

wire memtoreg_wb, memenable_wb;
wire[31:0] pc_wb, opa_wb, opb_wb, res_wb, savedata_wb;
//59-61. 1bit buffers
dff1bit inst52(clk, rst, regwrite_mem, regwrite_wb);
dff1bit inst53(clk, rst, memtoreg_mem, memtoreg_wb);
dff1bit inst38(clk, rst, memenable_mem, memenable_wb);
//62-67. 32bit buffers
dff32bit inst29(clk, rst, pcid_mem, pc_wb);
dff32bit inst32(clk, rst, alu_a_mem, opa_wb);
dff32bit inst36(clk, rst, alu_b_mem, opb_wb);
dff32bit inst10(clk, rst, res_mem, res_wb);
dff32bit inst50(clk, rst, ins_mem, ins_wb);
dff32bit inst37(clk, rst, savedata_mem, savedata_wb);


////////////////////////////////////////////////////////////////////////////
///////////////////////////// WB stage /////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

wire[31:0] memdatawb;
//68. mem reg selector
rv32i_mux32 inst55(res_wb, memdatawb, memtoreg_wb, writedata);

//69. data memory selector and width setter (for loading)  
rv32i_ramSel inst(iromdata, dram4k, dram2k, res_wb, ins_wb[14:12], memdatawb);

wire[31:0] mem_addr, mem_write_data;
//70. Mem Operation Displayer
rv32i_meminfo_display inst45(memtoreg_wb, memenable_wb, res_wb, savedata_wb, mem_addr, mem_write_data);

///////////////////////////////////////////////////////////////////////////
///////////////////////// WB/ID pipeline registers/////////////////////////
///////////////////////////////////////////////////////////////////////////

//71. 1bit buffer
dff1bit inst27(clk, rst, regwrite_wb, regwrite_buffer);

//72-73. 32bit buffers
dff32bit inst26(clk, rst, writedata, writedata_buffer);
dff32bit inst46(clk, rst, ins_wb, ins_buffer);

wire[31:0] debug_pc, debug_res, debug_ins, debug_opa, debug_opb, debug_mem_addr, debug_mem_write_data; 
//74-80. 32bit buffers (for debugging convenience)
dff32bit inst200(clk, rst, pc_wb, debug_pc);
dff32bit inst201(clk, rst, writedata, debug_res);
dff32bit inst202(clk, rst, ins_wb, debug_ins);
dff32bit inst203(clk, rst, opa_wb, debug_opa);
dff32bit inst204(clk, rst, opb_wb, debug_opb);
dff32bit inst205(clk, rst, mem_addr, debug_mem_addr);
dff32bit inst206(clk, rst, mem_write_data, debug_mem_write_data);
 

//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////// Simulation Code /////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////



initial
begin
  clk = 0;
end

always
begin
  #10 clk = ~clk;
end

initial
begin
  rst = 1;
  #40 rst = 0;
end

initial
begin
  $monitor("time %t, instruction %h, result %h", $time, ins_wb, writedata); 
end
  
  
endmodule
