package STAGE;
    // 1 Stage
    localparam IDLE         = 6'd0;
    localparam GLOBAL_DW    = 6'd1;
    // Stage 2 Up
    localparam AVG_POOL0    = 6'd2;
    localparam PW0          = 6'd3;
    localparam DW0          = 6'd4;
    localparam PW1          = 6'd5;
    localparam PW2          = 6'd6;
    // Stage 2 Down
    localparam PW3          = 6'd7;
    localparam DW1          = 6'd8;
    localparam PW4          = 6'd9;
    localparam PW5          = 6'd10;
    localparam ADD0         = 6'd11;
    // Stage 3 Up
    localparam AVG_POOL1    = 6'd12;
    localparam PW6          = 6'd13;
    localparam PW7          = 6'd14;
    localparam DW2          = 6'd15;
    localparam PW8          = 6'd16;
    localparam PW9          = 6'd17;
    // Stage 3 Down 1
    localparam PW10         = 6'd18;
    localparam PW11         = 6'd19;
    localparam DW3          = 6'd20;
    localparam PW12         = 6'd21;
    localparam PW13         = 6'd22;
    localparam ADD1         = 6'd23;
    // Stage 3 Down 2
    localparam PW14         = 6'd24;
    localparam PW15         = 6'd25;
    localparam DW4          = 6'd26;
    localparam PW16         = 6'd27;
    localparam PW17         = 6'd28;
    localparam ADD2         = 6'd29;
    // Stage 3 Down 3
    localparam PW18         = 6'd30;
    localparam PW19         = 6'd31;
    localparam DW5          = 6'd32;
    localparam PW20         = 6'd33;
    localparam PW21         = 6'd34;
    localparam ADD3         = 6'd35;
    // Stage Final
    localparam AVG_POOL2    = 6'd36;
    localparam FC           = 6'd37;
    localparam RESULT       = 6'd38;

    // typedef enum logic[5:0] {
    //     IDLE = 6'd0, GLOBAL_DW = 6'd1, 
    //     AVG_POOL0 = 6'd2, PW0 = 6'd3, DW0 = 6'd4, PW1 = 6'd5, PW2 = 6'd6, 
    //     PW3 = 6'd7, DW1 = 6'd8, PW4 = 6'd9, PW5 = 6'd10, ADD0 = 6'd11, 
    //     AVG_POOL1 = 6'd12, PW6 = 6'd13, PW7 = 6'd14, DW2 = 6'd15, PW8 = 6'd16, PW9 = 6'd17, 
    //     PW10 = 6'd18, PW11 = 6'd19, DW3 = 6'd20, PW12 = 6'd21, PW13 = 6'd22, ADD1 = 6'd23,
    //     PW14 = 6'd24, PW15 = 6'd25, DW4 = 6'd26, PW16 = 6'd27, PW17 = 6'd28, ADD2 = 6'd29,
    //     PW18 = 6'd30, PW19 = 6'd31, DW5 = 6'd32, PW20 = 6'd33, PW21 = 6'd34, ADD3 = 6'd35, 
    //     AVG_POOL2 = 6'd36, FC = 6'd37, RESULT = 6'd38
    // } t;
endpackage

package STAGE_TYPE;
    typedef enum logic[2:0] { 
        NONE, 
        DWS1, 
        DWS2, 
        PW__, 
        AVG2, 
        AVG4, 
        ADD_, 
        FULC 
    } t;
endpackage

package CAL_STATE;
    typedef enum logic[2:0] {
        IDLE,   // 閒置
        INIT,   // 4個CLK的初始化(發送Input請求)
        BUFF,   // 等待Input Buffer填充
        //LINE,   // 等待整排移位(DWS2)
        CALC,   // 計算
        MPOL    // 等待池化完成
    } t;
endpackage

package OPERATE;
    typedef enum logic[1:0] {
        ADD__,  // 閒置、2 RAM加法
        SHIFT,  // InputBuffer移位並接收輸入
        CONV1,  // 前半5組輸入卷積
        CONV2   // 後半4組輸入+一組Bias卷積
    } t;
endpackage

package CIB_SIZE;
    localparam ARRAY3       = 3'd0;
    localparam ARRAY4       = 3'd1;
    localparam ARRAY8_S1    = 3'd2;
    localparam ARRAY8_S2    = 3'd3;
    localparam ARRAY16      = 3'd4;

    // typedef enum logic[2:0] { 
    //     ARRAY3, 
    //     ARRAY4, 
    //     ARRAY8_S1, 
    //     ARRAY8_S2, 
    //     ARRAY16 
    // } t;
endpackage