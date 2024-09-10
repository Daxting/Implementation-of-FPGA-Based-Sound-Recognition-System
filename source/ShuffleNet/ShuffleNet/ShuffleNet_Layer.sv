`timescale 1ns / 1ns

// ���n�h
module ShuffleNet_Layer(
    // ���G�������i���
    output  logic[15:0]                 Result_value0,
    // ���G���u���i���
    output  logic[15:0]                 Result_value1,
    // RAM ��X
    output  logic[3:0][15:0]            out,
    // inA �Ѧh�u������Ӧ�RAMA�BRAMB�A inB ����RAMB��X
    input   logic   signed[3:0][15:0]   inA, inB,
    // RAM �v����J
    input   logic[3:0][4:0][15:0]       weight,
    // ----------------------------Controller-----------------------------
    input   logic                       CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
    input   logic                       CC_AvgPool_En, CC_Shift16,
    input   logic[2:0]                  CIB_Size,
    input   logic                       CIB_Shift, CIB_Zero_Input,
    input   logic[1:0]                  CL_Out_Sel,
    input   logic[1:0]                  MPB_In_Sel,
    input   logic                       MPB_In_Ready, MPB_Out_Ready,
    
    input   logic                       CLK, RST_N
);

    // ��X���
    logic[3:0][15:0]            result_selection;
    // ���n�q�D��X
    logic[3:0][15:0]            conv_result;
    // �[�k����X
    logic   signed[3:0][15:0]   add_result;
    // �̤j���ƿ�X
    logic[15:0]                 pool_result;
    // ���n�q�DBuffer��X
    logic[3:0][15:0]            buffer_result;
    // PoolBuffer��J
    logic[3:0][15:0]            poolbuffer_in;
    // PoolBuffer��X
    logic[8:0][15:0]            poolbuffer_out;
    // InputBuffer��X
    logic[3:0][8:0][15:0]       inputbuffer_out;

    // ��ܿ�X
    always_comb begin
        case(CL_Out_Sel)
        2'b00: begin
            result_selection[0] = conv_result[0];
            result_selection[1] = conv_result[1];
            result_selection[2] = conv_result[2];
            result_selection[3] = conv_result[3];
        end
        2'b01: begin
            result_selection[0] = pool_result;
            result_selection[1] = pool_result;
            result_selection[2] = pool_result;
            result_selection[3] = pool_result;
        end
        2'b10: begin
            result_selection[0] = add_result[0];
            result_selection[1] = add_result[1];
            result_selection[2] = add_result[2];
            result_selection[3] = add_result[3];
        end
        2'b11: begin
            result_selection[0] = buffer_result[0];
            result_selection[1] = buffer_result[1];
            result_selection[2] = buffer_result[2];
            result_selection[3] = buffer_result[3];
        end
        endcase
    end

    // �[�k��
    always_comb  begin
        add_result[0] = (inA[0] + inB[0]);
        add_result[1] = (inA[1] + inB[1]);
        add_result[2] = (inA[2] + inB[2]);
        add_result[3] = (inA[3] + inB[3]);
    end

    // �N���n�q�D��X�i�J�̤j���ƽw��
    assign poolbuffer_in = {conv_result[0], conv_result[1], conv_result[2], conv_result[3]};
    
    assign Result_value0 = buffer_result[0];
    assign Result_value1 = buffer_result[1];

    // ��X�i��ReLU6
    Fixed16_Relu6 relu6_0(out[0], result_selection[0]);
    Fixed16_Relu6 relu6_1(out[1], result_selection[1]);
    Fixed16_Relu6 relu6_2(out[2], result_selection[2]);
    Fixed16_Relu6 relu6_3(out[3], result_selection[3]);

    // ��J�w��
    ConvInputBuffer input_buffer0(inputbuffer_out[0], inA[0], CIB_Size, CIB_Shift, CIB_Zero_Input, CLK, RST_N);
    ConvInputBuffer input_buffer1(inputbuffer_out[1], inA[1], CIB_Size, CIB_Shift, CIB_Zero_Input, CLK, RST_N);
    ConvInputBuffer input_buffer2(inputbuffer_out[2], inA[2], CIB_Size, CIB_Shift, CIB_Zero_Input, CLK, RST_N);
    ConvInputBuffer input_buffer3(inputbuffer_out[3], inA[3], CIB_Size, CIB_Shift, CIB_Zero_Input, CLK, RST_N);

    // ���n�q�D
    ConvChannel chan0(buffer_result[0], conv_result[0], inputbuffer_out[0], weight[0], CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias, CC_AvgPool_En, CC_Shift16, CLK, RST_N);
    ConvChannel chan1(buffer_result[1], conv_result[1], inputbuffer_out[1], weight[1], CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias, CC_AvgPool_En, CC_Shift16, CLK, RST_N);
    ConvChannel chan2(buffer_result[2], conv_result[2], inputbuffer_out[2], weight[2], CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias, CC_AvgPool_En, CC_Shift16, CLK, RST_N);
    ConvChannel chan3(buffer_result[3], conv_result[3], inputbuffer_out[3], weight[3], CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias, CC_AvgPool_En, CC_Shift16, CLK, RST_N);

    // �̤j���ƽw��
    MaxPoolBuffer pool_buffer(poolbuffer_out, poolbuffer_in, MPB_In_Sel, MPB_In_Ready, MPB_Out_Ready, CLK, RST_N);
    // �̤j���Ƴ椸
    MaxPool33 maxpool(pool_result, poolbuffer_out);
endmodule