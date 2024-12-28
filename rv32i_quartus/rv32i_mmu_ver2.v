module rv32i_mmu_ver2(mmu_en, mmu_we, mmu_addr, mmu_din, mmu_dout, rst, clk_in, addr, bs, dq, cs_, ras_, cas_, we_, 
ldqm, udqm, cke, clk_out, state_out, ar_out, cntSample);
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
output clk_out; //watch out for this output clock signal that drives the DRAM chip
output [4:0] state_out;
output [3:0] ar_out;
output [5:0] cntSample;

//mmu internal regs
reg[31:0] status_reg;
//reg[12:0] addr_reg;
//reg[1:0] bs_reg;
//reg[15:0] dq_outbuf;
//A control register that sets all 1-bit  
//reg[7:0] ctrl_reg;
//bit name of the ctrl_reg
localparam bit_cs_ = 0;  //default 1
localparam bit_ras_ = 1; //default 1
localparam bit_cas_ = 2; //default 1
localparam bit_we_ = 3;  //default 1
localparam bit_ldqm = 4; //default 0
localparam bit_udqm = 5; //default 0
localparam bit_cke = 6;  //default 0
localparam bit_dqInMode = 7; //default 0 

//state variable of the FSM of the MMU
reg[4:0] state;
reg[4:0] next_state;
assign state_out = state;
//by flipping the original clk_in, the rising edge of the clk_out satisifies the timing requirement of the clk
//supplied to DRAM chip
assign clk_out = ~clk_in; //watch out!---------------------------------

reg dqInEn;

reg[15:0] dq_out;
assign dq = (dqInEn==1)?16'bz:dq_out;

//The inout port must be set into hi-z when it is in read (input) mode
//assign dq = (ctrl_reg[bit_dqInMode]==1)?16'bz:dq_outbuf;
/*
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
*/

reg [15:0] writeBuffer [7:0]; //write is from the point of the cpu
reg [15:0] readBuffer [7:0]; //read is from the point of the cpu
reg [23:0] waddrBuffer [7:0];
reg [23:0] raddrBuffer [7:0];

reg [2:0] wbWPtr, wbRPtr, rbWPtr, rbRPtr; 

//when CPU needs to write data into the DRAM
//1. write the target address to save data
//2. write the data to be saved (wbWPtr will increment)
//3. go on with other missions
//when CPU needs to read data from DRAM
//1. write the target address to read data (rbRPtr will increment)
//2. wait for a little while 
//3. read the data from readBuffer

//this module monitor the actions of the CPU
always @(posedge clk_in, posedge rst)
begin
	if(rst==1)
	begin 
		mmu_dout <= 32'bz;
		wbWPtr <= 0;
		rbRPtr <= 0;
	end
	else
	begin
		if(mmu_addr[31:16]==16'hE002 && mmu_en==1)
		begin
			if(mmu_we==0)//read mmu internal registers
			begin
				wbWPtr <= wbWPtr;
				rbRPtr <= rbRPtr;
				case(mmu_addr[15:0])
				16'h0008: mmu_dout <= {16'b0, readBuffer[rbRPtr-1]};
				16'h000C: mmu_dout <= {27'b0, state}; //allow cpu to check the state of the MMU FSM for debugging
				16'h0010: mmu_dout <= {10'b0, rtimer}; //allow cpu to check if it is a good timing to do any r/w
				16'h0014: mmu_dout <= {5'b0, wbWPtr, 5'b0, wbRPtr, 5'b0, rbWPtr, 5'b0, rbRPtr};
				default: mmu_dout <= 32'bz;
				endcase
			end
			else //write mmu internal registers
			begin
				mmu_dout <= 32'bz;
				case(mmu_addr[15:0])
				16'h0000: 
				begin
					writeBuffer[wbWPtr] <= mmu_din[15:0];
					wbWPtr <= wbWPtr + 1;
					rbRPtr <= rbRPtr;
				end
				16'h0004:
				begin
					waddrBuffer[wbWPtr] <= mmu_din[23:0];
					wbWPtr <= wbWPtr;
					rbRPtr <= rbRPtr;
				end
				16'h0008:
				begin
					raddrBuffer[rbRPtr] <= mmu_din[23:0];
					wbWPtr <= wbWPtr;
					rbRPtr <= rbRPtr + 1;
				end
				endcase
			end
		end
		else
		begin
			mmu_dout <= 32'bz;
			wbWPtr <= wbWPtr;
			rbRPtr <= rbRPtr;
		end
	end
