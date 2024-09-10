`timescale 1ns / 1ns

module Layer_BusConnector(
    output  logic[15:0]     Result_value0,
    output  logic[15:0]     Result_value1,
    output  logic[63:0]     out_bus,
    input   logic[63:0]     inA_bus, inB_bus,
    input   logic[319:0]    weight_bus,
    input   logic           CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
    input   logic           CC_AvgPool_En, CC_Shift16,
    input   logic[2:0]      CIB_Size,
    input   logic           CIB_Shift, CIB_Zero_Input,
    input   logic[1:0]      CL_Out_Sel,
    input   logic[1:0]      MPB_In_Sel,
    input   logic           MPB_In_Ready, MPB_Out_Ready,
    input   logic           CLK, RST_N
);

    logic[3:0][15:0]        out;
    logic[3:0][15:0]        inA, inB;
    logic[3:0][4:0][15:0]   weight;

    assign out_bus = {out[3], out[2], out[1], out[0]};
    assign inA = inA_bus;
    assign inB = inB_bus;
    assign weight = weight_bus;

    ShuffleNet_Layer layer(.*);

endmodule