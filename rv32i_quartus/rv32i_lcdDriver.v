module rv32i_lcdDriver(clk, rst, addr, dataIn, cs, we, dataOut, lcd_rst, lcd_cs, lcd_cd, lcd_wr, lcd_rd, lcd_data);
input clk, rst;
input [31:0] addr;
input [15:0] dataIn;
input cs, we;
output [31:0] dataOut;
reg lcd_rst, lcd_cs, lcd_cd, lcd_wr, lcd_rd;
output lcd_rst, lcd_cs, lcd_cd, lcd_wr, lcd_rd;
inout [7:0] lcd_data;
reg lcdReadEnable;
reg [7:0] lcdWriteBuf;

reg [31:0] dataOut;
reg [15:0] lcdRegs [15:0]; //16 regs of the lcd driver to interface with the 16bit processor. All the regs are mapped to the processor's memory space. 

// variables for state machines
reg [7:0] currState;
reg [7:0] nextState;
reg resetEnable;
reg syncEnable;
reg beginEnable;
reg fillEnable;

// variables for sub state machines
reg [15:0] status;
reg resetDone;
reg syncDone;
reg beginDone;
reg fillDone;

reg lcdReadEnable_reset, lcdReadEnable_sync, lcdReadEnable_begin, lcdReadEnable_fill;
reg [7:0] lcdWriteBuf_reset, lcdWriteBuf_sync, lcdWriteBuf_begin, lcdWriteBuf_fill;
reg lcd_rst_reset, lcd_cs_reset, lcd_cd_reset, lcd_wr_reset, lcd_rd_reset;
reg lcd_rst_sync, lcd_cs_sync, lcd_cd_sync, lcd_wr_sync, lcd_rd_sync;
reg lcd_rst_begin, lcd_cs_begin, lcd_cd_begin, lcd_wr_begin, lcd_rd_begin;
reg lcd_rst_fill, lcd_cs_fill, lcd_cd_fill, lcd_wr_fill, lcd_rd_fill; 

// set the inout port connecting lcd
assign lcd_data = (lcdReadEnable)?8'bz:lcdWriteBuf; //inout needs to be assigned with tri-state

/* 16 registers for processor to access */
/* mapped to the processor's address space 16'h8000 to 16'h800F */

localparam lcd_cs_cpu = 0;
localparam lcd_cd_cpu = 1;
localparam lcd_wr_cpu = 2;
localparam lcd_rd_cpu = 3;
localparam lcd_rst_cpu = 4;
localparam lcdReadEnable_cpu = 5;
localparam lcdWriteBuf_cpu = 6;

always @(posedge rst, posedge clk)
begin
	if(rst)
	begin
		lcdRegs[lcd_cs_cpu]<=16'h0001; //lcd_cs_cpu signal - LSB
		lcdRegs[lcd_cd_cpu]<=16'h0001; //lcd_cd_cpu signal - LSB  
		lcdRegs[lcd_wr_cpu]<=16'h0001; //lcd_wr_cpu signal - LSB
		lcdRegs[lcd_rd_cpu]<=16'h0001; //lcd_rd_cpu signal - LSB
		lcdRegs[lcd_rst_cpu]<=16'h0001; //lcd_rst_cpu signal - LSB
		lcdRegs[lcdReadEnable_cpu]<=16'h0000; //lcdReadEnable_cpu signal - LSB
		lcdRegs[lcdWriteBuf_cpu]<=16'h0000; //lcdWriteBuf_cpu signal - lower byte
		dataOut <= 32'bz;
	end
	else if(cs)
	begin
		//dataOut <= (addr[15:4]==12'h800)?lcdRegs[addr[3:0]]:16'bz; //read as long as cs is active
		if(we==0) //read operation
		begin
			case(addr)
			32'hE0000000: dataOut <= {16'b0, lcdRegs[lcd_cs_cpu]};
			32'hE0000002: dataOut <= {16'b0,lcdRegs[lcd_cd_cpu]};
			32'hE0000004: dataOut <= {16'b0,lcdRegs[lcd_wr_cpu]};
			32'hE0000006: dataOut <= {16'b0,lcdRegs[lcd_rd_cpu]};
			32'hE0000008: dataOut <= {16'b0,lcdRegs[lcd_rst_cpu]};
			32'hE000000A: dataOut <= {16'b0,lcdRegs[lcdReadEnable_cpu]};
			32'hE000000C: dataOut <= {16'b0,lcdRegs[lcdWriteBuf_cpu]};
			32'hE000000E: dataOut <= {24'b0, currState};
			32'hE0000010: dataOut <= {24'b0, lcd_data}; //warning: if lcdReadEnable_cpu is not set, the reading here is meaningless
			default: dataOut <= 32'bz;
			endcase
		end
		else //write operation
		begin
			dataOut <= 32'bz; 
			case(addr)
			32'hE0000000: lcdRegs[lcd_cs_cpu] <= dataIn;
			32'hE0000002: lcdRegs[lcd_cd_cpu] <= dataIn;
			32'hE0000004: lcdRegs[lcd_wr_cpu] <= dataIn;
			32'hE0000006: lcdRegs[lcd_rd_cpu] <= dataIn;
			32'hE0000008: lcdRegs[lcd_rst_cpu] <= dataIn;
			32'hE000000A: lcdRegs[lcdReadEnable_cpu] <= dataIn;
			32'hE000000C: lcdRegs[lcdWriteBuf_cpu] <= dataIn;
			endcase
		end
	end
	else
	begin
		dataOut <= 32'bz;
	end
