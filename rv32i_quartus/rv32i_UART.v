module rv32i_UART(rst, clk, cs1, we1, addr1, in1, q1, rx, tx);
input rst, clk, cs1, we1;
input [31:0] addr1;
input [31:0] in1;
output [31:0] q1;
reg [31:0] q1;

input rx; //connect to ESP8266's TX pin
output tx;
reg tx; //connect to ESP8266's RX pin

localparam rsize = 16;
localparam ssize = 16;
localparam rwidth = 4;
localparam swidth = 4;

reg rbufEmpty, rbufFull;
reg sbufEmpty, sbufFull;
//reg sbufAlmostFull;
reg [15:0] rbuf [rsize-1:0];
reg [15:0] sbuf [ssize-1:0];
reg [rwidth-1:0] rbufWP, rbufRP;
reg [swidth-1:0] sbufWP, sbufRP;

always @(rbufWP, rbufRP)
begin
	rbufEmpty <= (rbufWP==rbufRP)?1:0;
	rbufFull <= ((rbufWP+4'b0001)==rbufRP)?1:0;
end 

always @(sbufWP, sbufRP)
begin
	sbufEmpty <= (sbufWP==sbufRP)?1:0;
	sbufFull <= ((sbufWP+4'b0001)==sbufRP)?1:0;
	//sbufAlmostFull <= ((sbufWP+4'b0010)==sbufRP)?1:0;
end 

//define the read of the rbuf by the CPU and write of the wbuf by the CPU
always @(posedge rst, posedge clk)
begin
	if(rst)
	begin
		sbufWP <= 0;
		rbufRP <= 0;
	end
	else
	begin
		if(cs1==1)
		begin
			if(we1==1) //CPU write to UART send buffer
			begin
				case(addr1)
				32'hE0039000: //write to send buffer to send a byte
				begin
					sbuf[sbufWP]<=in1[15:0];
					sbufWP<=sbufWP+4'b0001;
				end
				endcase
			end
			else //CPU read from UART
			begin
				case(addr1)
				32'hE0039004:
				begin
					q1<={16'b0, rbuf[rbufRP]};
					rbufRP<=rbufRP+4'b0001;						
				end
				32'hE0039008:
				begin
					q1<={16'b0, 12'b0, sbufEmpty, sbufFull, rbufEmpty, rbufFull};
				end
				32'hE003900C:
				begin
					q1<={16'b0, 11'b0, currSendState};
				end
				32'hE0039010:
				begin
					q1<={16'b0, 11'b0, currReceiveState};
				end
				32'hE0039014:
				begin
					q1<={16'b0, 12'b0, sbufWP};  // 12 bit may need to change if buffer size changes !!!!!!!!!!!!
				end
				32'hE0039018:
				begin
					q1<={16'b0, 12'b0, sbufRP};  // 12 bit may need to change if buffer size changes !!!!!!!!!!!!
				end
				32'hE003901C:
				begin
					q1<={16'b0, 12'b0, rbufWP};  // 12 bit may need to change if buffer size changes !!!!!!!!!!!!
				end
				32'hE0039020:
				begin
					q1<={16'b0, 12'b0, rbufRP};  // 12 bit may need to change if buffer size changes !!!!!!!!!!!!
				end
				32'hE0039024:
				begin
					q1<={16'b0, sbuf[0]};
				end
				32'hE0039028:
				begin
					q1<={16'b0, sbuf[1]};
				end
				32'hE003902C:
				begin
					q1<={31'b0, byteWrite};
				end
				32'hE0039030:
				begin
					q1<={31'b0, sendReady};
				end
				default:
				begin
					q1<=32'bz;
				end
				endcase
			end
		end
		else q1<=32'bz;
	end
end


//define the read of the send buffer by ESP8266
reg sendReady;
reg [15:0] sendReg;
reg byteWrite;
always @(posedge rst, posedge clk)
begin
	if(rst)
	begin
		sbufRP <= 0;
		sendReady <= 0;
		sendReg <= 16'b0;
		byteWrite <= 0;
	end
	else
	begin
		if(currSendState == stateSendStop)
		begin
			if(byteWrite==0)
			begin
				sendReg <= (sbufEmpty==0)?sbuf[sbufRP]:sendReg;
				sbufRP <= (sbufEmpty==0)?(sbufRP + 4'b0001):sbufRP;
				sendReady <= (sbufEmpty==0)?1:0;
				byteWrite <= (sbufEmpty==0)?1:0;
			end
			/*else
			begin
				sendReg <= sendReg;
				sbufRP <= sbufRP;
				sendReady <= sendReady;
				byteWrite <= byteWrite;
			end*/
		end
		else
		begin
			sendReg <= sendReg;
			sbufRP <= sbufRP;
			sendReady <= 0;
			byteWrite <= 0;
		end
	end
end


//define the send FSM that drives the tx
localparam stateSendStop = 5'b00000;
localparam stateSendStart = 5'b00001;
localparam stateSendBit0 = 5'b00010;
localparam stateSendBit1 = 5'b00011;
localparam stateSendBit2 = 5'b00100;
localparam stateSendBit3 = 5'b00101;
localparam stateSendBit4 = 5'b00110;
localparam stateSendBit5 = 5'b00111;
localparam stateSendBit6 = 5'b01000;
localparam stateSendBit7 = 5'b01001;
localparam stateSendStopWait = 5'b10000;
localparam stateSendStartWait = 5'b10001;
localparam stateSendBit0Wait = 5'b10010;
localparam stateSendBit1Wait = 5'b10011;
localparam stateSendBit2Wait = 5'b10100;
localparam stateSendBit3Wait = 5'b10101;
localparam stateSendBit4Wait = 5'b10110;
localparam stateSendBit5Wait = 5'b10111;
localparam stateSendBit6Wait = 5'b11000;
localparam stateSendBit7Wait = 5'b11001;
reg [4:0] currSendState, nextSendState;


always @(currSendState)
begin
	case(currSendState)
	stateSendStop:
	begin
		nextSendState <= (sendReady)?stateSendStopWait:stateSendStop;
		tx <= 1;
		delay8us68Enable2 <= 1;
	end
	stateSendStopWait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendStart:stateSendStopWait;
		tx <= 1;
		delay8us68Enable2 <= 0;
	end
	stateSendStart:
	begin
		nextSendState <= stateSendStartWait;
		tx <= 0;
		delay8us68Enable2 <= 1;
	end
	stateSendStartWait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit0:stateSendStartWait;
		tx <= 0;
		delay8us68Enable2 <= 0;	
	end
	stateSendBit0:
	begin
		nextSendState <= stateSendBit0Wait;
		tx <= sendReg[0];
		delay8us68Enable2 <= 1;
	end
	stateSendBit0Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit1:stateSendBit0Wait;
		tx <= sendReg[0];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit1:
	begin
		nextSendState <= stateSendBit1Wait;
		tx <= sendReg[1];
		delay8us68Enable2 <= 1;
	end
	stateSendBit1Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit2:stateSendBit1Wait;
		tx <= sendReg[1];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit2:
	begin
		nextSendState <= stateSendBit2Wait;
		tx <= sendReg[2];
		delay8us68Enable2 <= 1;
	end
	stateSendBit2Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit3:stateSendBit2Wait;
		tx <= sendReg[2];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit3:
	begin
		nextSendState <= stateSendBit3Wait;
		tx <= sendReg[3];
		delay8us68Enable2 <= 1;
	end
	stateSendBit3Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit4:stateSendBit3Wait;
		tx <= sendReg[3];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit4:
	begin
		nextSendState <= stateSendBit4Wait;
		tx <= sendReg[4];
		delay8us68Enable2 <= 1;
	end
	stateSendBit4Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit5:stateSendBit4Wait;
		tx <= sendReg[4];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit5:
	begin
		nextSendState <= stateSendBit5Wait;
		tx <= sendReg[5];
		delay8us68Enable2 <= 1;
	end
	stateSendBit5Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit6:stateSendBit5Wait;
		tx <= sendReg[5];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit6:
	begin
		nextSendState <= stateSendBit6Wait;
		tx <= sendReg[6];
		delay8us68Enable2 <= 1;
	end
	stateSendBit6Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendBit7:stateSendBit6Wait;
		tx <= sendReg[6];
		delay8us68Enable2 <= 0;	
	end
	stateSendBit7:
	begin
		nextSendState <= stateSendBit7Wait;
		tx <= sendReg[7];
		delay8us68Enable2 <= 1;
	end
	stateSendBit7Wait:
	begin
		nextSendState <= (delay8us68Done2)?stateSendStop:stateSendBit7Wait;
		tx <= sendReg[7];
		delay8us68Enable2 <= 0;	
	end	
	endcase
end

always @(posedge rst, posedge clk)
begin
	if(rst) currSendState <= stateSendStop;
	else currSendState <= nextSendState;
end

//define the write of the receive buffer by ESP8266
reg receiveReady;
reg [15:0] receiveReg;
reg byteRead;
always @(posedge rst, posedge clk)
begin
	if(rst)
	begin
		rbufWP <= 0;
		receiveReady <= 0; //notify the receive FSM to be ready to receive any data sent by ESP8266 (minitor the rx pin)
		byteRead <= 0;
	end
	else
	begin
		if(currReceiveState == stateReceiveStop)
		begin
			if(byteRead==0)
			begin
				if(rbufFull==0) rbuf[rbufWP] <= receiveReg;
				rbufWP <= (rbufFull==0)?(rbufWP+4'b0001):rbufWP;
				receiveReady <= (rbufFull==0)?1:0;
				byteRead <= (rbufFull==0)?1:0;
			end	
		end
		else
		begin
			rbufWP <= rbufWP;
			receiveReady <= 0;
			byteRead <= 0;
		end		
	end
end

//define the receive FSM that reads rx
localparam stateReceiveStop = 5'b00000;
localparam stateReceiveStart = 5'b00001;
localparam stateReceiveBit0 = 5'b00010;
localparam stateReceiveBit1 = 5'b00011;
localparam stateReceiveBit2 = 5'b00100;
localparam stateReceiveBit3 = 5'b00101;
localparam stateReceiveBit4 = 5'b00110;
localparam stateReceiveBit5 = 5'b00111;
localparam stateReceiveBit6 = 5'b01000;
localparam stateReceiveBit7 = 5'b01001;
localparam stateReceiveStopWait = 5'b10000;
localparam stateReceiveStartWait = 5'b10001;
localparam stateReceiveBit0Wait = 5'b10010;
localparam stateReceiveBit1Wait = 5'b10011;
localparam stateReceiveBit2Wait = 5'b10100;
localparam stateReceiveBit3Wait = 5'b10101;
localparam stateReceiveBit4Wait = 5'b10110;
localparam stateReceiveBit5Wait = 5'b10111;
localparam stateReceiveBit6Wait = 5'b11000;
localparam stateReceiveBit7Wait = 5'b11001;

reg [8:0] counter10bit1, counter10bit2;

always @(posedge rst, posedge delay8us68Enable1, posedge clk)
begin
	if(rst) counter10bit1 <= 0;
	else if(delay8us68Enable1) counter10bit1 <= 0;
	else counter10bit1 = counter10bit1 + 1;
end

always @(posedge rst, posedge delay8us68Enable2, posedge clk)
begin
	if(rst) counter10bit2 <= 0;
	else if(delay8us68Enable2) counter10bit2 <= 0;
	else counter10bit2 = counter10bit2 + 1;
end

reg delay8us68Enable1, delay8us68Enable2;
reg delay8us68Done1, delay8us68Done2;

always @(rst, clk)
begin
	if(rst)
	begin
		delay8us68Done1 <= 0;
		delay8us68Done2 <= 0;
	end
	else
	begin
		delay8us68Done1 <= (counter10bit1==9'd432)?1:0; //count 434 to match 115200 baudrate, but considering the preceding 1 clk and trailing 1 clk, we set 432 here
		delay8us68Done2 <= (counter10bit2==9'd432)?1:0;
	end
end

reg [4:0] currReceiveState, nextReceiveState;

always @(currReceiveState)
begin
	case(currReceiveState)
	stateReceiveStop:
	begin
		nextReceiveState <= (receiveReady&&rx)?stateReceiveStart:stateReceiveStop;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 1;
	end
	/*stateReceiveStopWait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveStart:stateReceiveStopWait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;	
	end*/
	stateReceiveStart:
	begin
		nextReceiveState <= (rx==0)?stateReceiveStartWait:stateReceiveStart;
		receiveReg <= receiveReg;
      delay8us68Enable1 <= 1;		
	end
	stateReceiveStartWait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit0:stateReceiveStartWait;
		receiveReg <= receiveReg;
      delay8us68Enable1 <= 0;		
	end
	stateReceiveBit0:
	begin
		nextReceiveState <= stateReceiveBit0Wait;
		receiveReg[0] <= rx;
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit0Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit1:stateReceiveBit0Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit1:
	begin
		nextReceiveState <= stateReceiveBit1Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= rx;
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit1Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit2:stateReceiveBit1Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit2:
	begin
		nextReceiveState <= stateReceiveBit2Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= rx;
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit2Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit3:stateReceiveBit2Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit3:
	begin
		nextReceiveState <= stateReceiveBit3Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= rx;
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit3Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit4:stateReceiveBit3Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit4:
	begin
		nextReceiveState <= stateReceiveBit4Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= rx;
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit4Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit5:stateReceiveBit4Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit5:
	begin
		nextReceiveState <= stateReceiveBit5Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= rx;
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit5Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit6:stateReceiveBit5Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit6:
	begin
		nextReceiveState <= stateReceiveBit6Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= rx;
		receiveReg[7] <= receiveReg[7];
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit6Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveBit7:stateReceiveBit6Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end
	stateReceiveBit7:
	begin
		nextReceiveState <= stateReceiveBit7Wait;
		receiveReg[0] <= receiveReg[0];
		receiveReg[1] <= receiveReg[1];
		receiveReg[2] <= receiveReg[2];
		receiveReg[3] <= receiveReg[3];
		receiveReg[4] <= receiveReg[4];
		receiveReg[5] <= receiveReg[5];
		receiveReg[6] <= receiveReg[6];
		receiveReg[7] <= rx;
		delay8us68Enable1 <= 1;
	end
	stateReceiveBit7Wait:
	begin
		nextReceiveState <= (delay8us68Done1)?stateReceiveStop:stateReceiveBit7Wait;
		receiveReg <= receiveReg;
		delay8us68Enable1 <= 0;
	end	
	endcase
end

always @(posedge rst, posedge clk)
begin
	if(rst) currReceiveState <= stateReceiveStart;
	else currReceiveState <= nextReceiveState;
end

endmodule