end

always @(posedge clk_in, posedge rst)
begin
	if(rst) state<=0;
	else state<=next_state;
end

reg[31:0] counter;
reg counterEnable;

reg rst2;

assign cntSample = counter[5:0];


always @(posedge clk_in, posedge rst, posedge rst2)
begin
	if(rst) counter <= 0;
	else if(rst2) counter <= 0;
	else
		if(counterEnable) counter<=counter+1;
		else counter<=counter;
end

/*
always @(posedge clk_in, posedge rst, posedge rst2)
begin
	if(rst) counter <= 0;
	else if(clk_in)
		if(rst2) counter<=0;
		else if(counterEnable) counter<=counter+1;
		else counter<=counter;
	else counter <= counter;
end
*/

reg [3:0] ar_cnt;
reg inc;

assign ar_out = ar_cnt;

always @(posedge rst, posedge inc)
begin
	if(rst) ar_cnt<=0;
	else ar_cnt<=ar_cnt+1;
end

reg [13:0] rf_cnt;
reg rf_inc, rf_reset;

always @(posedge rst, posedge clk_in)
begin
	if(rst) rf_cnt<=0;
	else if(clk_in)
	begin
	   if(rf_reset) rf_cnt <= 0;
		else if(rf_inc) rf_cnt <= rf_cnt + 1;
		else rf_cnt <= rf_cnt;
	end
	else rf_cnt <= rf_cnt;
end


reg wbRPtrUpdate;
reg rbWPtrUpdate;
reg rbWEn;


//timer to refresh the DRAM
//period to refresh according to DRAM manual: 64ms = 3200000 cycles of 20ns 
reg [21:0] rtimer;
reg rtEnable, rtReset;
always @(posedge rst, posedge clk_in)
begin
	if(rst) rtimer<=0;
	else if(clk_in)
	begin
		if(rtReset) rtimer <= 0;
		else if(rtEnable)
		begin
			if(rtimer<3199900) rtimer <= rtimer + 1;
			else rtimer <= 0;
		end
		else rtimer <= rtimer;
	end
	else rtimer <= rtimer;
end

