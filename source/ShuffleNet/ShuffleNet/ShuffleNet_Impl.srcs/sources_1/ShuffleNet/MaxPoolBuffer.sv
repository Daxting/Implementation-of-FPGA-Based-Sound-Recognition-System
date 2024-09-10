`timescale 1ns / 1ns
// 輸入端的ReLU6會導致14、13bit消失(因為必為0)
// 最大池化緩衝(MPB)
module MaxPoolBuffer(
    output  logic[8:0][15:0]    out,
    input   logic[3:0][15:0]    in,
    // 00 輸入第0排與第六排， 01 輸入第二排並對B組最大池化， 10 輸入第三排與第四排， 11 輸入第五排並對A組最大池化
    input   logic[1:0]          MPB_In_Sel,
    // MPB_In_Ready 表達有資料要傳入MPB、MPB_Out_Ready表達該CLK要輸出MP
    input   logic               MPB_In_Ready, MPB_Out_Ready,
    input   logic               CLK, RST_N
);

    logic[2:0][31:0][15:0]      bufferA, bufferB;

    always_comb begin : MPB_Output_Selection
        case(MPB_In_Sel)
        2'b00: out = {9{16'b0000_0000_0000_0000}};
        2'b01: out = {bufferB[0][2:0], bufferB[1][2:0], bufferB[2][2:0]};
        2'b10: out = {9{16'b0000_0000_0000_0000}};
        2'b11: out = {bufferA[0][2:0], bufferA[1][2:0], bufferA[2][2:0]};
        endcase
    end

    always_ff@(posedge CLK or negedge RST_N) begin : bufferA_Selection
        if(!RST_N) begin
            bufferA[0] <= {32{16'b0000_0000_0000_0000}};
            bufferA[1] <= {32{16'b0000_0000_0000_0000}};
            bufferA[2] <= {32{16'b0000_0000_0000_0000}};
        end
        else begin
            case(MPB_In_Sel)
                2'b00: begin
                    if(MPB_In_Ready) begin
                        bufferA[0][7:0] <= {in[0], bufferA[0][7:1]};
                        bufferA[0][15:8] <= {in[1], bufferA[0][15:9]};
                        bufferA[0][23:16] <= {in[2], bufferA[0][23:17]};
                        bufferA[0][31:24] <= {in[3], bufferA[0][31:25]};
                        bufferA[1] <= bufferA[1];
                        bufferA[2] <= bufferA[2];
                    end
                    else begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1] <= bufferA[1];
                        bufferA[2] <= bufferA[2];
                    end
                end
                2'b01: begin
                    if(MPB_In_Ready) begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1][7:0] <= {in[0], bufferA[1][7:1]};
                        bufferA[1][15:8] <= {in[1], bufferA[1][15:9]};
                        bufferA[1][23:16] <= {in[2], bufferA[1][23:17]};
                        bufferA[1][31:24] <= {in[3], bufferA[1][31:25]};
                        bufferA[2] <= bufferA[2];
                    end
                    else begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1] <= bufferA[1];
                        bufferA[2] <= bufferA[2];
                    end
                end
                2'b10: begin
                    if(MPB_In_Ready) begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1] <= bufferA[1];
                        bufferA[2][7:0] <= {in[0], bufferA[2][7:1]};
                        bufferA[2][15:8] <= {in[1], bufferA[2][15:9]};
                        bufferA[2][23:16] <= {in[2], bufferA[2][23:17]};
                        bufferA[2][31:24] <= {in[3], bufferA[2][31:25]};
                    end
                    else begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1] <= bufferA[1];
                        bufferA[2] <= bufferA[2];
                    end
                end
                2'b11: begin
                    if(MPB_Out_Ready) begin
                        bufferA[0] <= {16'b0000_0000_0000_0000, 16'b0000_0000_0000_0000, bufferA[0][31:2]};
                        bufferA[1] <= {16'b0000_0000_0000_0000, 16'b0000_0000_0000_0000, bufferA[1][31:2]};
                        bufferA[2] <= {16'b0000_0000_0000_0000, 16'b0000_0000_0000_0000, bufferA[2][31:2]};
                    end
                    /*
                    else if(MPB_In_Ready) begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1] <= bufferA[1];
                        bufferA[2][7:0] <= {in[0], bufferA[2][7:1]};
                        bufferA[2][15:8] <= {in[1], bufferA[2][15:9]};
                        bufferA[2][23:16] <= {in[2], bufferA[2][23:17]};
                        bufferA[2][31:24] <= {in[3], bufferA[2][31:25]};
                    end
                    */
                    else begin
                        bufferA[0] <= bufferA[0];
                        bufferA[1] <= bufferA[1];
                        bufferA[2] <= bufferA[2];
                    end
                end
            endcase
        end
    end

    always_ff@(posedge CLK or negedge RST_N) begin : bufferB_Selection
        if(!RST_N) begin
            bufferB[0] <= {32{16'b0000_0000_0000_0000}};
            bufferB[1] <= {32{16'b0000_0000_0000_0000}};
            bufferB[2] <= {32{16'b0000_0000_0000_0000}};
        end
        else begin
            case(MPB_In_Sel)
                2'b00: begin
                    if(MPB_In_Ready) begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1] <= bufferB[1];
                        bufferB[2][7:0] <= {in[0], bufferB[2][7:1]};
                        bufferB[2][15:8] <= {in[1], bufferB[2][15:9]};
                        bufferB[2][23:16] <= {in[2], bufferB[2][23:17]};
                        bufferB[2][31:24] <= {in[3], bufferB[2][31:25]};
                    end
                    else begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1] <= bufferB[1];
                        bufferB[2] <= bufferB[2];
                    end
                end
                2'b01: begin
                    if(MPB_Out_Ready) begin
                        bufferB[0] <= {16'b0000_0000_0000_0000, 16'b0000_0000_0000_0000, bufferB[0][31:2]};
                        bufferB[1] <= {16'b0000_0000_0000_0000, 16'b0000_0000_0000_0000, bufferB[1][31:2]};
                        bufferB[2] <= {16'b0000_0000_0000_0000, 16'b0000_0000_0000_0000, bufferB[2][31:2]};
                    end
                    /*
                    else if(MPB_In_Ready) begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1] <= bufferB[1];
                        bufferB[2][7:0] <= {in[0], bufferB[2][7:1]};
                        bufferB[2][15:8] <= {in[1], bufferB[2][15:9]};
                        bufferB[2][23:16] <= {in[2], bufferB[2][23:17]};
                        bufferB[2][31:24] <= {in[3], bufferB[2][31:25]};
                    end
                    */
                    else begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1] <= bufferB[1];
                        bufferB[2] <= bufferB[2];
                    end
                end
                2'b10: begin
                    if(MPB_In_Ready) begin
                        bufferB[0][7:0] <= {in[0], bufferB[0][7:1]};
                        bufferB[0][15:8] <= {in[1], bufferB[0][15:9]};
                        bufferB[0][23:16] <= {in[2], bufferB[0][23:17]};
                        bufferB[0][31:24] <= {in[3], bufferB[0][31:25]};
                        bufferB[1] <= bufferB[1];
                        bufferB[2] <= bufferB[2];
                    end
                    else begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1] <= bufferB[1];
                        bufferB[2] <= bufferB[2];
                    end
                end
                2'b11: begin
                    if(MPB_In_Ready) begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1][7:0] <= {in[0], bufferB[1][7:1]};
                        bufferB[1][15:8] <= {in[1], bufferB[1][15:9]};
                        bufferB[1][23:16] <= {in[2], bufferB[1][23:17]};
                        bufferB[1][31:24] <= {in[3], bufferB[1][31:25]};
                        bufferB[2] <= bufferB[2];
                    end
                    else begin
                        bufferB[0] <= bufferB[0];
                        bufferB[1] <= bufferB[1];
                        bufferB[2] <= bufferB[2];
                    end
                end
            endcase
        end
    end

endmodule