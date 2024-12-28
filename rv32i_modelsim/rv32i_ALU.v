module rv32i_ALU(a, b, op, res, taken);
parameter width = 32;
parameter opw = 6;
input[width-1:0] a, b;
input[opw-1:0] op;
output reg [width-1:0] res;
output reg taken;

wire[width-1:0] sum;
wire[width-1:0] diff;
wire cmp;
wire[width-1:0] res_and;
wire[width-1:0] res_or;
wire[width-1:0] res_xor;
wire[width-1:0] res_sll;
wire[width-1:0] res_srl;
wire[width-1:0] res_sra;

assign sum = a + b;
assign diff = a - b;
assign cmp = a < b;
assign res_and = a & b;
assign res_or = a | b;
assign res_xor = a ^ b;
assign res_sll = (a<<b[4:0]);
assign res_srl = (a>>b[4:0]);
assign res_sra = (a[width-1]==1)?(((1<<b[4:0])-1)<<(width-b[4:0]))+res_srl:res_srl;


always @(op, a, b, sum, diff, cmp, res_and, res_or, res_xor, res_sll, res_srl, res_sra)
begin
	case(op)
	6'b000001: //addition mode: LUI, AUIPC, LB, LH, LW, LBU, LHU, SB, SH, SW, ADDI, ADD
	begin
	res<=sum;
	taken<=0;
	end
	6'b000010: //subtraction mode: SUB 
	begin
	res<=diff;
	taken<=0;
	end
	6'b000011: //slt, slti Note: verilog hdl treats binary sequence as 
	begin
	res<=(a[width-1]^b[width-1])?(a[width-1]?1:0):cmp;
	taken<=0;
	end
	6'b000100: //sltu, sltiu Note: verilog hdl treats binary sequence as	
	begin
	if(cmp)
	begin
	res<=1;
	taken<=0;
	end
	else
	begin
	res<=0;
	taken<=0;
	end
	end
	6'b000101: //BEQ
	begin
	res<=0;
	taken<=(diff==0);
	end
	6'b000110: //BNE
	begin
	res<=0;
	taken<=~(diff==0);
	end
	6'b000111: //BLT
	begin
	res<=0;
	taken<=(a[width-1]^b[width-1])?(a[width-1]?1:0):cmp;
	end
	6'b001000: //BGE
	begin
	res<=0;
	taken<=~((a[width-1]^b[width-1])?(a[width-1]?1:0):cmp);
	end	
	6'b001001: //BLTU
	begin
	res<=0;
	taken<=cmp;
	end
	6'b001010: //BGEU
	begin
	res<=0;
	taken<=~cmp;
	end
	6'b001011: //AND, ANDI
	begin
	res<=res_and;
	taken<=0;
	end
	6'b001100: //OR, ORI
	begin
	res<=res_or;
	taken<=0;
	end
	6'b001101: //XOR, XORI
	begin
	res<=res_xor;
	taken<=0;
	end
	6'b001110: //SLL, SLLI
	begin
	res<=res_sll;
	taken<=0;
	end
	6'b001111: //SRL, SRLI
	begin
	res<=res_srl;
	taken<=0;
	end
	6'b010000: //SRA, SRAI
	begin
	res<=res_sra;
	taken<=0;
	end
	default:
	begin
	res<=0;
	taken<=0;
	end
	endcase
end
endmodule
