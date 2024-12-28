module rv32i_brAddrCalc(ins, pc, brAddr);
input[31:0] ins, pc;
output[31:0] brAddr;

assign brAddr = (ins[31])?(pc + {19'h7FFFF, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0}):(pc + {19'h00000, ins[31], ins[7], ins[30:25], ins[11:8], 1'b0});

endmodule
