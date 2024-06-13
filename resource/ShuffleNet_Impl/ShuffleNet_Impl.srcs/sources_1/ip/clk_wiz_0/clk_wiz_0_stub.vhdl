-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
-- Date        : Thu Jun 13 23:32:25 2024
-- Host        : LAPTOP-34B7KF6P running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/Works/Vivado/ShuffleNet_Impl/ShuffleNet_Impl.srcs/sources_1/ip/clk_wiz_0/clk_wiz_0_stub.vhdl
-- Design      : clk_wiz_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_wiz_0 is
  Port ( 
    CLK_25 : out STD_LOGIC;
    CLK_100 : out STD_LOGIC;
    resetn : in STD_LOGIC;
    CLK_125 : in STD_LOGIC
  );

end clk_wiz_0;

architecture stub of clk_wiz_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "CLK_25,CLK_100,resetn,CLK_125";
begin
end;