end




/* finite state machine based on the primary state of LCD setting up */
localparam state_init  = 8'h00;
localparam state_reset = 8'h01;
localparam state_sync  = 8'h02;
localparam state_begin = 8'h03;
localparam state_fill =  8'h04;
localparam state_finish = 8'h05;

//localparam sbit_initDone = 4'b0000;




always @(currState)
begin
	case(currState)
	state_init:
	begin
		nextState <= state_reset; //requires processor to turn on the display, or set to 1 automatically at reset
		resetEnable <= 1'b0;
		syncEnable <= 1'b0;
		beginEnable <= 1'b0;
		fillEnable <= 1'b0;
		lcd_cs <= 1;
		lcd_cd <= 1;
		lcd_wr <= 1;
		lcd_rd <= 1;
		lcd_rst <= 1;
		lcdReadEnable <= 0;
		lcdWriteBuf <= 8'b0;
	end
	state_reset:
	begin
		nextState <= (resetDone)?state_sync:state_reset;
		resetEnable <= 1'b1; //allowing reset sub-steps to start
		syncEnable <= 1'b0;
		beginEnable <= 1'b0;
		fillEnable <= 1'b0;
		lcd_cs <= lcd_cs_reset;
		lcd_cd <= lcd_cd_reset;
		lcd_wr <= lcd_wr_reset;
		lcd_rd <= lcd_rd_reset;
		lcd_rst <= lcd_rst_reset;
		lcdReadEnable <= lcdReadEnable_reset;
		lcdWriteBuf <= lcdWriteBuf_reset;
	end
	state_sync:
	begin
		nextState <= (syncDone)?state_begin:state_sync;
		resetEnable <= 1'b0; //reset irrelvant now
		syncEnable <= 1'b1; //allowing sync sub-steps to start
		beginEnable <= 1'b0;
		fillEnable <= 1'b0;
		lcd_cs <= lcd_cs_sync;
		lcd_cd <= lcd_cd_sync;
		lcd_wr <= lcd_wr_sync;
		lcd_rd <= lcd_rd_sync;
		lcd_rst <= lcd_rst_sync;
		lcdReadEnable <= lcdReadEnable_sync;
		lcdWriteBuf <= lcdWriteBuf_sync;		
	end
	state_begin:
	begin
		nextState <= (beginDone)?state_fill:state_begin; //should jump to state_fill next!
		resetEnable <= 1'b0;
		syncEnable <= 1'b0;
		beginEnable <= 1'b1;
		fillEnable <= 1'b0;
		lcd_cs <= lcd_cs_begin;
		lcd_cd <= lcd_cd_begin;
		lcd_wr <= lcd_wr_begin;
		lcd_rd <= lcd_rd_begin;
		lcd_rst <= lcd_rst_begin;
		lcdReadEnable <= lcdReadEnable_begin;
		lcdWriteBuf <= lcdWriteBuf_begin;		
	end
	state_fill:
	begin
		nextState <= (fillDone)?state_finish:state_fill;
		resetEnable <= 1'b0;
		syncEnable <= 1'b0;
		beginEnable <= 1'b0;
		fillEnable <= 1'b1;
		lcd_cs <= lcd_cs_fill;
		lcd_cd <= lcd_cd_fill;
		lcd_wr <= lcd_wr_fill;
		lcd_rd <= lcd_rd_fill;
		lcd_rst <= lcd_rst_fill;
		lcdReadEnable <= lcdReadEnable_fill;
		lcdWriteBuf <= lcdWriteBuf_fill;		
	end
	state_finish: //CPU configure mode
	begin
		nextState <= state_finish;
		resetEnable <= 1'b0;
		syncEnable <= 1'b0;
		beginEnable <= 1'b0;
		fillEnable <= 1'b0;
		lcd_cs <= lcdRegs[lcd_cs_cpu][0];
		lcd_cd <= lcdRegs[lcd_cd_cpu][0];
		lcd_wr <= lcdRegs[lcd_wr_cpu][0];
		lcd_rd <= lcdRegs[lcd_rd_cpu][0];
		lcd_rst <= lcdRegs[lcd_rst_cpu][0];
		lcdReadEnable <= lcdRegs[lcdReadEnable_cpu][0];
		lcdWriteBuf <= lcdRegs[lcdWriteBuf_cpu][7:0];		
	end	
	endcase
