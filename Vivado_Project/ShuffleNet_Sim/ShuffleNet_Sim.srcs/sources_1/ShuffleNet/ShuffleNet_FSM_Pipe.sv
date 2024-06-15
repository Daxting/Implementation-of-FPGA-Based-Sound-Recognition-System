`timescale 1ns / 1ns

`include "ShuffleNet_Define.svh"

module ShuffleNet_FSM(
    // 結果輸出
    output  logic                   Result,
    // 結果可用標記
    output  logic                   Result_Ready,
    // ----------------------- 控制訊號 ------------------------
    output  logic                   CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
    output  logic                   CC_AvgPool_En, CC_Shift16,
    output  logic[2:0]              CIB_Size,
    output  logic                   CIB_Shift, CIB_Zero_Input,
    output  logic[1:0]              CL_Out_Sel,
    output  logic[1:0]              MPB_In_Sel,
    output  logic                   MPB_In_Ready, MPB_Out_Ready,
    output  logic                   Kernel_Require, Read_Require, Write_Require,
    // ----------------------- 狀態機輸入 ----------------------
    input   logic   signed[15:0]    Result_value0,
    input   logic   signed[15:0]    Result_value1,
    input   logic                   CLK, RST_N
);

    logic[5:0]  Pipe0_next_Stage, Pipe0_Stage, Pipe1_Stage, Pipe2_Stage, Pipe3_Stage;
    logic[5:0]  Pipe0_Stage_type, Pipe2_Stage_type;
    logic[6:0]  Pipe0_next_Kernel, Pipe0_Kernel, Pipe1_Kernel, Pipe2_Kernel, Pipe3_Kernel;
    logic[6:0]  Pipe0_next_FeatureIn_Y, Pipe0_FeatureIn_Y, Pipe1_FeatureIn_Y, Pipe2_FeatureIn_Y, Pipe3_FeatureIn_Y;
    logic[6:0]  Pipe0_next_FeatureIn_X, Pipe0_FeatureIn_X, Pipe1_FeatureIn_X, Pipe2_FeatureIn_X, Pipe3_FeatureIn_X;
    logic[6:0]  Pipe0_next_Step, Pipe0_Step, Pipe1_Step, Pipe2_Step, Pipe3_Step;
    logic[2:0]  Pipe0_next_CalState, Pipe0_CalState, Pipe1_CalState, Pipe2_CalState, Pipe3_CalState;
    logic[1:0]  Pipe0_next_Operate, Pipe0_Operate, Pipe1_Operate, Pipe2_Operate, Pipe3_Operate;

endmodule