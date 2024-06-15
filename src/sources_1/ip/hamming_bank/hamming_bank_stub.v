// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
// Date        : Thu Jun 13 23:34:01 2024
// Host        : LAPTOP-34B7KF6P running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Works/Vivado/ShuffleNet_Impl/ShuffleNet_Impl.srcs/sources_1/ip/hamming_bank/hamming_bank_stub.v
// Design      : hamming_bank
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.1.1_AR75516" *)
module hamming_bank(clka, ena, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,addra[9:0],douta[15:0]" */;
  input clka;
  input ena;
  input [9:0]addra;
  output [15:0]douta;
endmodule