end

always @(posedge rst, posedge clk)
begin
	if(rst) currState <= state_init;
	else currState <= nextState;
end


/* sub finite state machine for lcd reset */ 

// counters and signals
reg [1:0] counter2bit;
reg [18:0] counter18bit;
wire clk12M5;
wire clk25M;
wire delay2msDone;
reg delay2msEnable;

always @(posedge rst, posedge clk)
begin
	if(rst)
	counter2bit <= 2'b0;
	else
	counter2bit <= counter2bit + 1;
end

assign clk12M5 = counter2bit[1]; //define a slower clock for sending data/command to lcd
assign clk25M = counter2bit[0];


always @(posedge rst, posedge delay2msEnable, posedge clk)
begin
	if(rst)
	counter18bit <= 18'b0;
	else if(delay2msEnable)
	counter18bit <= 18'b0;
	else
	counter18bit <= counter18bit + 1;
end

assign delay2msDone = counter18bit[17]; //17


reg[7:0] resetCurrState;
reg[7:0] resetNextState;

localparam reset_prep = 8'h00;
localparam reset_step1 = 8'h01;
localparam reset_step2 = 8'h02;
localparam reset_step3 = 8'h03;
localparam reset_step4 = 8'h04;

//state transitions and signal settings
always @(resetCurrState)
begin
	case(resetCurrState)
	reset_prep:
	begin
		resetNextState <= (resetEnable)?reset_step1:reset_prep;
		lcd_rst_reset <= 1;
		lcd_cs_reset <= 1;
		lcd_cd_reset <= 1;
		lcd_wr_reset <= 1;
		lcd_rd_reset <= 1;
      lcdReadEnable_reset <= 0;		
		delay2msEnable <= 1;
		resetDone <= 0;
	end
	reset_step1:
	begin
		resetNextState <= reset_step2;
		lcd_rst_reset <= 1; //set all LCD control signals high
		lcd_cs_reset <= 1;
		lcd_cd_reset <= 1;
		lcd_wr_reset <= 1;
		lcd_rd_reset <= 1;
		lcdReadEnable_reset <= 0;
		delay2msEnable <= 1;
		resetDone <= 0;
	end
	reset_step2:
	begin
		resetNextState <= reset_step3;
		lcd_rst_reset <= 0;
		lcd_cs_reset <= 1;
		lcd_cd_reset <= 1;
		lcd_wr_reset <= 1;
		lcd_rd_reset <= 1;
	   lcdReadEnable_reset <= 0;	
		delay2msEnable <= 0;
		resetDone <= 0;
	end
	reset_step3:
	begin
		resetNextState <= (delay2msDone)?reset_step4:reset_step3;
		lcd_rst_reset <= 0;
		lcd_cs_reset <= 1;
		lcd_cd_reset <= 1;
		lcd_wr_reset <= 1;
		lcd_rd_reset <= 1;
	   lcdReadEnable_reset <= 0;	
		delay2msEnable <= 0;
		resetDone <= 0;
	end
	reset_step4:
	begin
		resetNextState <= reset_step4;
		lcd_rst_reset <= 1; //reset signal finished
		lcd_cs_reset <= 1;
		lcd_cd_reset <= 1;
		lcd_wr_reset <= 1;
		lcd_rd_reset <= 1;
		lcdReadEnable_reset <= 0;
		delay2msEnable <= 1;
		resetDone <= 1; //enable sync step
	end
	endcase
end

//sequential part
always @(posedge rst, posedge clk12M5)
begin
	if(rst) resetCurrState <= reset_prep;
	else resetCurrState <= resetNextState;
end

/* sub finite state machine for lcd sync */
localparam sync_prep = 8'h00;
localparam sync_step1 = 8'h01;
localparam sync_step2 = 8'h02;
localparam sync_step3 = 8'h03;
localparam sync_step4 = 8'h04;
localparam sync_step5 = 8'h05;
localparam sync_step6 = 8'h06;
localparam sync_step7 = 8'h07;
localparam sync_step8 = 8'h08;
localparam sync_step9 = 8'h09;
localparam sync_step10 = 8'h0a;

reg [7:0] syncCurrState;
reg [7:0] syncNextState;


