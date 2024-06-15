`timescale 1ns / 1ns

// 卷積層輸入緩衝(CIB)
module ConvInputBuffer(
    // 3*3 的16bit輸出
    output  logic[8:0][15:0]    out,
    // 單次16bit輸入
    input   logic[15:0]         in,
    // 當前狀態機下，buffer使用寬度大小，有ARRAY16(預設), ARRAY8, ARRAY4, ARRAY3四種
    input   logic[2:0]          CIB_Size,
    // 狀態機通知移位(高電位)、0輸入模式(高電位時輸入取代為0)         
    input   logic               CIB_Shift, CIB_Zero_Input,
    input   logic               CLK, RST_N
);

    logic[15:0]         input_selection;
    logic[2:0][15:0]    bufferA[0:2];
    logic[2:0][15:0]    bufferB[0:1];
    logic[3:0][15:0]    bufferC[0:1];
    logic[6:0][15:0]    bufferD[0:1];

    assign out = {bufferA[2], bufferA[1], bufferA[0]};
    assign input_selection = (CIB_Zero_Input) ? 16'b0000_0000_0000_0000 : in;

    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            bufferA[0] <= {3{16'b0000_0000_0000_0000}};
            bufferA[1] <= {3{16'b0000_0000_0000_0000}};
            bufferA[2] <= {3{16'b0000_0000_0000_0000}};
        end
        else begin
            if(CIB_Shift) begin
                if(CIB_Size == CIB_SIZE::ARRAY3) begin
                    bufferA[0] <= {bufferA[1][0], bufferA[0][2:1]};
                    bufferA[1] <= {bufferA[2][0], bufferA[1][2:1]};
                    bufferA[2] <= {input_selection, bufferA[2][2:1]};
                end
                else begin
                    bufferA[0] <= {bufferB[0][0], bufferA[0][2:1]};
                    bufferA[1] <= {bufferB[1][0], bufferA[1][2:1]};
                    bufferA[2] <= {input_selection, bufferA[2][2:1]};
                end
            end
            else begin
                bufferA[0] <= bufferA[0];
                bufferA[1] <= bufferA[1];
                bufferA[2] <= bufferA[2];
            end
        end
    end

    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            bufferB[0] <= {3{16'b0000_0000_0000_0000}};
            bufferB[1] <= {3{16'b0000_0000_0000_0000}};
        end
        else begin
            if(CIB_Shift) begin
                if(CIB_Size == CIB_SIZE::ARRAY4) begin
                    bufferB[0] <= {bufferA[1][0], bufferB[0][2:1]};
                    bufferB[1] <= {bufferA[2][0], bufferB[1][2:1]};
                end
                else begin
                    bufferB[0] <= {bufferC[0][0], bufferB[0][2:1]};
                    bufferB[1] <= {bufferC[1][0], bufferB[1][2:1]};
                end
            end
            else begin
                bufferB[0] <= bufferB[0];
                bufferB[1] <= bufferB[1];
            end
        end
    end

    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            bufferC[0] <= {4{16'b0000_0000_0000_0000}};
            bufferC[1] <= {4{16'b0000_0000_0000_0000}};
        end
        else begin
            if(CIB_Shift) begin
                if(CIB_Size == CIB_SIZE::ARRAY8_S1) begin
                    bufferC[0] <= {bufferA[1][0], bufferC[0][3:1]};
                    bufferC[1] <= {bufferA[2][0], bufferC[1][3:1]};
                end
                else if(CIB_Size == CIB_SIZE::ARRAY8_S2) begin
                    bufferC[0] <= {bufferD[0][0], bufferA[1][0], bufferC[0][2:1]};
                    bufferC[1] <= {bufferD[1][0], bufferA[1][0], bufferC[1][2:1]};
                end
                else begin
                    bufferC[0] <= {bufferD[0][0], bufferC[0][3:1]};
                    bufferC[1] <= {bufferD[1][0], bufferC[1][3:1]};
                end
            end
            else begin
                bufferC[0] <= bufferC[0];
                bufferC[1] <= bufferC[1];
            end
        end
    end

    always_ff@(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            bufferD[0] <= {7{16'b0000_0000_0000_0000}};
            bufferD[1] <= {7{16'b0000_0000_0000_0000}};
        end
        else begin
            if(CIB_Shift) begin
                bufferD[0] <= {bufferA[1][0], bufferD[0][6:1]};
                bufferD[1] <= {bufferA[2][0], bufferD[1][6:1]};
            end
            else begin
                bufferD[0] <= bufferD[0];
                bufferD[1] <= bufferD[1];
            end
        end
    end
endmodule
