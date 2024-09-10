`timescale 1ns / 1ns

`include "ShuffleNet_Define.svh"

/*
    與Stage相關
    Max_Kernel_Cnt;
    Max_Feature_In_X, Max_Feature_In_Y;
    Max_Step_Cnt;
    CIB_Size,

    跟Stage Type有關
    CU_NoWeight,
    CC_AvgPool_En,
    CC_Shift16,
    CL_Out_Sel,

    跟Feature Map相關
    CIB_Zero_Input,
    
    與Operate相關
    MPB_In_Sel,
    CU_Save, 
    CU_CLR,
    CU_In_Sel,
    CU_NoBias,  
    MPB_In_Ready, 
    Kernel_Require,
    Input_Require,
    Write_Require
*/

// ShuffleNet狀態機
module ShuffleNet_FSM(
    // 輸出高電位表示結果已輸出
    output  logic               Result_Ready,
    // 輸出高電位表示結果為真
    output  logic               Result,
    // -------------------- Counter & FSM ------------------------------
    // 當下CLK、下一CLK Stage
    output  logic[5:0]          Stage, next_Stage,
    // 當下CLK、下一CLK Kernel數
    output  logic[6:0]          Kernel_Cnt, next_Kernel_Cnt,
    /*  
        當下CLK Step
        所有開始之前4個CLK Input_Require的計數
        對於DWS1、DWS2 用於計算Init的CLK
            註: 對於DWS2特例GLOBAL_DW Step表達為MaxPool計數
        對於PW 用於計算輸入通道數，
        對於AVG2、AVG4 用於計算輸入格數
        對於ADD 保持為0
        對於FulC 用於計算通道數
    */
    output  logic[6:0]          Step_Cnt,
    // 下一個CLK需要輸出資料
    output  logic               Write_Require,
    // -------------------- Enable Controller ------------------------------
    output  logic               CU_Save, CU_CLR, CU_In_Sel, CU_NoWeight, CU_NoBias,
    output  logic               CC_AvgPool_En, CC_Shift16,
    output  logic[2:0]          CIB_Size,
    output  logic               CIB_Shift, CIB_Zero_Input,
    output  logic[1:0]          CL_Out_Sel,
    output  logic[1:0]          MPB_In_Sel,
    output  logic               MPB_In_Ready, MPB_Out_Ready,
    output  logic               Kernel_Require, Input_Require_WP,
    // 來自MFSC
    input   logic               MFSC_Ready,
    // 結果為假的可能性
    input   logic signed[15:0]         Result_value0,
    // 結果為真的可能性
    input   logic signed[15:0]         Result_value1,

    input   logic               CLK, RST_N
);
    logic               Input_Require, Padding;
    // 當下CLK、下一CLK Feature Map Input X、Y
    logic[6:0]          Feature_In_X, Feature_In_Y, next_Feature_In_X, next_Feature_In_Y;
    // 下一CLK Step
    logic[6:0]          next_Step_Cnt;
    STAGE_TYPE::t       Stage_Type;
    CAL_STATE::t        Cal_State, next_Cal_State;
    OPERATE::t          Operate, next_Operate;
    logic[1:0]          next_MPB_In_Sel;

    logic[6:0]          Max_Kernel_Cnt;
    logic[6:0]          Max_Feature_In_X, Max_Feature_In_Y;
    logic[6:0]          Max_Step_Cnt;

    logic               Kernel_Carry;
    logic               Feature_In_X_Carry, Feature_In_Y_Carry;
    logic               Step_Carry;
    logic               Operate_Carry;

    // debug用電路 用於模擬實際數據運作生效時機
    /*
    logic[3:0]          Input_Require_Shift;
    logic[2:0]          Kernel_Require_Shift;

    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            Input_Require_Shift <= 4'b0000;
            Kernel_Require_Shift <= 3'b000;
        end
        else begin
            Input_Require_Shift <= {Input_Require_Shift[2:0], Input_Require_WP};
            Kernel_Require_Shift <= {Kernel_Require_Shift[1:0], Kernel_Require};
        end
    end
    */

    assign Input_Require_WP = (Input_Require & !Padding);

    // 結果判斷
    assign Result_Ready = (Stage == STAGE::RESULT || Stage == STAGE::IDLE);
    assign Result = (Stage == STAGE::RESULT) ? (Result_value1 > Result_value0) : 1'b0;

    // Counter判斷
    assign Kernel_Carry = (Kernel_Cnt == Max_Kernel_Cnt);
    assign Feature_In_X_Carry = (Feature_In_X == Max_Feature_In_X);
    assign Feature_In_Y_Carry = (Feature_In_Y == Max_Feature_In_Y);
    assign Step_Carry = (Step_Cnt == Max_Step_Cnt);
    assign Operate_Carry = (Operate == OPERATE::CONV2);

    // 查表 Stage對應的Stage Type
    always_comb begin
        case(Stage)
            STAGE::IDLE: Stage_Type = STAGE_TYPE::NONE;
            // Stage 1 
            STAGE::GLOBAL_DW: Stage_Type = STAGE_TYPE::DWS2;
            // Stage 2 Up
            STAGE::AVG_POOL0: Stage_Type = STAGE_TYPE::AVG2;
            STAGE::PW0: Stage_Type = STAGE_TYPE::PW__;
            STAGE::DW0: Stage_Type = STAGE_TYPE::DWS2;
            STAGE::PW1: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW2: Stage_Type = STAGE_TYPE::PW__;
            // Stage 2 Down
            STAGE::PW3: Stage_Type = STAGE_TYPE::PW__;
            STAGE::DW1: Stage_Type = STAGE_TYPE::DWS1;
            STAGE::PW4: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW5: Stage_Type = STAGE_TYPE::PW__;
            STAGE::ADD0: Stage_Type = STAGE_TYPE::ADD_;
            // Stage 3 Up
            STAGE::AVG_POOL1: Stage_Type = STAGE_TYPE::AVG2; 
            STAGE::PW6: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW7: Stage_Type = STAGE_TYPE::PW__; 
            STAGE::DW2: Stage_Type = STAGE_TYPE::DWS2;
            STAGE::PW8: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW9: Stage_Type = STAGE_TYPE::PW__; 
            // Stage 3 Down 1
            STAGE::PW10: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW11: Stage_Type = STAGE_TYPE::PW__;
            STAGE::DW3:  Stage_Type = STAGE_TYPE::DWS1;
            STAGE::PW12: Stage_Type = STAGE_TYPE::PW__; 
            STAGE::PW13: Stage_Type = STAGE_TYPE::PW__; 
            STAGE::ADD1: Stage_Type = STAGE_TYPE::ADD_;
            // Stage 3 Down 2
            STAGE::PW14: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW15: Stage_Type = STAGE_TYPE::PW__;
            STAGE::DW4:  Stage_Type = STAGE_TYPE::DWS1; 
            STAGE::PW16: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW17: Stage_Type = STAGE_TYPE::PW__; 
            STAGE::ADD2: Stage_Type = STAGE_TYPE::ADD_;
            // Stage 3 Down 3
            STAGE::PW18: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW19: Stage_Type = STAGE_TYPE::PW__;
            STAGE::DW5:  Stage_Type = STAGE_TYPE::DWS1;
            STAGE::PW20: Stage_Type = STAGE_TYPE::PW__;
            STAGE::PW21: Stage_Type = STAGE_TYPE::PW__;
            STAGE::ADD3: Stage_Type = STAGE_TYPE::ADD_;
            // Stage Final
            STAGE::AVG_POOL2: Stage_Type = STAGE_TYPE::AVG4;
            STAGE::FC: Stage_Type = STAGE_TYPE::FULC;
            STAGE::RESULT: Stage_Type = STAGE_TYPE::NONE;
            default: Stage_Type = STAGE_TYPE::NONE;
        endcase
    end

    // 查表 Stage對應的Input Buffer Size
    always_comb begin
        case(Stage)
            // Stage 1 
            STAGE::GLOBAL_DW: CIB_Size = CIB_SIZE::ARRAY16;
            // Stage 2 Up
            STAGE::DW0: CIB_Size = CIB_SIZE::ARRAY16;
            // Stage 2 Down
            STAGE::DW1: CIB_Size = CIB_SIZE::ARRAY8_S1;
            // Stage 3 Up
            STAGE::DW2: CIB_Size = CIB_SIZE::ARRAY8_S2;
            // Stage 3 Down 1
            STAGE::DW3: CIB_Size = CIB_SIZE::ARRAY4;
            // Stage 3 Down 2
            STAGE::DW4: CIB_Size = CIB_SIZE::ARRAY4; 
            // Stage 3 Down 3
            STAGE::DW5: CIB_Size = CIB_SIZE::ARRAY4;
            // Stage Final
            default: CIB_Size = CIB_SIZE::ARRAY3;
        endcase
    end

    // 查表 Stage對應的Counter Max值
    always_comb begin
        case(Stage)
            STAGE::IDLE: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd0, 7'd0, 7'd0};
            // Stage 1 
            STAGE::GLOBAL_DW: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd16, 7'd16, 7'd64};
            // Stage 2 Up
            STAGE::AVG_POOL0: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd7, 7'd7};
            STAGE::PW0: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd15, 7'd15};
            STAGE::DW0: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd16, 7'd16};
            STAGE::PW1: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd7, 7'd7};
            STAGE::PW2: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd7, 7'd7};
            // Stage 2 Down
            STAGE::PW3: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd7, 7'd7};
            STAGE::DW1: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd9, 7'd9};
            STAGE::PW4: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd7, 7'd7};
            STAGE::PW5: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd7, 7'd7};
            STAGE::ADD0: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd7, 7'd7};
            // Stage 3 Up
            STAGE::AVG_POOL1: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3};
            STAGE::PW6: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd7, 7'd7};
            STAGE::PW7: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd7, 7'd7}; 
            STAGE::DW2: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd8, 7'd8};
            STAGE::PW8: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd3, 7'd3};
            STAGE::PW9: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd3, 7'd3};
            // Stage 3 Down 1
            STAGE::PW10: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd3, 7'd3};
            STAGE::PW11: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd3, 7'd3};
            STAGE::DW3:  {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd5, 7'd5};
            STAGE::PW12: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3}; 
            STAGE::PW13: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3};  
            STAGE::ADD1: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd16, 7'd3, 7'd3};
            // Stage 3 Down 2
            STAGE::PW14: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd3, 7'd3};
            STAGE::PW15: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd3, 7'd3};
            STAGE::DW4:  {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd5, 7'd5}; 
            STAGE::PW16: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3}; 
            STAGE::PW17: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3}; 
            STAGE::ADD2: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd16, 7'd3, 7'd3};
            // Stage 3 Down 3
            STAGE::PW18: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd3, 7'd3};
            STAGE::PW19: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd2, 7'd3, 7'd3};
            STAGE::DW5:  {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd4, 7'd5, 7'd5};
            STAGE::PW20: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3};
            STAGE::PW21: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd8, 7'd3, 7'd3};
            STAGE::ADD3: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd16, 7'd3, 7'd3}; 
            // Stage Final
            STAGE::AVG_POOL2: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd64, 7'd3, 7'd3}; 
            STAGE::FC: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd1, 7'd0, 7'd0}; 
            STAGE::RESULT: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd0, 7'd0, 7'd0};
            default: {Max_Kernel_Cnt, Max_Feature_In_X, Max_Feature_In_Y} = {7'd0, 7'd0, 7'd0};
        endcase
    end

    // 查表 Stage Type對應的Enable Line
    always_comb begin
        case(Stage_Type)
            STAGE_TYPE::NONE: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b11};
            STAGE_TYPE::DWS1: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b00};
            STAGE_TYPE::DWS2: begin
                if(Stage == STAGE::GLOBAL_DW) {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b01};
                else {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b00};
            end
            STAGE_TYPE::PW__: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b00};
            STAGE_TYPE::AVG2: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b1, 1'b1, 1'b0, 2'b00};
            STAGE_TYPE::AVG4: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b1, 1'b1, 1'b1, 2'b00};
            STAGE_TYPE::ADD_: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b1, 1'b0, 1'b0, 2'b10};
            STAGE_TYPE::FULC: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b11};
            default: {CU_NoWeight, CC_AvgPool_En, CC_Shift16, CL_Out_Sel} = {1'b0, 1'b0, 1'b0, 2'b11};
        endcase
    end

    // Stage 更新為next_Stage
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) Stage <= STAGE::IDLE;
        else Stage <= next_Stage;
    end

    /*  Stage_Type推算next_Stage
        NONE            由MFSC_Ready決定
        GLOBAL_DW       由Step_Cnt、Cal_State決定
        DWS1、DWS2      由Kernel、FeatureMap決定
        PW__            由Kernel、FeatureMap、Step決定
        AVG2、AVG4      由Kernel、FeatureMap、Step決定
        ADD_            由Kernel、FeatureMap決定
        FulC            由Step_Cnt決定
    */
    always_comb begin
        case(Stage_Type)
            STAGE_TYPE::NONE: begin
                // 啟動計算
                if(Stage == STAGE::IDLE && MFSC_Ready) next_Stage = STAGE::GLOBAL_DW;
                // 輸出結果並在下一個CLK回復IDLE
                else if(Stage == STAGE::RESULT) next_Stage = STAGE::IDLE;
                else next_Stage = Stage;
            end
            STAGE_TYPE::DWS1, STAGE_TYPE::DWS2: begin
                // DWS2 特例
                if(Stage == STAGE::GLOBAL_DW) begin
                    // 必須在Cal_State等待MaxPool 結束後進入下一Stage
                    if(Cal_State == CAL_STATE::MPOL & Step_Carry & Kernel_Carry) next_Stage = STAGE::AVG_POOL0;
                    else next_Stage = Stage;
                end
                else begin
                    if(Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry & Operate_Carry) next_Stage = Stage + 6'd1;
                    else next_Stage = Stage;
                end
            end
            STAGE_TYPE::PW__, STAGE_TYPE::AVG2, STAGE_TYPE::AVG4: begin
                if(Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry & Step_Carry & Operate_Carry) next_Stage = Stage + 6'd1;
                else next_Stage = Stage;
            end
            STAGE_TYPE::ADD_: begin
                if(Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry) next_Stage = Stage + 6'd1;
                else next_Stage = Stage;
            end
            STAGE_TYPE::FULC: begin
                if(Step_Carry & Operate_Carry) next_Stage = Stage + 6'd1;
                else next_Stage = Stage;
            end
            default: next_Stage = STAGE::IDLE;
        endcase
    end

    // Kernel_Cnt 更新為next_Kernel_Cnt
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) Kernel_Cnt <= 7'd0;
        else Kernel_Cnt <= next_Kernel_Cnt;
    end

    /*  推算next_Kernel_Cnt
        ** 依賴next_Stage
    */
    always_comb begin
        // 初始化時Kernel維持為0
        if(Cal_State == CAL_STATE::INIT) begin
            if(Stage_Type == STAGE_TYPE::DWS2 && Stage != STAGE::GLOBAL_DW) begin
	    	if(Step_Carry & Kernel_Cnt == 7'd0) next_Kernel_Cnt = 7'd1;
                else next_Kernel_Cnt = Kernel_Cnt;
            end
            else begin
                // 開始計算時Kernel為1
                if(Step_Carry) next_Kernel_Cnt = 7'd1;
                else next_Kernel_Cnt = 7'd0;
            end
        end
        // 下一階段是新Stage時(初始化) 初始化時Kernel為0
        else if(Stage != next_Stage) next_Kernel_Cnt = 7'd0;
        else begin
            case(Stage_Type)
                STAGE_TYPE::NONE: next_Kernel_Cnt = 7'd0;
                STAGE_TYPE::DWS1,
                STAGE_TYPE::DWS2: begin
                    // 在DWS1、DWS2模式下每計算完一張圖且最後一格計算完全 Kernel_Cnt就加一，直到達到該stage最大Kernel_Cnt
                    if(Stage == STAGE::GLOBAL_DW) begin
                        if(Cal_State == CAL_STATE::MPOL & Step_Carry) begin
                            if(Kernel_Carry) next_Kernel_Cnt = 7'd0;
                            else next_Kernel_Cnt = Kernel_Cnt + 7'd1;
                        end
                        else next_Kernel_Cnt = Kernel_Cnt;
                    end
                    else begin
                        if(Feature_In_X_Carry & Feature_In_Y_Carry & Operate_Carry) begin
                            if(Kernel_Carry) next_Kernel_Cnt = 7'd0;
                            else next_Kernel_Cnt = Kernel_Cnt + 7'd1;
                        end
                        else next_Kernel_Cnt = Kernel_Cnt;
                    end
                    
                end
                STAGE_TYPE::PW__: begin
                    // 在PW模式下每計算完一張圖且最後一格計算完全 Kernel_Cnt就加一，直到達到該stage最大Kernel_Cnt
                    if(Feature_In_X_Carry & Feature_In_Y_Carry & Step_Carry & Operate_Carry) begin
                        if(Kernel_Carry) next_Kernel_Cnt = 7'd0;
                        else next_Kernel_Cnt = Kernel_Cnt + 7'd1;
                    end
                    else next_Kernel_Cnt = Kernel_Cnt;
                end
                STAGE_TYPE::AVG2: begin
                    if(Feature_In_X_Carry & Feature_In_Y_Carry & Step_Carry) begin
                        if(Kernel_Carry) next_Kernel_Cnt = 7'd0;
                        else next_Kernel_Cnt = Kernel_Cnt + 7'd1;
                    end
                    else next_Kernel_Cnt = Kernel_Cnt;
                end
                STAGE_TYPE::AVG4,
                STAGE_TYPE::ADD_: begin
                    // 在4*4最大池化、加法模式下每計算完一張圖Kernel_Cnt就加一，直到達到該stage最大Kernel_Cnt
                    if(Feature_In_X_Carry & Feature_In_Y_Carry) begin
                        if(Kernel_Carry) next_Kernel_Cnt = 7'd0;
                        else next_Kernel_Cnt = Kernel_Cnt + 7'd1;
                    end
                    else next_Kernel_Cnt = Kernel_Cnt;
                end
                STAGE_TYPE::FULC: next_Kernel_Cnt = 7'd1;
                default: next_Kernel_Cnt = 7'd0;
            endcase
        end
    end

    // Feature_In 更新為next_Feature_In
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            Feature_In_X <= 7'd0;
            Feature_In_Y <= 7'd0;
        end
        else begin
            Feature_In_X <= next_Feature_In_X;
            Feature_In_Y <= next_Feature_In_Y;
        end
    end

    // 推算Feature In
    always_comb begin
        if(Cal_State == CAL_STATE::CALC || Cal_State == CAL_STATE::BUFF) begin
            case(Stage_Type)
                STAGE_TYPE::NONE,
                STAGE_TYPE::FULC: {next_Feature_In_X, next_Feature_In_Y} = {7'd0, 5'd0};
                STAGE_TYPE::DWS1,
                STAGE_TYPE::DWS2: begin
                    case(next_Operate)
                        OPERATE::ADD__: {next_Feature_In_X, next_Feature_In_Y} = {7'd0, 5'd0};
                        OPERATE::SHIFT,
                        OPERATE::CONV1: begin
                            if(Feature_In_X_Carry) begin
                                if(Feature_In_Y_Carry) next_Feature_In_Y = 5'd0;
                                else next_Feature_In_Y = Feature_In_Y + 5'd1;
                                next_Feature_In_X = 7'd0;
                            end
                            else {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X + 7'd1, Feature_In_Y};                            
                        end
                        OPERATE::CONV2: {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X, Feature_In_Y};
                        default: {next_Feature_In_X, next_Feature_In_Y} = {7'd0, 5'd0};
                    endcase
                end
                STAGE_TYPE::PW__: begin
                    if(Step_Carry) begin
                        if(Feature_In_X_Carry) begin
                            if(Feature_In_Y_Carry) next_Feature_In_Y = 5'd0;
                            else next_Feature_In_Y = Feature_In_Y + 5'd1;
                            next_Feature_In_X = 7'd0;
                        end
                        else {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X + 7'd1, Feature_In_Y};
                    end
                    else {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X, Feature_In_Y};
                end
                STAGE_TYPE::AVG2: begin
                    if(Step_Carry) begin
                        if(Feature_In_X_Carry) begin
                            if(Feature_In_Y_Carry) next_Feature_In_Y = 5'd0;
                            else next_Feature_In_Y = Feature_In_Y + 5'd1;
                            next_Feature_In_X = 7'd0;
                        end
                        else {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X + 7'd1, Feature_In_Y};
                    end
                    else {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X, Feature_In_Y};
                    
                end 
                STAGE_TYPE::AVG4,
                STAGE_TYPE::ADD_: begin
                    if(Feature_In_X_Carry) begin
                        if(Feature_In_Y_Carry) next_Feature_In_Y = 5'd0;
                        else next_Feature_In_Y = Feature_In_Y + 5'd1;
                        next_Feature_In_X = 7'd0;
                    end
                    else {next_Feature_In_X, next_Feature_In_Y} = {Feature_In_X + 7'd1, Feature_In_Y};
                end 
                default: {next_Feature_In_X, next_Feature_In_Y} = {7'd0, 5'd0};
            endcase            
        end
        else {next_Feature_In_X, next_Feature_In_Y} = {7'd0, 5'd0};
    end

    // Cal_State 更新為next_Cal_State
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) Cal_State <= CAL_STATE::IDLE;
        else Cal_State <= next_Cal_State;
    end

    // 根據Cal_State查表Max_Step_Cnt
    always_comb begin
        case(Cal_State)
            CAL_STATE::IDLE: Max_Step_Cnt = 7'd1;
            CAL_STATE::INIT: Max_Step_Cnt = 7'd4;
            CAL_STATE::BUFF: begin
                case(CIB_Size)
                    CIB_SIZE::ARRAY3: Max_Step_Cnt = 7'd4;
                    CIB_SIZE::ARRAY4: Max_Step_Cnt = 7'd14;
                    CIB_SIZE::ARRAY8_S1: Max_Step_Cnt = 7'd22;
                    CIB_SIZE::ARRAY8_S2: Max_Step_Cnt = 7'd19;
                    CIB_SIZE::ARRAY16: Max_Step_Cnt = 7'd35;
                    default: Max_Step_Cnt = 7'd1;
                endcase
            end
            CAL_STATE::CALC: begin
                case(Stage_Type)
                    STAGE_TYPE::NONE: Max_Step_Cnt = 7'd1;
                    STAGE_TYPE::DWS1: Max_Step_Cnt = 7'd1;
                    STAGE_TYPE::DWS2: begin
                        // Step_Cnt給MaxPool Buffer使用
                        if(Stage == STAGE::GLOBAL_DW) Max_Step_Cnt = 7'd25;
                        else Max_Step_Cnt = 7'd1;
                    end
                    STAGE_TYPE::PW__: begin
                        case(Stage)
                            // Stage 2 Up
                            STAGE::PW0: Max_Step_Cnt = 7'd16;
                            STAGE::PW1: Max_Step_Cnt = 7'd4;
                            STAGE::PW2: Max_Step_Cnt = 7'd4;
                            // Stage 2 Down
                            STAGE::PW3: Max_Step_Cnt = 7'd32;
                            STAGE::PW4: Max_Step_Cnt = 7'd4; 
                            STAGE::PW5: Max_Step_Cnt = 7'd4;
                            // Stage 3 Up
                            STAGE::PW6: Max_Step_Cnt = 7'd16;
                            STAGE::PW7: Max_Step_Cnt = 7'd16; 
                            STAGE::PW8: Max_Step_Cnt = 7'd8; 
                            STAGE::PW9: Max_Step_Cnt = 7'd8;  
                            // Stage 3 Down 1
                            STAGE::PW10: Max_Step_Cnt = 7'd32; 
                            STAGE::PW11: Max_Step_Cnt = 7'd32; 
                            STAGE::PW12: Max_Step_Cnt = 7'd8; 
                            STAGE::PW13: Max_Step_Cnt = 6'd8;
                            // Stage 3 Down 2
                            STAGE::PW14: Max_Step_Cnt = 7'd32; 
                            STAGE::PW15: Max_Step_Cnt = 7'd32; 
                            STAGE::PW16: Max_Step_Cnt = 7'd8;  
                            STAGE::PW17: Max_Step_Cnt = 7'd8; 
                            // Stage 3 Down 3
                            STAGE::PW18: Max_Step_Cnt = 7'd32; 
                            STAGE::PW19: Max_Step_Cnt = 7'd32;   
                            STAGE::PW20: Max_Step_Cnt = 7'd8;  
                            STAGE::PW21: Max_Step_Cnt = 7'd8; 
                            default: Max_Step_Cnt = 7'd1;
                        endcase
                    end
                    STAGE_TYPE::AVG2: Max_Step_Cnt = 7'd4;
                    STAGE_TYPE::AVG4: Max_Step_Cnt = 7'd16;
                    STAGE_TYPE::ADD_: Max_Step_Cnt = 7'd1;
                    STAGE_TYPE::FULC: Max_Step_Cnt = 7'd64;
                    default: Max_Step_Cnt = 7'd1;
                endcase
            end
            CAL_STATE::MPOL: Max_Step_Cnt = 7'd17;
            default: Max_Step_Cnt = 7'd1;
        endcase
    end

    // 推算next_Cal_State
    always_comb begin
        case(Cal_State)
            CAL_STATE::IDLE: begin
                // 啟動時Global DW需要初始化
                if(Stage == STAGE::IDLE & MFSC_Ready) next_Cal_State = CAL_STATE::INIT;
                else next_Cal_State = Cal_State;
            end
            CAL_STATE::INIT: begin
                // 初始化計算完4個CLK後 DW轉為等待Buff填充、其他開始進行計算。
                if(Step_Carry) begin
                    if(Stage_Type == STAGE_TYPE::DWS1 | Stage_Type == STAGE_TYPE::DWS2) next_Cal_State = CAL_STATE::BUFF;
                    else next_Cal_State = CAL_STATE::CALC;
                end
                else next_Cal_State = Cal_State;
            end
            CAL_STATE::BUFF: begin
                // 等待Buffer填充完畢
                if(Step_Carry) next_Cal_State = CAL_STATE::CALC;
                else next_Cal_State = Cal_State;
            end
            CAL_STATE::CALC: begin
                case(Stage_Type)
                    STAGE_TYPE::DWS1,
                    STAGE_TYPE::DWS2: begin
                        if(Stage == STAGE::GLOBAL_DW) begin
                            // Global DW會在BUFF、CALC與MPOL之間循環
                            if(Feature_In_X_Carry & Feature_In_Y_Carry & Operate_Carry) next_Cal_State = CAL_STATE::MPOL;
                            else next_Cal_State = Cal_State;
                        end
                        else begin
                            // DW 會在BUFF與CALC之間循環，直到達到最大Kernel
                            if(Feature_In_X_Carry & Feature_In_Y_Carry & Operate_Carry) begin
                                if(Kernel_Carry) next_Cal_State = CAL_STATE::INIT;
                                else if(Stage_Type == STAGE_TYPE::DWS2) next_Cal_State = CAL_STATE::INIT;
                                else next_Cal_State = CAL_STATE::BUFF;
                            end
                            else next_Cal_State = Cal_State;
                        end
                    end
                    STAGE_TYPE::PW__,
                    STAGE_TYPE::AVG2, 
                    STAGE_TYPE::AVG4: begin
                        if(Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry & Step_Carry & Operate_Carry) next_Cal_State = CAL_STATE::INIT;
                        else next_Cal_State = Cal_State;
                    end 
                    STAGE_TYPE::ADD_: begin
                        if(Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry) next_Cal_State = CAL_STATE::INIT;
                        else next_Cal_State = Cal_State;
                    end
                    STAGE_TYPE::FULC: begin
                        if(Step_Carry & Operate_Carry) next_Cal_State = CAL_STATE::IDLE;
                        else next_Cal_State = Cal_State;
                    end
                    default: next_Cal_State = CAL_STATE::IDLE;
                endcase
            end
            CAL_STATE::MPOL: begin
                // 等待最大池化完畢
                if(Step_Carry) begin
                    if(Kernel_Carry) next_Cal_State = CAL_STATE::INIT;
                    else next_Cal_State = CAL_STATE::BUFF;
                end
                else next_Cal_State = Cal_State;
            end
            default: next_Cal_State = CAL_STATE::IDLE;
        endcase
    end

    // Step_Cnt 更新為next_Step_Cnt
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) Step_Cnt <= 7'd0;
        else Step_Cnt <= next_Step_Cnt;
    end

    // 推算next_Step_Cnt
    always_comb begin
        case(Cal_State)
            CAL_STATE::IDLE: begin
                if(MFSC_Ready) next_Step_Cnt = 7'd1;
                else next_Step_Cnt = 7'd0;
            end
            CAL_STATE::INIT: begin
                if(Step_Carry) next_Step_Cnt = 7'd1;
                else next_Step_Cnt = Step_Cnt + 7'd1;
            end
            CAL_STATE::BUFF: begin
                if(Step_Carry) begin
                    if(Stage == STAGE::GLOBAL_DW & Feature_In_Y == 7'd2) next_Step_Cnt = 7'd2;
                    else next_Step_Cnt = 7'd1;
                end
                else next_Step_Cnt = Step_Cnt + 7'd1;
            end
            CAL_STATE::CALC: begin
                case(Stage_Type)
                    STAGE_TYPE::NONE: next_Step_Cnt = 7'd0;
                    STAGE_TYPE::DWS1: next_Step_Cnt = 7'd1;
                    STAGE_TYPE::DWS2: begin
                        if(Stage == STAGE::GLOBAL_DW) begin
                            if(Step_Carry) begin
                                if(!(next_Feature_In_Y[0])) next_Step_Cnt = 7'd1;
                                else next_Step_Cnt = Step_Cnt;
                            end
                            else next_Step_Cnt = Step_Cnt + 7'd1;
                        end
                        else next_Step_Cnt = 7'd1;
                    end
                    STAGE_TYPE::PW__,
                    STAGE_TYPE::AVG2, 
                    STAGE_TYPE::AVG4,
                    STAGE_TYPE::FULC: begin
                        if(Step_Carry) next_Step_Cnt = 7'd1;
                        else next_Step_Cnt = Step_Cnt + 7'd1;
                    end
                    STAGE_TYPE::ADD_: next_Step_Cnt = 7'd1;
                    default: next_Step_Cnt = 7'd0;
                endcase
            end
            CAL_STATE::MPOL:
                if(Step_Carry) next_Step_Cnt = 7'd1;
                else next_Step_Cnt = Step_Cnt + 7'd1;
            default: next_Step_Cnt = 7'd0;
        endcase
    end

    // Operate 更新為next_Operate
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) Operate <= OPERATE::ADD__;
        else Operate <= next_Operate;
    end

    // 推算next_Operate
    always_comb begin
        case(Cal_State)
            CAL_STATE::IDLE: begin
                if(MFSC_Ready) next_Operate = OPERATE::SHIFT;
                else next_Operate = OPERATE::ADD__;
            end
            CAL_STATE::INIT: begin
                if(Step_Carry & Stage_Type == STAGE_TYPE::ADD_) next_Operate = OPERATE::ADD__;
                else next_Operate = OPERATE::SHIFT;
            end
            CAL_STATE::BUFF: begin
                if(Step_Carry & Stage_Type == STAGE_TYPE::DWS1) next_Operate = OPERATE::CONV1;
                else next_Operate = OPERATE::SHIFT;
            end
            CAL_STATE::CALC: begin
                case(Stage_Type)
                    STAGE_TYPE::NONE: next_Operate = OPERATE::ADD__;
                    STAGE_TYPE::DWS1: begin
                        case(Operate)
                            OPERATE::ADD__: next_Operate = OPERATE::SHIFT;
                            OPERATE::SHIFT: begin
                                if(Feature_In_X == 7'd0) next_Operate = OPERATE::SHIFT;
                                else next_Operate = OPERATE::CONV1;
                            end
                            OPERATE::CONV1: next_Operate = OPERATE::CONV2;
                            OPERATE::CONV2: begin
                                if(Feature_In_X_Carry) next_Operate = OPERATE::SHIFT;
                                else next_Operate = OPERATE::CONV1;
                            end
                            default: next_Operate = OPERATE::SHIFT;
                        endcase
                    end
                    STAGE_TYPE::DWS2: begin
                        case(Operate)
                            OPERATE::ADD__: next_Operate = OPERATE::SHIFT;
                            OPERATE::SHIFT: begin
                                if(Feature_In_X == 7'd0) next_Operate = OPERATE::SHIFT;
                                else next_Operate = OPERATE::CONV1;
                            end
                            OPERATE::CONV1: next_Operate = OPERATE::CONV2;
                            OPERATE::CONV2: begin
                                if(Stage == STAGE::GLOBAL_DW & Step_Carry & Feature_In_X_Carry & Feature_In_Y_Carry) next_Operate = OPERATE::ADD__;
                                else 
                                    next_Operate = OPERATE::SHIFT;
                            end
                            default: next_Operate = OPERATE::SHIFT;
                        endcase
                    end
                    STAGE_TYPE::PW__,
                    STAGE_TYPE::AVG2,
                    STAGE_TYPE::AVG4,
                    STAGE_TYPE::FULC: next_Operate = (Step_Cnt[1:0] == 2'b11) ? OPERATE::CONV2 : OPERATE::SHIFT;
                    STAGE_TYPE::ADD_: begin
                        if(Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry) next_Operate = OPERATE::SHIFT;
                        else next_Operate = OPERATE::ADD__;
                    end
                    default: next_Operate = OPERATE::ADD__;
                endcase
            end
            CAL_STATE::MPOL: begin
                if(Step_Carry) next_Operate = OPERATE::SHIFT;
                else next_Operate = OPERATE::ADD__;
            end
            default: next_Operate = OPERATE::ADD__;
        endcase
    end

    // 推算CIB_Zero_Input
    always_comb begin
        if(Stage_Type == STAGE_TYPE::DWS1 & (next_Feature_In_X == 7'd0 || next_Feature_In_Y == 7'd0 || next_Feature_In_X == Max_Feature_In_X || next_Feature_In_Y == Max_Feature_In_Y)) begin
            CIB_Zero_Input = 1'b1;
        end
        else if(Stage_Type == STAGE_TYPE::DWS2) begin
            if(next_Feature_In_X == Max_Feature_In_X && Stage != STAGE::GLOBAL_DW) CIB_Zero_Input = 1'b1;
            else if(next_Feature_In_Y == Max_Feature_In_Y) CIB_Zero_Input = 1'b1;
            else CIB_Zero_Input = 1'b0;
        end
        else CIB_Zero_Input = 1'b0;
    end

    // 推算Padding
    always_comb begin
        if(Stage_Type == STAGE_TYPE::DWS1) begin
            if(Cal_State == CAL_STATE::INIT) Padding = 1'b1;
            else if(Cal_State == CAL_STATE::BUFF) begin
                // 首行Padding
                if(Feature_In_Y == 7'd0 && (Feature_In_X <= (Max_Feature_In_X - 7'd3))) Padding = 1'b1;
                // 第二行Padding
                else if(Feature_In_Y == 7'd1 && (Feature_In_X == (Max_Feature_In_X - 7'd4) || Feature_In_X == (Max_Feature_In_X - 7'd3))) Padding = 1'b1;
                else Padding = 1'b0;
            end
            else if(Cal_State == CAL_STATE::CALC) begin
                // 末行Padding
                if(Feature_In_Y == (Max_Feature_In_Y - 7'd1) && (Feature_In_X == (Max_Feature_In_X - 7'd1) || Feature_In_X == (Max_Feature_In_X)) ) Padding = 1'd1;
                else if(Feature_In_Y == Max_Feature_In_Y) Padding = 1'b1;
                // 行頭、行尾Padding
                else if((Feature_In_X == (Max_Feature_In_X - 7'd2) || Feature_In_X == (Max_Feature_In_X - 7'd1)) && Operate == OPERATE::CONV1) Padding = 1'b1;
                else Padding = 1'b0;
            end
            else Padding = 1'b0;
        end
        else if(Stage_Type == STAGE_TYPE::DWS2) begin
            if(Cal_State == CAL_STATE::BUFF) begin
                if(Feature_In_X == (Max_Feature_In_X - 7'd4) && Stage != STAGE::GLOBAL_DW) Padding = 1'b1;
                else Padding = 1'b0;
            end
            else if(Cal_State == CAL_STATE::CALC) begin
                // 末行Padding
                if(Feature_In_Y == (Max_Feature_In_Y - 7'd1) && ((Feature_In_X == (Max_Feature_In_X - 7'd3)) || (Feature_In_X == (Max_Feature_In_X - 7'd2) || Feature_In_X == (Max_Feature_In_X - 7'd1)) || (Feature_In_X == (Max_Feature_In_X)))) begin
                    if(Stage == STAGE::GLOBAL_DW && Feature_In_X == (Max_Feature_In_X - 7'd3)) Padding = 1'd0;
                    else Padding = 1'd1;
                end
                else if(Feature_In_Y == Max_Feature_In_Y) Padding = 1'b1;
                // 行尾Padding
                else if(Feature_In_X == (Max_Feature_In_X - 7'd3) && Operate == OPERATE::SHIFT && Stage != STAGE::GLOBAL_DW) Padding = 1'b1;
                else Padding = 1'b0;
            end
            else Padding = 1'b0;
        end
        else Padding = 1'b0;
    end

    // 推算CIB_Shift
    always_comb begin
        case(Stage_Type)
            STAGE_TYPE::NONE: CIB_Shift = 1'b0;
            STAGE_TYPE::DWS1: begin
                if(Operate == OPERATE::CONV2 || Operate == OPERATE::SHIFT) CIB_Shift = 1'b1;
                else CIB_Shift = 1'b0;
            end
            STAGE_TYPE::DWS2: begin
                if(Operate == OPERATE::CONV2 || Operate == OPERATE::SHIFT) CIB_Shift = 1'b1;
                else CIB_Shift = 1'b0;
            end
            STAGE_TYPE::PW__: CIB_Shift = 1'b1;
            STAGE_TYPE::AVG2: CIB_Shift = 1'b1;
            STAGE_TYPE::AVG4: CIB_Shift = 1'b1;
            STAGE_TYPE::ADD_: CIB_Shift = 1'b0;
            STAGE_TYPE::FULC: CIB_Shift = 1'b1;
            default: CIB_Shift = 1'b0;
        endcase
    end

    // 推算Input_Require、Kernel_Require
    always_comb begin
        case(Stage_Type)
            STAGE_TYPE::NONE: {Input_Require, Kernel_Require} = 2'b00;
            STAGE_TYPE::DWS1: begin
                // Buffer Cal_State 末尾3個CLK要請求Kernel
                if(Cal_State == CAL_STATE::BUFF & (Step_Cnt == (Max_Step_Cnt - 7'd2) || Step_Cnt == (Max_Step_Cnt - 7'd1) || Step_Cnt == (Max_Step_Cnt))) Kernel_Require = 1'b1;
                else if(Cal_State == CAL_STATE::CALC) begin
                    // 末尾1.5個CLK不請求Kernel
                    if(Feature_In_Y_Carry && ((Operate == OPERATE::CONV2 && Feature_In_X == (Max_Feature_In_X - 7'd1)) || Feature_In_X == (Max_Feature_In_X))) begin
                        Kernel_Require = 1'b0;
                    end
                    // 每排末尾的CONV1與前一個CONV2不請求Kernel
                    else if(Feature_In_X == (Max_Feature_In_X) && Operate == OPERATE::CONV1 || Feature_In_X == (Max_Feature_In_X - 7'd1) && Operate == OPERATE::CONV2) begin
                        Kernel_Require = 1'b0;
                    end
                    else Kernel_Require = 1'b1;
                end
                else Kernel_Require = 1'b0;

                if(Cal_State == CAL_STATE::INIT) Input_Require = 1'b1;
                else if(Cal_State == CAL_STATE::BUFF) begin
                    if(Step_Carry) Input_Require = 1'b0;
                    else if(Feature_In_X == (Max_Feature_In_X) && Feature_In_Y == 7'd1) Input_Require = 1'b0;
                    else Input_Require = 1'b1;
                end
                else if(Cal_State == CAL_STATE::CALC) begin
                    // 末尾3個CLK不請求Input
                    if(Feature_In_Y_Carry & (Feature_In_X == (Max_Feature_In_X - 7'd2) || Feature_In_X == (Max_Feature_In_X - 7'd1) || Feature_In_X == (Max_Feature_In_X))) begin
                        Input_Require = 1'b0;
                    end
                    else if(Operate == OPERATE::CONV1) Input_Require = 1'b1;
                    else if(Feature_In_X == 7'd0) Input_Require = 1'b1;
                    else if(Feature_In_X == (Max_Feature_In_X - 7'd1) && Operate == OPERATE::CONV2) Input_Require = 1'b1;
                    else Input_Require = 1'b0;
                end
                else Input_Require = 1'b0;

            end
            STAGE_TYPE::DWS2: begin
                // Buffer Cal_State 末尾2個CLK要請求Kernel
                if(Cal_State == CAL_STATE::BUFF & (Step_Cnt == (Max_Step_Cnt - 7'd1) || Step_Cnt == (Max_Step_Cnt))) Kernel_Require = 1'b1;
                else if(Cal_State == CAL_STATE::CALC) begin
                    // 末尾3個CLK不請求Kernel
                    if(Feature_In_Y_Carry & (Feature_In_X == (Max_Feature_In_X - 7'd2) || Feature_In_X == (Max_Feature_In_X - 7'd1) || Feature_In_X == (Max_Feature_In_X))) begin
                        Kernel_Require = 1'b0;
                    end
                    // 每一行第一格必請求Kernel
                    else if(Feature_In_X == 7'd0) Kernel_Require = 1'b1;
                    // 換行前一格CONV1不請求Kernel，其他請求
                    else if(Operate == OPERATE::CONV1) begin
                        if(Feature_In_X_Carry) Kernel_Require = 1'b0;
                        else Kernel_Require = 1'b1;
                    end
                    // CONV2必請求Kernel
                    else if(Operate == OPERATE::CONV2) Kernel_Require = 1'b1;
                    else Kernel_Require = 1'b0;
                end
                else Kernel_Require = 1'b0;

                
                if(Cal_State == CAL_STATE::CALC) begin
                    // 末尾3個CLK不請求Input
                    if(Feature_In_Y_Carry & (Feature_In_X == (Max_Feature_In_X - 7'd2) || Feature_In_X == (Max_Feature_In_X - 7'd1) || Feature_In_X == (Max_Feature_In_X))) begin
                        Input_Require = 1'b0;
                    end
                    // 除每行末尾的CONV1請求Input外，其餘不請求
                    else if(Operate == OPERATE::CONV1) begin
                        if(Feature_In_X_Carry) Input_Require = 1'b1;
                        else Input_Require = 1'b0;
                    end
                    else if(Feature_In_X_Carry) Input_Require = 1'b0;
                    else Input_Require = 1'b1;
                end
                else if(Cal_State == CAL_STATE::INIT) Input_Require = 1'b1;
                else if(Cal_State == CAL_STATE::BUFF) begin
                    if(Feature_In_X_Carry && Feature_In_Y == 7'd1) Input_Require = 1'b0;
                    else Input_Require = 1'b1;
                end
                else if(Cal_State == CAL_STATE::MPOL && !Kernel_Carry) begin
                    if(Step_Cnt == 7'd14 || Step_Cnt == 7'd15 || Step_Cnt == 7'd16 || Step_Cnt == 7'd17) Input_Require = 1'b1;
                    else Input_Require = 1'b0;
                end
                else Input_Require = 1'b0;
            end
            STAGE_TYPE::PW__: begin
                Kernel_Require = (Step_Cnt[1:0] == 2'b01) && (Cal_State == CAL_STATE::CALC);
                // 末尾3個CLK不請求Input
                if(Cal_State == CAL_STATE::CALC & Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry & (Step_Cnt == (Max_Step_Cnt - 7'd2) || Step_Cnt == (Max_Step_Cnt - 7'd1) || Step_Cnt == (Max_Step_Cnt))) Input_Require = 1'b0;
                else Input_Require = 1'b1;
            end
            STAGE_TYPE::AVG2: begin
                Kernel_Require = 1'b0;
                // 末尾3個CLK不請求Input
                if(Cal_State == CAL_STATE::CALC & Kernel_Carry & Feature_In_X_Carry & Feature_In_Y_Carry & (Step_Cnt == 7'd2 || Step_Cnt == 7'd3 || Step_Cnt == 7'd4)) Input_Require = 1'b0;
                else Input_Require = 1'b1;
            end
            STAGE_TYPE::AVG4: begin
                Kernel_Require = 1'b0;
                // 末尾3個CLK不請求Input
                if(Cal_State == CAL_STATE::CALC & Kernel_Carry & (Step_Cnt == 7'd14 || Step_Cnt == 7'd15 || Step_Cnt == 7'd16)) Input_Require = 1'b0;
                else Input_Require = 1'b1;
            end
            STAGE_TYPE::FULC: begin
                Kernel_Require = (Step_Cnt[1:0] == 2'b01) && (Cal_State == CAL_STATE::CALC);
                // 末尾3個CLK不請求Input
                if(Cal_State == CAL_STATE::CALC & (Step_Cnt == 7'd62 || Step_Cnt == 7'd63 || Step_Cnt == 7'd64)) Input_Require = 1'b0;
                else Input_Require = 1'b1;
            end
            STAGE_TYPE::ADD_: begin
                Kernel_Require = 1'b0;
                // INIT第一個CLK不請求Input
                if(Cal_State == CAL_STATE::INIT & Step_Cnt == 7'd1) Input_Require = 1'b0;
                // 末尾3個CLK不請求Input
                //else if(Feature_In_Y_Carry & Feature_In_X != 7'd0) Input_Require = 1'b0;
                else if(Kernel_Carry & Feature_In_Y_Carry & (Feature_In_X == Max_Feature_In_X - 7'd2 || Feature_In_X == Max_Feature_In_X - 7'd1 || Feature_In_X == Max_Feature_In_X)) Input_Require = 1'b0;
                else Input_Require = 1'b1;
            end
            default: {Input_Require, Kernel_Require} = 2'b00;
        endcase
    end

    // 推算CU_Save、CU_CLR、CU_In_Sel、CU_NoBias、Write_Require
    always_comb begin
        if(Cal_State == CAL_STATE::CALC || Cal_State == CAL_STATE::MPOL) begin
            case(Stage_Type)
                STAGE_TYPE::NONE: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                STAGE_TYPE::DWS1: begin
                    case(Operate)
                        OPERATE::ADD__: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                        OPERATE::SHIFT: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                        OPERATE::CONV1: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b11010;
                        OPERATE::CONV2: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10111;
                        default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                    endcase
                end
                STAGE_TYPE::DWS2: begin
                    if(Stage == STAGE::GLOBAL_DW) begin
                        Write_Require = MPB_Out_Ready;
                        case(Operate)
                            OPERATE::ADD__: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias} = 4'b0111;
                            OPERATE::SHIFT: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias} = 4'b0111;
                            OPERATE::CONV1: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias} = 4'b1100;
                            OPERATE::CONV2: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias} = 4'b1110;
                            default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias} = 4'b0111;
                        endcase 
                    end
                    else begin
                        case(Operate)
                            OPERATE::ADD__: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                            OPERATE::SHIFT: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                            OPERATE::CONV1: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b11010;
                            OPERATE::CONV2: begin
                                {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias} = 4'b1011;
                                Write_Require = !(Feature_In_Y[0]);
                            end
                            default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                        endcase 
                    end
                end
                STAGE_TYPE::PW__: begin
                    case(Operate)
                        OPERATE::SHIFT: begin
                            // 第一個Step進行Reset
                            if(Step_Cnt == 7'd1) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b00110;
                        end
                        OPERATE::CONV2: begin
                            // 完成一組時輸出
                            if(Step_Carry) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10111;
                            // 第一次加法不考慮Buffer
                            else if(Step_Cnt == 7'd4) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b11110;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10110;
                        end
                        default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                    endcase
                end
                STAGE_TYPE::AVG2: begin
                    case(Operate)
                        OPERATE::SHIFT: begin
                            // 第一個Step進行Reset
                            if(Step_Cnt == 7'd1) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b00110;
                        end
                        OPERATE::CONV2: begin
                            // 完成一組時輸出
                            if(Step_Carry) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10111;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10110;
                        end
                        default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                    endcase
                end
                STAGE_TYPE::AVG4: begin
                    case(Operate)
                        OPERATE::SHIFT: begin
                            // 第一個Step進行Reset
                            if(Step_Cnt == 7'd1) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b00110;
                        end
                        OPERATE::CONV2: begin
                            // 完成一組時輸出
                            if(Step_Carry) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10111;
                            // 第一次加法不考慮Buffer
                            else if(Step_Cnt == 7'd4) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b11110;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10110;
                        end
                        default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                    endcase
                end
                STAGE_TYPE::ADD_: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01111;
                STAGE_TYPE::FULC: begin
                    case(Operate)
                        OPERATE::SHIFT: begin
                            // 第一個Step進行Reset
                            if(Step_Cnt == 7'd1) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b00110;
                        end
                        OPERATE::CONV2: begin
                            // 完成一組時輸出
                            if(Step_Carry) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10111;
                            // 第一次加法需要考慮Bias，並且不考慮Buffer
                            else if(Step_Cnt == 7'd4) {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b11100;
                            else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b10110;
                        end
                        default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
                    endcase
                end
                default: {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
            endcase
        end
        else {CU_Save, CU_CLR, CU_In_Sel, CU_NoBias, Write_Require} = 5'b01110;
    end

    // MaxPool Buffer MPB_In_Sel更新為next_MPB_In_Sel
    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) MPB_In_Sel <= 2'b00;
        else MPB_In_Sel <= next_MPB_In_Sel;
    end

    // 推算next_MPB_In_Sel
    always_comb begin
        if(Stage == STAGE::GLOBAL_DW) begin
            if(next_Cal_State == CAL_STATE::MPOL) begin
                next_MPB_In_Sel = 2'b01;
            end
            else if(next_Cal_State == CAL_STATE::CALC) begin
                if(Cal_State == CAL_STATE::MPOL) next_MPB_In_Sel = 2'b00;
                else if(Step_Carry & !(next_Feature_In_Y[0])) begin
                    if(Cal_State == CAL_STATE::BUFF) next_MPB_In_Sel = MPB_In_Sel;
                    else next_MPB_In_Sel = MPB_In_Sel + 2'b01;
                end
                else next_MPB_In_Sel = MPB_In_Sel;
            end
            else next_MPB_In_Sel = 2'b00;
        end
        else next_MPB_In_Sel = 2'b00;
    end

    // 推算MPB_In_Ready、MPB_Out_Ready
    always_comb begin
        if(Stage == STAGE::GLOBAL_DW) begin
            // 只要在GLOBAL_DW Stage下非奇數排Conv2就要讀取資料
            MPB_In_Ready = (Operate == OPERATE::CONV2) & !(Feature_In_Y[0]);

            if(!(Feature_In_Y[0])) begin
                if((Cal_State == CAL_STATE::CALC | Cal_State == CAL_STATE::MPOL) & (MPB_In_Sel[0] == 1'b1) & (Feature_In_Y != 7'd4)) begin
                    case(Step_Cnt)
                        7'd1: MPB_Out_Ready = 1'b0;
                        7'd2: MPB_Out_Ready = 1'b1;
                        7'd3: MPB_Out_Ready = 1'b1;
                        7'd4: MPB_Out_Ready = 1'b1;
                        7'd5: MPB_Out_Ready = 1'b1;
                        7'd6: MPB_Out_Ready = 1'b1;
                        7'd7: MPB_Out_Ready = 1'b1;
                        7'd8: MPB_Out_Ready = 1'b1;
                        7'd9: MPB_Out_Ready = 1'b1;
                        7'd10: MPB_Out_Ready = 1'b1;
                        7'd11: MPB_Out_Ready = 1'b1;
                        7'd12: MPB_Out_Ready = 1'b1;
                        7'd13: MPB_Out_Ready = 1'b1;
                        7'd14: MPB_Out_Ready = 1'b1;
                        7'd15: MPB_Out_Ready = 1'b1;
                        7'd16: MPB_Out_Ready = 1'b1;
                        7'd17: MPB_Out_Ready = 1'b1;
                        7'd18: MPB_Out_Ready = 1'b0;
                        7'd19: MPB_Out_Ready = 1'b0;
                        7'd20: MPB_Out_Ready = 1'b0;
                        7'd21: MPB_Out_Ready = 1'b0;
                        7'd22: MPB_Out_Ready = 1'b0;
                        7'd23: MPB_Out_Ready = 1'b0;
                        7'd24: MPB_Out_Ready = 1'b0;
                        7'd25: MPB_Out_Ready = 1'b0;
                        default: MPB_Out_Ready = 1'b0;
                    endcase
                end
                else MPB_Out_Ready = 1'b0;
            end
            else MPB_Out_Ready = 1'b0;
        end
        else {MPB_In_Ready, MPB_Out_Ready} = 2'b00;
    end
    
endmodule