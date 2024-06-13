-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.1.1_AR75516 (win64) Build 2960000 Wed Aug  5 22:57:20 MDT 2020
-- Date        : Thu Jun 13 23:35:02 2024
-- Host        : LAPTOP-34B7KF6P running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/Works/Vivado/ShuffleNet_Impl/ShuffleNet_Impl.srcs/sources_1/ip/melbank/melbank_stub.vhdl
-- Design      : melbank
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg400-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity melbank is
  Port ( 
    clka : in STD_LOGIC;
    ena : in STD_LOGIC;
    addra : in STD_LOGIC_VECTOR ( 14 downto 0 );
    douta : out STD_LOGIC_VECTOR ( 15 downto 0 )
  );

end melbank;

architecture stub of melbank is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,ena,addra[14:0],douta[15:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_4,Vivado 2020.1.1_AR75516";
begin
end;