always @(state)
begin
	case(state)
	5'b00000:  //initialization starts here
	begin
		next_state <= 5'b00001;
		counterEnable <= 1;
		rst2 <= 0;
		cs_ <= 1; 
		ras_ <= 1; 
		cas_ <= 1; 
		we_ <= 1; 
		ldqm <= 1; 
		udqm <= 1; 
		cke <= 1;
		dqInEn <= 0;
		addr <= 0;
		bs <= 0;
		dq_out <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00001: //state to wait for power to be stable
	begin
		cs_ <= 1; 
		ras_ <= 1; 
		cas_ <= 1; 
		we_ <= 1; 
		ldqm <= 1; 
		udqm <= 1; 
		dqInEn <= 0;
		addr <= 0;
		bs <= 0;
		dq_out <= 0;
		if(counter<50000000) //roughly waiting for 1 second
		begin
			next_state <= 5'b00001;
			counterEnable <= 1;
			cke <= 1;
		end
		else if(counter <50000002)
		begin
			next_state <= 5'b00001;
			counterEnable <= 1;
			cke <= 1;
		end
		else
		begin
			next_state <= 5'b00010;
			counterEnable <= 0;
			cke <= 1;
		end
		rst2 <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00010: //precharge all
	begin
		cs_ <= 0; 
		ras_ <= 0; 
		cas_ <= 1; 
		we_ <= 0; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 0;
		next_state <= 5'b00011;
		counterEnable <= 1; //start counting for the delay after precharge
		rst2 <= 1; 
		addr <= 1024;
		bs <= 0;
		dq_out <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00011:
	begin
		if(counter < 3) //still in precharge-all delay
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00011;
			counterEnable <= 1; //keep counting for the delay after precharge
			rst2 <= 0; 
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;	
		end
		else //mode register set
		begin
			cs_ <= 0; 
			ras_ <= 0; 
			cas_ <= 0; 
			we_ <= 0; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00100;
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 13'b0000000110000;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
		end
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00100: //mode register set delay starts
	begin
		cs_ <= 1; 
		ras_ <= 1; 
		cas_ <= 1; 
		we_ <= 1; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 0;
		next_state <= 5'b00101;
		counterEnable <= 1;
		rst2 <= 1;
		addr <= 0;
		bs <= 0;
		dq_out <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00101:
	begin
		if(counter<3) //still in mode register set delay
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00101;
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
		end
		else //start 8 auto-refresh cycles
		begin 
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00110;
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;			
		end
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00110:
	begin
		if(ar_cnt<8)
		begin
			cs_ <= 0; 
			ras_ <= 0; 
			cas_ <= 0; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00111;
			counterEnable <= 1;
			rst2 <= 1;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;				
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01000; //initialization is done, ready for normal operation
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;			
		end
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b00111:
	begin
		if(counter<3)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00111;
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 1;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b00110;
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
		end
      wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 0;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	
	/////////////////////////////////////////
	/////////////////////////////////////////
	/////////////////////////////////////////
	/* normal operation loop */
	5'b01000:  //normal operation starts here
	begin
		if(rtimer > 3100000) //time to refresh
		begin
			cs_ <= 0; 
			ras_ <= 0; 
			cas_ <= 1; 
			we_ <= 0; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10100; //go to precharge - all waiting
			counterEnable <= 1;
			rst2 <= 1;
			addr <= 1024;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
			rf_reset <= 1;
			rtReset <= 0;
		end
		else if((wbRPtr==wbWPtr)&&(rbRPtr==rbWPtr)) //if no CPU request for data (write/read)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01000; //stay on the same state
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else if(wbRPtr!=wbWPtr) //CPU has sent a data item to write to the DRAM
		begin
			cs_ <= 0; 
			ras_ <= 0; 
			cas_ <= 1; 
			we_ <= 0; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01001; //go to precharge waiting
			counterEnable <= 1;
			rst2 <= 1;
			addr <= 0;
			bs <= waddrBuffer[wbRPtr][23:22]; //highest two bits of the buffered address are bank selection
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else //CPU has sent a read request
		begin
			cs_ <= 0; 
			ras_ <= 0; 
			cas_ <= 1; 
			we_ <= 0; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01110; //go to precharge waiting
			counterEnable <= 1;
			rst2 <= 1;
			addr <= 0;
			bs <= raddrBuffer[rbWPtr][23:22]; //highest two bits of the buffered address are bank selection
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	
	/////////////////////////////////
	/////////////////////////////////
	/////////////////////////////////
	/*write request handling states*/
	5'b01001:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01001; //stay on precharge waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01010; //go to activate
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	5'b01010:
	begin
		cs_ <= 0; 
		ras_ <= 0; 
		cas_ <= 1; 
		we_ <= 1; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 0;
		next_state <= 5'b01011; //go to activate waiting
		counterEnable <= 1;
		rst2 <= 1;
		addr <= waddrBuffer[wbRPtr][21:9]; //row address extracted from write address buffer
		bs <= waddrBuffer[wbRPtr][23:22]; //bank address extracted from write address buffer
		dq_out <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 1;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b01011:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01011; //stay on activate waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01100; //go to write
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	5'b01100:
	begin
		cs_ <= 0; 
		ras_ <= 1; 
		cas_ <= 0; 
		we_ <= 0; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 0;
		next_state <= 5'b01101; //go to write waiting
		counterEnable <= 1;
		rst2 <= 1;
		addr <= {4'b0000, waddrBuffer[wbRPtr][8:0]}; //column address extracted from write address buffer
		bs <= waddrBuffer[wbRPtr][23:22]; //bank address extracted from write address buffer
		dq_out <= writeBuffer[wbRPtr];
		inc <= 0;
		wbRPtrUpdate <= 1;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 1;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b01101:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01101; //stay on write waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01000; //go back to normal
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end

	//////////////////////////////////
	//////////////////////////////////
	//////////////////////////////////
	/* read request handling states */
	5'b01110:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01110; //stay on precharge waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01111; //go to activate
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
	      rbWEn <= 0;
			rtEnable <= 1;
	      rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	5'b01111:
	begin
		cs_ <= 0; 
		ras_ <= 0; 
		cas_ <= 1; 
		we_ <= 1; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 0;
		next_state <= 5'b10000; //go to activate waiting
		counterEnable <= 1;
		rst2 <= 1;
		addr <= raddrBuffer[rbWPtr][21:9]; //row address extracted from read address buffer
		bs <= raddrBuffer[rbWPtr][23:22]; //bank address extracted from read address buffer
		dq_out <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
		rbWEn <= 0;
		rtEnable <= 1;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b10000:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10000; //stay on activate waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10001; //go to read
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
	      rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	5'b10001:
	begin
		cs_ <= 0; 
		ras_ <= 1; 
		cas_ <= 0; 
		we_ <= 1; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 1; //must turn on dq input now
		next_state <= 5'b10010; //go to read waiting
		counterEnable <= 1;
		rst2 <= 1;
		addr <= {4'b0000, raddrBuffer[rbWPtr][8:0]}; //column address extracted from read address buffer
		bs <= raddrBuffer[rbWPtr][23:22]; //bank address extracted from write address buffer
		dq_out <= 0; //read command cycle don't care dq bus value
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 0;
      rbWEn <= 0;
		rtEnable <= 1;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	5'b10010:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 1;
			next_state <= 5'b10010; //stay on read waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
	      rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 1;
			next_state <= 5'b10011; //go to finishing the read
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 1;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	5'b10011:
	begin
		cs_ <= 1; 
		ras_ <= 1; 
		cas_ <= 1; 
		we_ <= 1; 
		ldqm <= 0; 
		udqm <= 0; 
		cke <= 1;
		dqInEn <= 1;
		next_state <= 5'b01000; //go back to normal
		counterEnable <= 0;
		rst2 <= 0;
		addr <= 0;
		bs <= 0;
		dq_out <= 0;
		inc <= 0;
		wbRPtrUpdate <= 0;
		rbWPtrUpdate <= 1;
		rbWEn <= 0;
		rtEnable <= 1;
		rf_inc <= 0;
		rf_reset <= 0;
		rtReset <= 0;
	end
	
	
	/////////////////////////////////////////////
	/////////////////////////////////////////////
	/////////////////////////////////////////////
	//periodic refresh handling states
	5'b10100:
	begin
		if(counter<2)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10100; //stay on precharge waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10101; //go to auto refresh
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
	end
	5'b10101:
	begin
		if(rf_cnt<8192)
		begin
			cs_ <= 0; 
			ras_ <= 0; 
			cas_ <= 0; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10110; //go to auto refresh waiting
			counterEnable <= 1;
			rst2 <= 1;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 1;
			rf_reset <= 0;
		   rtReset <= 0;	
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01000; //go back to normal
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
			rf_reset <= 0;
	      rtReset <= 1; //reset refresh timer to avoid another refresh sequence.		
		end
	end
	5'b10110:
	begin
		if(counter<3)
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10110; //stay on auto refresh waiting
			counterEnable <= 1;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
			rtReset <= 0;
		end
		else
		begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b10101; //go to refresh the next row
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
		   rtReset <= 0;	
		end
	end
	
	/////////////////////////////////////////////////
	/////////////////////////////////////////////////
	/////////////////////////////////////////////////
	/////////////////////////////////////////////////
	default:
	begin
			cs_ <= 1; 
			ras_ <= 1; 
			cas_ <= 1; 
			we_ <= 1; 
			ldqm <= 0; 
			udqm <= 0; 
			cke <= 1;
			dqInEn <= 0;
			next_state <= 5'b01000; //stay on the same state
			counterEnable <= 0;
			rst2 <= 0;
			addr <= 0;
			bs <= 0;
			dq_out <= 0;
			inc <= 0;
			wbRPtrUpdate <= 0;
			rbWPtrUpdate <= 0;
			rbWEn <= 0;
			rtEnable <= 1;
			rf_inc <= 0;
		   rf_reset <= 0;
		   rtReset <= 0;	
	end
	endcase

end


// DRAM write pointer update module
always @(posedge rst, posedge clk_in)
begin
	if(rst)
	begin
		wbRPtr <= 0;
	end
	else
	begin
		if(wbRPtrUpdate) wbRPtr <= wbRPtr + 1;
	end
end

// DRAM read pointer update module
always @(posedge rst, posedge clk_in)
begin
	if(rst)
	begin
		rbWPtr <= 0;
	end
	else
	begin
		if(rbWPtrUpdate) rbWPtr <= rbWPtr + 1;
	end
end

// DRAM read data module
always @(posedge clk_out)
begin
	if(rbWEn) readBuffer[rbWPtr] <= dq;
end

endmodule