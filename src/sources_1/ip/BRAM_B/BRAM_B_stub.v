// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
// Date        : Thu Jun 13 23:39:33 2024
// Host        : LAPTOP-34B7KF6P running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Works/Vivado/ShuffleNet_Impl/ShuffleNet_Impl.srcs/sources_1/ip/BRAM_B/BRAM_B_stub.v
// Design      : BRAM_B
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.1.1_AR75516" *)
module BRAM_B(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[9:0],dina[15:0],clkb,addrb[9:0],doutb[15:0]" */;
  input clka;
  input [0:0]wea;
  input [9:0]addra;
  input [15:0]dina;
  input clkb;
  input [9:0]addrb;
  output [15:0]doutb;
endmodule
