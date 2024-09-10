`timescale 1ns/1ns

module ShuffleNet(
    // High Voltage means Result is ready
    output  wire                Result_Ready,
    // High Voltage means Result is true
    output  wire                Result,
    // -------------------------- Data Flow ----------------------------
    // Data RAM Output
    output  wire[63:0]          out_bus,
    // inA Data RAM form RAMA or RAMB
    // inB Data RAM form RAMB
    input   wire[63:0]          inA_bus, inB_bus,
    // Weight RAM Input
    input   wire[319:0]         weight_bus,
    // ------------------- FSM for Memory Controller ------------------
    // Current & Next CLK Stage
    output  wire[5:0]           Stage, next_Stage,
    // Current & Next CLK Kernel Count
    output  wire[6:0]           Kernel_Cnt, next_Kernel_Cnt,
    // Current CLK Step Count
    output  wire[6:0]           Step_Cnt,
    // Next CLK Need Write
    output  wire                Write_Require,
    // Next CLK Need Kernel
    output  wire                Kernel_Require,
    // Next CLK Need Input
    output  wire                Input_Require_WP,
    // From MFSC ( Start FSM )
    input   wire                MFSC_Ready,
    input   wire                CLK, RST_N
);

    // The Possibility that Result is False or True
    wire[15:0]                  Result_value0, Result_value1;

    // For ConvUnit Control
    wire                        CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias;
    // For ConvChannel Control
    wire                        CC_AvgPool_En, CC_Shift16;
    // For Conv_InputBuffer Control
    wire[2:0]                   CIB_Size;
    wire                        CIB_Shift, CIB_Zero_Input;
    // For ConvLayer Control
    wire[1:0]                   CL_Out_Sel;
    // For MaxPoolBuffer Control
    wire[1:0]                   MPB_In_Sel;
    wire                        MPB_In_Ready, MPB_Out_Ready;

    ShuffleNet_FSM fsm(
        Result_Ready, Result, 
        Stage, next_Stage, Kernel_Cnt, next_Kernel_Cnt, Step_Cnt, Write_Require,
        CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias, 
        CC_AvgPool_En, CC_Shift16, CIB_Size, CIB_Shift, CIB_Zero_Input,
        CL_Out_Sel, MPB_In_Sel, MPB_In_Ready, MPB_Out_Ready, Kernel_Require, Input_Require_WP, MFSC_Ready,
        Result_value0, Result_value1, CLK, RST_N
    );

    Layer_BusConnector layer(
        Result_value0, Result_value1,
        out_bus, inA_bus, inB_bus, weight_bus,
        CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
        CC_AvgPool_En, CC_Shift16, CIB_Size, CIB_Shift, CIB_Zero_Input,
        CL_Out_Sel, MPB_In_Sel, MPB_In_Ready, MPB_Out_Ready, 
        CLK, RST_N
    );

endmodule