// megafunction wizard: %LPM_CONSTANT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: LPM_CONSTANT 

// ============================================================
// File Name: const2.v
// Megafunction Name(s):
// 			LPM_CONSTANT
//
// Simulation Library Files(s):
// 			
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 23.1std.1 Build 993 05/14/2024 SC Lite Edition
// ************************************************************


//Copyright (C) 2024  Intel Corporation. All rights reserved.
//Your use of Intel Corporation's design tools, logic functions 
//and other software and tools, and any partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Intel Program License 
//Subscription Agreement, the Intel Quartus Prime License Agreement,
//the Intel FPGA IP License Agreement, or other applicable license
//agreement, including, without limitation, that your use is for
//the sole purpose of programming logic devices manufactured by
//Intel and sold by Intel or its authorized distributors.  Please
//refer to the applicable agreement for further details, at
//https://fpgasoftware.intel.com/eula.


//lpm_constant CBX_AUTO_BLACKBOX="ALL" ENABLE_RUNTIME_MOD="NO" LPM_CVALUE=E0020008 LPM_WIDTH=32 result
//VERSION_BEGIN 23.1 cbx_lpm_constant 2024:05:14:17:57:37:SC cbx_mgl 2024:05:14:17:57:46:SC  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463


//synthesis_resources = 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  const2_lpm_constant_q29
	( 
	result) ;
	output   [31:0]  result;


	assign
		result = 32'b11100000000000100000000000001000;
endmodule //const2_lpm_constant_q29
//VALID FILE


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module const2 (
	result);

	output	[31:0]  result;

	wire [31:0] sub_wire0;
	wire [31:0] result = sub_wire0[31:0];

	const2_lpm_constant_q29	const2_lpm_constant_q29_component (
				.result (sub_wire0));

endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: Radix NUMERIC "16"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: Value NUMERIC "3758227464"
// Retrieval info: PRIVATE: nBit NUMERIC "32"
// Retrieval info: PRIVATE: new_diagram STRING "1"
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all
// Retrieval info: CONSTANT: LPM_CVALUE NUMERIC "3758227464"
// Retrieval info: CONSTANT: LPM_HINT STRING "ENABLE_RUNTIME_MOD=NO"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_CONSTANT"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "32"
// Retrieval info: USED_PORT: result 0 0 32 0 OUTPUT NODEFVAL "result[31..0]"
// Retrieval info: CONNECT: result 0 0 32 0 @result 0 0 32 0
// Retrieval info: GEN_FILE: TYPE_NORMAL const2.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL const2.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL const2.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL const2.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL const2_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL const2_bb.v TRUE
