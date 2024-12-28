module rv32i_ramEnabler(pc, data_in, en, data_out);
input [31:0] pc;
input [31:0] data_in;
input en;
output [31:0] data_out;

assign data_out = ((en==1)&&(pc[31:12]==20'hE0030))?data_in:32'bz;

endmodule