always @(syncCurrState)
begin
	case(syncCurrState)
	sync_prep:
	begin
		syncNextState <= (syncEnable)?sync_step1:sync_prep;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 1;
		lcd_cd_sync <= 1;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step1:
	begin
		syncNextState <= sync_step2;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step2:
	begin
		syncNextState <= sync_step3;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 0;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step3:
	begin
		syncNextState <= sync_step4;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step4:
	begin
		syncNextState <= sync_step5;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 0;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step5:
	begin
		syncNextState <= sync_step6;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step6:
	begin
		syncNextState <= sync_step7;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 0;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step7:
	begin
		syncNextState <= sync_step8;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step8:
	begin
		syncNextState <= sync_step9;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 0;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step9:
	begin
		syncNextState <= sync_step10;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 0;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 0;
	end
	sync_step10:
	begin
		syncNextState <= sync_step10;
		lcd_rst_sync <= 1;
		lcd_cs_sync <= 1;
		lcd_cd_sync <= 0;
		lcd_wr_sync <= 1;
		lcd_rd_sync <= 1; 
		lcdReadEnable_sync <= 0;
		lcdWriteBuf_sync <= 8'b0;
		syncDone <= 1;
	end
	endcase
end

always @(posedge rst, posedge clk12M5)
begin
	if(rst) syncCurrState <= sync_prep;
	else syncCurrState <= syncNextState;
end

/* sub FSM for lcd begin  */
localparam begin_prep = 8'h00;
localparam begin_step1 = 8'h01;
localparam begin_step2 = 8'h02;
localparam begin_step3 = 8'h03;
localparam begin_step4 = 8'h04;
localparam begin_step5 = 8'h05;
localparam begin_step6 = 8'h06;
localparam begin_step7 = 8'h07;
localparam begin_step8 = 8'h08;
localparam begin_step9 = 8'h09;
localparam begin_step10 = 8'h10;
localparam begin_step11 = 8'h11;
localparam begin_step12 = 8'h12;
localparam begin_step13 = 8'h13;
localparam begin_step14 = 8'h14;
localparam begin_step15 = 8'h15;
localparam begin_step16 = 8'h16;
localparam begin_step17 = 8'h17;
localparam begin_step18 = 8'h18;
localparam begin_step19 = 8'h19;
localparam begin_step20 = 8'h20;
localparam begin_step21 = 8'h21;
localparam begin_step22 = 8'h22;
localparam begin_step23 = 8'h23;
localparam begin_step24 = 8'h24;
localparam begin_step25 = 8'h25;
localparam begin_step26 = 8'h26;
localparam begin_step27 = 8'h27;
localparam begin_step28 = 8'h28;
localparam begin_step29 = 8'h29;
localparam begin_step30 = 8'h30;
localparam begin_step31 = 8'h31;
localparam begin_step32 = 8'h32;
localparam begin_step33 = 8'h33;
localparam begin_step34 = 8'h34;
localparam begin_step35 = 8'h35;
localparam begin_step36 = 8'h36;
localparam begin_step37 = 8'h37;
localparam begin_step38 = 8'h38;
localparam begin_step39 = 8'h39;
localparam begin_step40 = 8'h40;
localparam begin_step41 = 8'h41;
localparam begin_step42 = 8'h42;
localparam begin_step43 = 8'h43;
localparam begin_step44 = 8'h44;
localparam begin_step45 = 8'h45;
localparam begin_step46 = 8'h46;
localparam begin_step47 = 8'h47;
localparam begin_step48 = 8'h48;
localparam begin_step49 = 8'h49;
localparam begin_step50 = 8'h50;
localparam begin_step51 = 8'h51;
localparam begin_step52 = 8'h52;
localparam begin_step53 = 8'h53;
localparam begin_step54 = 8'h54;
localparam begin_step55 = 8'h55;
localparam begin_step56 = 8'h56;
localparam begin_step57 = 8'h57;
localparam begin_step58 = 8'h58;
localparam begin_step59 = 8'h59;
localparam begin_step60 = 8'h60;
localparam begin_step61 = 8'h61;
localparam begin_step62 = 8'h62;
localparam begin_step63 = 8'h63;
localparam begin_step64 = 8'h64;
localparam begin_step65 = 8'h65;
localparam begin_step66 = 8'h66;
localparam begin_step67 = 8'h67;
localparam begin_step68 = 8'h68;
localparam begin_step69 = 8'h69;
localparam begin_step70 = 8'h70;
localparam begin_step71 = 8'h71;
localparam begin_step72 = 8'h72;
localparam begin_step73 = 8'h73;
localparam begin_step74 = 8'h74;
localparam begin_step75 = 8'h75;
localparam begin_step76 = 8'h76;
localparam begin_step77 = 8'h77;
localparam begin_step78 = 8'h78;
localparam begin_step79 = 8'h79;
localparam begin_step80 = 8'h80;
localparam begin_step81 = 8'h81;
localparam begin_step82 = 8'h82;
localparam begin_step83 = 8'h83;
localparam begin_step84 = 8'h84;
localparam begin_step85 = 8'h85;
localparam begin_step86 = 8'h86;
localparam begin_step87 = 8'h87;
localparam begin_step88 = 8'h88;
localparam begin_step89 = 8'h89;

