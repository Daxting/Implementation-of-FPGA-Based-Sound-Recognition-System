// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
// Date        : Tue Jun  4 19:45:04 2024
// Host        : LAPTOP-34B7KF6P running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub -rename_top kernel_0 -prefix
//               kernel_0_ kernel_0_stub.v
// Design      : kernel_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2020.1.1_AR75516" *)
module kernel_0(clka, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[8:0],dina[79:0],douta[79:0]" */;
  input clka;
  input [0:0]wea;
  input [8:0]addra;
  input [79:0]dina;
  output [79:0]douta;
endmodule
