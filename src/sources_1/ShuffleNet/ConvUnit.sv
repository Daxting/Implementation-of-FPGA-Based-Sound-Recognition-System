`timescale 1ns / 1ns
// 卷積單元 (5dsp並行)(CU)
module ConvUnit(
    output  logic   signed[15:0]        buffer_out,
    output  logic   signed[15:0]        out,
    input   logic   signed[8:0][15:0]   in,
    input   logic   signed[4:0][15:0]   weight,
    // ----------------------------Controller-----------------------------
    input   logic                       CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
    input   logic                       CLK, RST_N
);

    // 暫存
    logic   signed[15:0]    buffer;
    // buffer累加輸出
    logic   signed[15:0]    buffer_selection;
    // bias符號位拓展
    logic   signed[31:0]    bias_extension[0:4];
    // 中間值
    logic   signed[31:0]    midvalue[0:4];
    // 中間值縮減
    logic   signed[15:0]    midvalue_cut[0:4];
    // 特徵選擇輸入
    logic   signed[15:0]    input_selection[0:4];
    // 權重選擇輸入
    logic   signed[15:0]    weight_selection[0:4];

    assign buffer_out = buffer;

    assign out = midvalue_cut[4];
    
    assign buffer_selection = (CU_CLR) ? 16'b0000_0000_0000_0000 : buffer;

    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) buffer <= 16'b0000_0000_0000_0000;
        else begin
            if(CU_Save) buffer <= midvalue_cut[4];
            else if(CU_CLR) buffer <= 16'b0000_0000_0000_0000;
            else buffer <= buffer;
        end
    end

    always_comb begin
        midvalue_cut[0] = midvalue[0][25:10];
        midvalue_cut[1] = midvalue[1][25:10];
        midvalue_cut[2] = midvalue[2][25:10];
        midvalue_cut[3] = midvalue[3][25:10];
        midvalue_cut[4] = midvalue[4][25:10];
        bias_extension[0] = { {6{buffer_selection[15]}}, buffer_selection, {10{1'b0}} };
        bias_extension[1] = { {6{midvalue_cut[0][15]}}, midvalue_cut[0], {10{1'b0}} };
        bias_extension[2] = { {6{midvalue_cut[1][15]}}, midvalue_cut[1], {10{1'b0}} };
        bias_extension[3] = { {6{midvalue_cut[2][15]}}, midvalue_cut[2], {10{1'b0}} };
        bias_extension[4] = { {6{midvalue_cut[3][15]}}, midvalue_cut[3], {10{1'b0}} };
    end

    always_comb begin
        midvalue[0] = (input_selection[0] * weight_selection[0]) + bias_extension[0];
        midvalue[1] = (input_selection[1] * weight_selection[1]) + bias_extension[1];
        midvalue[2] = (input_selection[2] * weight_selection[2]) + bias_extension[2];
        midvalue[3] = (input_selection[3] * weight_selection[3]) + bias_extension[3];
        midvalue[4] = (input_selection[4] * weight_selection[4]) + bias_extension[4];
    end

    // 選擇特徵輸入
    always_comb begin
        if(CU_In_Sel) begin
            input_selection[0] = 16'b0000_0100_0000_0000;
            input_selection[1] = in[8];
            input_selection[2] = in[7];
            input_selection[3] = in[6];
            input_selection[4] = in[5];
        end
        else begin
            input_selection[0] = in[4];
            input_selection[1] = in[3];
            input_selection[2] = in[2];
            input_selection[3] = in[1];
            input_selection[4] = in[0];
        end
    end

    // 選擇權重輸入
    always_comb begin
        if(CU_NoWeight) begin
            weight_selection[0] = (CU_NoBias) ? 16'b0000_0000_0000_0000 : 16'b0000_0100_0000_0000;;
            weight_selection[1] = 16'b0000_0100_0000_0000;
            weight_selection[2] = 16'b0000_0100_0000_0000;
            weight_selection[3] = 16'b0000_0100_0000_0000;
            weight_selection[4] = 16'b0000_0100_0000_0000;
        end
        else begin
            weight_selection[0] = (CU_NoBias) ? 16'b0000_0000_0000_0000 : weight[4];
            weight_selection[1] = weight[3];
            weight_selection[2] = weight[2];
            weight_selection[3] = weight[1];
            weight_selection[4] = weight[0];
        end
    end
endmodule