reg [7:0] beginCurrState;
reg [7:0] beginNextState;

//timers
wire delay50msDone;
reg delay50msEnable;

wire delay150msDone;
reg delay150msEnable;

reg [21:0] counter22bit;

reg [23:0] counter24bit;

always @(posedge rst, posedge delay50msEnable, posedge clk)
begin
	if(rst) counter22bit <= 0;
	else if(delay50msEnable) counter22bit <= 0;
	else counter22bit = counter22bit + 1;
end

assign delay50msDone = counter22bit[21]; //21

always @(posedge rst, posedge delay150msEnable, posedge clk)
begin
	if(rst) counter24bit <= 0;
	else if(delay150msEnable) counter24bit <= 0;
	else counter24bit = counter24bit + 1;
end

assign delay150msDone = counter24bit[23]; //23

//register names
localparam ILI9341_SOFTRESET          = 8'h01;
localparam ILI9341_SLEEPIN            = 8'h10;
localparam ILI9341_SLEEPOUT           = 8'h11;
localparam ILI9341_NORMALDISP         = 8'h13;
localparam ILI9341_INVERTOFF          = 8'h20;
localparam ILI9341_INVERTON           = 8'h21;
localparam ILI9341_GAMMASET           = 8'h26;
localparam ILI9341_DISPLAYOFF         = 8'h28;
localparam ILI9341_DISPLAYON          = 8'h29;
localparam ILI9341_COLADDRSET         = 8'h2A;
localparam ILI9341_PAGEADDRSET        = 8'h2B;
localparam ILI9341_MEMORYWRITE        = 8'h2C;
localparam ILI9341_PIXELFORMAT        = 8'h3A;
localparam ILI9341_FRAMECONTROL       = 8'hB1;
localparam ILI9341_DISPLAYFUNC        = 8'hB6;
localparam ILI9341_ENTRYMODE          = 8'hB7;
localparam ILI9341_POWERCONTROL1      = 8'hC0;
localparam ILI9341_POWERCONTROL2      = 8'hC1;
localparam ILI9341_VCOMCONTROL1      = 8'hC5;
localparam ILI9341_VCOMCONTROL2      = 8'hC7;
localparam ILI9341_MEMCONTROL      = 8'h36;
localparam ILI9341_MADCTL  = 8'h36;
localparam ILI9341_MADCTL_MY  = 8'h80;
localparam ILI9341_MADCTL_MX  = 8'h40;
localparam ILI9341_MADCTL_MV  = 8'h20;
localparam ILI9341_MADCTL_ML  = 8'h10;
localparam ILI9341_MADCTL_RGB = 8'h00;
localparam ILI9341_MADCTL_BGR = 8'h08;
localparam ILI9341_MADCTL_MH  = 8'h04;


