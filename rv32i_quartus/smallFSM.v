module smallFSM(rst, clk, out);
input rst, clk;
output reg out;

reg[2:0] state, next_state;

always @(posedge rst, posedge clk)
begin
	if(rst==1) state <= 1;
	else state <= next_state;
end

always @(state)
begin
	case(state)
	3'b001:
		begin
		next_state<=2;
		out <= 0;
		end
	3'b010:
	   begin
		next_state<=3;
		out <= 0;
		end
	3'b011:
	   begin
		next_state<=4;
		out <= 1;
		end
	3'b100:
	   begin
		next_state<=5;
		out <= 0;
		end
	3'b101:
	   begin
		next_state<=1;
		out <= 1;
		end
	default:
	   begin
		next_state<=1;
		out <= 0;
		end
	endcase
end


endmodule