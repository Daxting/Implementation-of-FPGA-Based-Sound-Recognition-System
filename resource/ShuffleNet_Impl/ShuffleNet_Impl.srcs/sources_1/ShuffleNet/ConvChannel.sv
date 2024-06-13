`timescale 1ns / 1ns
// dsp卷積通道(CC)
module ConvChannel(
    output  logic   signed[15:0]        buffer_out,
    output  logic   signed[15:0]        out,
    input   logic   signed[8:0][15:0]   in,
    input   logic   signed[4:0][15:0]   weight,
    // ----------------------------Controller-----------------------------
    input   logic                       CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
    input   logic                       CC_AvgPool_En, CC_Shift16,
    input   logic                       CLK, RST_N
);

    logic   signed[15:0]    conv_out;

    // 決定要不要平均池化、要除以二或四
    always_comb begin
        case({CC_AvgPool_En, CC_Shift16})
            2'b00: out = conv_out;
            2'b01: out = conv_out;
            2'b10: out = (conv_out >>> 2);
            2'b11: out = (conv_out >>> 4);
        endcase
    end

    // 卷積單元
    ConvUnit unit(buffer_out, conv_out, in, weight, CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias, CLK, RST_N);
endmodule