always @(beginCurrState)
begin
	case(beginCurrState)
	begin_prep:
	begin
		beginNextState <= (beginEnable)?begin_step1:begin_prep;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 1;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'b0;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step1:
	begin
		beginNextState <= begin_step2;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'b0;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step2: //set ILI9341_SOFTRESET to 0x00
	begin
		beginNextState <= begin_step3;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_SOFTRESET;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step3:
	begin
		beginNextState <= begin_step4;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_SOFTRESET;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step4:
	begin
		beginNextState <= begin_step5;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_SOFTRESET;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step5:
	begin
		beginNextState <= begin_step6;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step6:
	begin
		beginNextState <= begin_step7;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step7: 
	begin
		beginNextState <= begin_step8;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 0;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step8:
	begin
		beginNextState <= (delay50msDone)?begin_step9:begin_step8;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 0;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step9: //set ILI9341_DISPLAYOFF to 0x00
	begin
		beginNextState <= begin_step10;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_DISPLAYOFF;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step10:
	begin
		beginNextState <= begin_step11;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_DISPLAYOFF;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step11:
	begin
		beginNextState <= begin_step12;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_DISPLAYOFF;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step12:
	begin
		beginNextState <= begin_step13;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step13:
	begin
		beginNextState <= begin_step14;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step14:
	begin
		beginNextState <= begin_step15;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end	
	begin_step15: //set ILI9341_POWERCONTROL1 to 0x23
	begin
		beginNextState <= begin_step16;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_POWERCONTROL1;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step16:
	begin
		beginNextState <= begin_step17;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_POWERCONTROL1;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step17:
	begin
		beginNextState <= begin_step18;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_POWERCONTROL1;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step18:
	begin
		beginNextState <= begin_step19;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h23;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step19:
	begin
		beginNextState <= begin_step20;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h23;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step20:
	begin
		beginNextState <= begin_step21;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h23;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step21: //set ILI9341_POWERCONTROL2 to 0x10
	begin
		beginNextState <= begin_step22;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_POWERCONTROL2;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step22:
	begin
		beginNextState <= begin_step23;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_POWERCONTROL2;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step23:
	begin
		beginNextState <= begin_step24;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_POWERCONTROL2;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step24:
	begin
		beginNextState <= begin_step25;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h10;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step25:
	begin
		beginNextState <= begin_step26;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h10;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step26:
	begin
		beginNextState <= begin_step27;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h10;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end	
	begin_step27: //16-bit set ILI9341_VCOMCONTROL1 to 0x2b2b, both command and data are 16-bit
	begin
		beginNextState <= begin_step28;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step28:
	begin
		beginNextState <= begin_step29;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step29:
	begin
		beginNextState <= begin_step30;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step30:
	begin
		beginNextState <= begin_step31;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_VCOMCONTROL1;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step31:
	begin
		beginNextState <= begin_step32;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_VCOMCONTROL1;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step32:
	begin
		beginNextState <= begin_step33;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_VCOMCONTROL1;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step33:
	begin
		beginNextState <= begin_step34;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h2b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step34:
	begin
		beginNextState <= begin_step35;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h2b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step35:
	begin
		beginNextState <= begin_step36;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h2b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step36:
	begin
		beginNextState <= begin_step37;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h2b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;				
	end
	begin_step37:
	begin
		beginNextState <= begin_step38;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h2b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step38:
	begin
		beginNextState <= begin_step39;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h2b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step39: //set ILI9341_VCOMCONTROL2 to 0xc0
	begin
		beginNextState <= begin_step40;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_VCOMCONTROL2;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;				
	end
	begin_step40:
	begin
		beginNextState <= begin_step41;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_VCOMCONTROL2;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step41:
	begin
		beginNextState <= begin_step42;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_VCOMCONTROL2;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step42:
	begin
		beginNextState <= begin_step43;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'hc0;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step43:
	begin
		beginNextState <= begin_step44;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'hc0;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step44:
	begin
		beginNextState <= begin_step45;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'hc0;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step45: //set ILI9341_MEMCONTROL to ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR
	begin
		beginNextState <= begin_step46;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_MEMCONTROL;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step46:
	begin
		beginNextState <= begin_step47;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_MEMCONTROL;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step47:
	begin
		beginNextState <= begin_step48;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_MEMCONTROL;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step48:
	begin
		beginNextState <= begin_step49;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step49:
	begin
		beginNextState <= begin_step50;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step50:
	begin
		beginNextState <= begin_step51;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step51: //set ILI9341_PIXELFORMAT to 0x55
	begin
		beginNextState <= begin_step52;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_PIXELFORMAT;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step52:
	begin
		beginNextState <= begin_step53;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_PIXELFORMAT;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step53:
	begin
		beginNextState <= begin_step54;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_PIXELFORMAT;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;
	end
	begin_step54:
	begin
		beginNextState <= begin_step55;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h55;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step55:
	begin
		beginNextState <= begin_step56;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h55;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step56:
	begin
		beginNextState <= begin_step57;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h55;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end	
	begin_step57: //16-bit set ILI9341_FRAMECONTROL to 0x001b, both command and data are 16-bit
	begin
		beginNextState <= begin_step58;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step58:
	begin
		beginNextState <= begin_step59;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step59:
	begin
		beginNextState <= begin_step60;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step60:
	begin
		beginNextState <= begin_step61;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_FRAMECONTROL;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step61:
	begin
		beginNextState <= begin_step62;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_FRAMECONTROL;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step62:
	begin
		beginNextState <= begin_step63;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_FRAMECONTROL;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step63:
	begin
		beginNextState <= begin_step64;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step64:
	begin
		beginNextState <= begin_step65;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step65:
	begin
		beginNextState <= begin_step66;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step66:
	begin
		beginNextState <= begin_step67;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h1b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step67:
	begin
		beginNextState <= begin_step68;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h1b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step68:
	begin
		beginNextState <= begin_step69;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h1b;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step69: //set ILI9341_ENTRYMODE to 0x07
	begin
		beginNextState <= begin_step70;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_ENTRYMODE;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step70:
	begin
		beginNextState <= begin_step71;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_ENTRYMODE;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step71:
	begin
		beginNextState <= begin_step72;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_ENTRYMODE;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step72:
	begin
		beginNextState <= begin_step73;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h07;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step73:
	begin
		beginNextState <= begin_step74;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h07;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step74:
	begin
		beginNextState <= begin_step75;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h07;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step75: //set ILI9341_SLEEPOUT to 0x00
	begin
		beginNextState <= begin_step76;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_SLEEPOUT;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step76:
	begin
		beginNextState <= begin_step77;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_SLEEPOUT;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step77:
	begin
		beginNextState <= begin_step78;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_SLEEPOUT;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step78:
	begin
		beginNextState <= begin_step79;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step79:
	begin
		beginNextState <= begin_step80;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step80: 
	begin
		beginNextState <= begin_step81;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 0;
		beginDone = 0;			
	end
	begin_step81:
	begin
		beginNextState <= (delay150msDone)?begin_step82:begin_step81;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 0;
		beginDone = 0;		
	end
	begin_step82: //set ILI9341_DISPLAYON to 0x00
	begin
		beginNextState <= begin_step83;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_DISPLAYON;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step83:
	begin
		beginNextState <= begin_step84;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_DISPLAYON;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step84:
	begin
		beginNextState <= begin_step85;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 0;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= ILI9341_DISPLAYON;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step85:
	begin
		beginNextState <= begin_step86;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;			
	end
	begin_step86:
	begin
		beginNextState <= begin_step87;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 0;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;		
	end
	begin_step87:
	begin
		beginNextState <= begin_step88;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 0;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 0;	
	end
	begin_step88:
	begin
		beginNextState <= begin_step88;
		lcd_rst_begin <= 1;
		lcd_cs_begin <= 1;
		lcd_cd_begin <= 1;
		lcd_wr_begin <= 1;
		lcd_rd_begin <= 1;
		lcdReadEnable_begin <= 0;
		lcdWriteBuf_begin <= 8'h00;
		delay50msEnable <= 1;
		delay150msEnable <= 1;
		beginDone = 1;			
	end
	endcase
