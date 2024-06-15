// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
// Date        : Tue Jun  4 20:13:40 2024
// Host        : LAPTOP-34B7KF6P running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/Works/Vivado/ShuffleNet_Sim/ShuffleNet_Sim.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.v
// Design      : clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg400-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_wiz_0(CLK_25, CLK_100, resetn, CLK_125)
/* synthesis syn_black_box black_box_pad_pin="CLK_25,CLK_100,resetn,CLK_125" */;
  output CLK_25;
  output CLK_100;
  input resetn;
  input CLK_125;
endmodule
