module rv32i_mmu(mmu_en, mmu_we, mmu_addr, mmu_din, mmu_dout, rst, clk_in, addr, bs, dq, cs_, ras_, cas_, we_, 
ldqm, udqm, cke);
//interface with rv32i
input mmu_en, mmu_we;
input [31:0] mmu_addr, mmu_din;
output reg[31:0] mmu_dout;
//operational signals
input rst, clk_in;
//interface with dram
output reg[12:0] addr;
output reg[1:0] bs;
inout [15:0] dq;
//output reg clk_out; //need to handle this clk signal carefully .......................
output reg cs_, ras_, cas_, we_, ldqm, udqm, cke;

//mmu internal regs
reg[31:0] status_reg;
reg[12:0] addr_reg;
reg[1:0] bs_reg;
reg[15:0] dq_outbuf;
//A control register that sets all 1-bit  
reg[7:0] ctrl_reg;
//bit name of the ctrl_reg
localparam bit_cs_ = 0;  //default 1
localparam bit_ras_ = 1; //default 1
localparam bit_cas_ = 2; //default 1
localparam bit_we_ = 3;  //default 1
localparam bit_ldqm = 4; //default 0
localparam bit_udqm = 5; //default 0
localparam bit_cke = 6;  //default 0
localparam bit_dqInMode = 7; //default 0 

//The inout port must be set into hi-z when it is in read (input) mode
assign dq = (ctrl_reg[bit_dqInMode]==1)?16'bz:dq_outbuf;

always @(addr_reg)
begin
	addr<=addr_reg;
end

always @(bs_reg)
begin
	bs<=bs_reg;
end

always @(ctrl_reg)
begin
	cs_ <= ctrl_reg[bit_cs_];
	ras_ <= ctrl_reg[bit_ras_];
	cas_ <= ctrl_reg[bit_cas_];
	we_ <= ctrl_reg[bit_we_];
	ldqm <= ctrl_reg[bit_ldqm];
	udqm <= ctrl_reg[bit_udqm];
	cke <= ctrl_reg[bit_cke];
end

always @(posedge clk_in, posedge rst)
begin
	if(rst==1)
	begin
		addr_reg <= 13'b0;
		bs_reg <= 2'b0;
		dq_outbuf <= 16'b0;
		ctrl_reg <= 8'b00001111; 
		mmu_dout <= 32'bz;
	end
	else
	begin
		if(mmu_addr[31:16]==16'hE002 && mmu_en==1)
		begin
			if(mmu_we==0)//read mmu internal registers
			begin
				case(mmu_addr[15:0])
				16'h0000: mmu_dout <= {24'b0, ctrl_reg};
				16'h0004: mmu_dout <= {16'b0, dq}; //only works when bit7 of ctrl_reg is set 1
				16'h0008: mmu_dout <= {19'b0, addr_reg};
				16'h000C: mmu_dout <= {30'b0, bs_reg};
				16'h0010: mmu_dout <= status_reg;
				default: mmu_dout <= 32'bz;
				endcase
			end
			else //write mmu internal registers
			begin
				mmu_dout <= 32'bz;
				case(mmu_addr[15:0])
				16'h0000: ctrl_reg <= mmu_din[7:0];
				16'h0004: dq_outbuf <= mmu_din[15:0]; //only works when bit7 of ctrl_reg is set 0
				16'h0008: addr_reg <= mmu_din[12:0];
				16'h000C: bs_reg <= mmu_din[1:0];
				endcase
			end
		end
		else mmu_dout <= 32'bz;
	end
end

endmodule