end

always @(posedge rst, posedge clk12M5)
begin
	if(rst) beginCurrState <= begin_prep;
	else beginCurrState <= beginNextState;
end


/* sub FSM for lcd fill - not a required initialization part */
localparam BLACK   = 16'h0000;
localparam BLUE    = 16'h001F;
localparam LIGHT_BLUE = 16'h000F;
localparam RED     = 16'hF800;
localparam GREEN   = 16'h07E0;
localparam CYAN    = 16'h07FF;
localparam MAGENTA = 16'hF81F;
localparam YELLOW  = 16'hFFE0;
localparam WHITE   = 16'hFFFF;

wire [15:0] fillColor;
assign fillColor = BLUE; 

localparam fill_prep = 8'h00;
localparam fill_step1 = 8'h01;
localparam fill_step2 = 8'h02;
localparam fill_step3 = 8'h03;
localparam fill_step4 = 8'h04;
localparam fill_step5 = 8'h05;
localparam fill_step6 = 8'h06;
localparam fill_step7 = 8'h07;
localparam fill_step8 = 8'h08;
localparam fill_step9 = 8'h09;
localparam fill_step10 = 8'h10;
localparam fill_step11 = 8'h11;
localparam fill_step12 = 8'h12;
localparam fill_step13 = 8'h13;
localparam fill_step14 = 8'h14;
localparam fill_step15 = 8'h15;
localparam fill_step16 = 8'h16;
localparam fill_step17 = 8'h17;
localparam fill_step18 = 8'h18;
localparam fill_step19 = 8'h19;
localparam fill_step20 = 8'h20;
localparam fill_step21 = 8'h21;
localparam fill_step22 = 8'h22;
localparam fill_step23 = 8'h23;
localparam fill_step24 = 8'h24;
localparam fill_step25 = 8'h25;
localparam fill_step26 = 8'h26;
localparam fill_step27 = 8'h27;
localparam fill_step28 = 8'h28;
localparam fill_step29 = 8'h29;
localparam fill_step30 = 8'h30;
localparam fill_step31 = 8'h31;
localparam fill_step32 = 8'h32;
localparam fill_step33 = 8'h33;
localparam fill_step34 = 8'h34;
localparam fill_step35 = 8'h35;
localparam fill_step36 = 8'h36;

localparam fill_step15a = 8'h0a;
localparam fill_step15b = 8'h0b;
localparam fill_step15c = 8'h0c;

localparam widthMinus1 = 16'd239;
localparam heightMinus1 = 16'd319;

reg [7:0] fillCurrState, fillNextState;

reg [16:0] counter17bit;

reg writeSignal;
wire writeDone;

always @(posedge rst, posedge writeSignal)
begin
	if(rst) counter17bit <= 0;
	else counter17bit <= counter17bit + 1;
end

assign writeDone = (counter17bit == 76800)?1:0;

always @(fillCurrState)
begin
	case(fillCurrState)
	fill_prep:
	begin
		fillNextState <= (fillEnable)?fill_step1:fill_prep;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 1;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;
	end
	fill_step1:
	begin
		fillNextState <= fill_step2;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step2:
	begin
		fillNextState <= fill_step3;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= ILI9341_COLADDRSET;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step3:
	begin
		fillNextState <= fill_step4;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= ILI9341_COLADDRSET;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step4:
	begin
		fillNextState <= fill_step5;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= ILI9341_COLADDRSET;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step5:
	begin
		fillNextState <= fill_step6;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step6:
	begin
		fillNextState <= fill_step7;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step7:
	begin
		fillNextState <= fill_step8;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step8:
	begin
		fillNextState <= fill_step9;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step9:
	begin
		fillNextState <= fill_step10;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step10:
	begin
		fillNextState <= fill_step11;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= widthMinus1[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step11:
	begin
		fillNextState <= fill_step12;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= widthMinus1[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step12:
	begin
		fillNextState <= fill_step13;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= widthMinus1[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step13:
	begin
		fillNextState <= fill_step14;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= widthMinus1[7:0];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step14:
	begin
		fillNextState <= fill_step15;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= widthMinus1[7:0];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step15:
	begin
		fillNextState <= fill_step15a;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= widthMinus1[7:0];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step15a:
	begin
		fillNextState <= fill_step15b;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= ILI9341_PAGEADDRSET;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step15b:
	begin
		fillNextState <= fill_step15c;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= ILI9341_PAGEADDRSET;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step15c:
	begin
		fillNextState <= fill_step16;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= ILI9341_PAGEADDRSET;
		fillDone = 0;
		writeSignal = 0;		
	end	
	fill_step16:
	begin
		fillNextState <= fill_step17;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step17:
	begin
		fillNextState <= fill_step18;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step18:
	begin
		fillNextState <= fill_step19;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step19:
	begin
		fillNextState <= fill_step20;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step20:
	begin
		fillNextState <= fill_step21;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step21:
	begin
		fillNextState <= fill_step22;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= heightMinus1[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step22:
	begin
		fillNextState <= fill_step23;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= heightMinus1[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step23:
	begin
		fillNextState <= fill_step24;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= heightMinus1[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step24:
	begin
		fillNextState <= fill_step25;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= heightMinus1[7:0];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step25:
	begin
		fillNextState <= fill_step26;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= heightMinus1[7:0];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step26:
	begin
		fillNextState <= fill_step27;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= heightMinus1[7:0];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step27:
	begin
		fillNextState <= fill_step28;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h2c;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step28:
	begin
		fillNextState <= fill_step29;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h2c;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step29:
	begin
		fillNextState <= fill_step30;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 0;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h2c;
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step30:
	begin
		fillNextState <= fill_step31;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= fillColor[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step31:
	begin
		fillNextState <= fill_step32;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= fillColor[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step32:
	begin
		fillNextState <= fill_step33;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= fillColor[15:8];
		fillDone = 0;
		writeSignal = 0;		
	end
	fill_step33:
	begin
		fillNextState <= fill_step34;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= fillColor[7:0];
		fillDone = 0;
		writeSignal = 1;		
	end
	fill_step34:
	begin
		fillNextState <= fill_step35;
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 0;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= fillColor[7:0];
		fillDone = 0;
		writeSignal = 1;		
	end
	fill_step35:
	begin
		fillNextState <= (writeDone)?fill_step36:fill_step30; //creating a loop here, whose loop variable and condition are maintained by an entity outside this FSM
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 0;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= fillColor[7:0];
		fillDone = 0;
		writeSignal = 1;		
	end
	fill_step36:
	begin
		fillNextState <= fill_step36; //creating a loop here, whose loop variable and condition are maintained by an entity outside this FSM
		lcd_rst_fill <= 1;
		lcd_cs_fill <= 1;
		lcd_cd_fill <= 1;
		lcd_wr_fill <= 1;
		lcd_rd_fill <= 1;
		lcdReadEnable_fill <= 0;
		lcdWriteBuf_fill <= 8'h00;
		fillDone = 1;
		writeSignal = 0;		
	end	
	endcase
end

always @(posedge rst, posedge clk12M5)
begin
	if(rst) fillCurrState <= fill_prep;
	else fillCurrState <= fillNextState;
end



endmodule
