module initial_mux(
input wire [15:0]A_data,
input wire [15:0]B_data,
input wire [10:0]A_addr,
input wire [10:0]B_addr,
input wire A_write_enable,
input wire B_write_enable,
input wire select_A,
output reg [10:0]addr,
output reg [15:0]data,
output reg write_enable
);
    always @(*)begin
        if(select_A==1'b1)begin
            write_enable = A_write_enable;
            data = A_data;
            addr = A_addr;
        end
        else begin
            write_enable = B_write_enable;
            data = B_data;
            addr = B_addr;
        end
    end
endmodule


module mux2(
input wire [15:0]A_data,
input wire [15:0]B_data,
input wire select_A,
output reg [15:0]data
);
    always @(*)begin
        if(select_A==1'b1)begin
            data = A_data;
        end
        else begin
            data = B_data;
        end
    end
endmodule 

module mux4_reverse_sequence(
input wire [79:0] input_data_0,
input wire [79:0] input_data_1,
input wire [79:0] input_data_2,
input wire [79:0] input_data_3,
input wire [1:0] select_data,
output reg [79:0] output_data
);
wire [79:0] output_data_0;
wire [79:0] output_data_1;
wire [79:0] output_data_2;
wire [79:0] output_data_3;
assign output_data_0 = {input_data_0[15:0], input_data_0[31:16], input_data_0[47:32],input_data_0[63:48], input_data_0[79:64]};
assign output_data_1 = {input_data_1[15:0], input_data_1[31:16], input_data_1[47:32],input_data_1[63:48], input_data_1[79:64]};
assign output_data_2 = {input_data_2[15:0], input_data_2[31:16], input_data_2[47:32],input_data_2[63:48], input_data_2[79:64]};
assign output_data_3 = {input_data_3[15:0], input_data_3[31:16], input_data_3[47:32],input_data_3[63:48], input_data_3[79:64]};
    always @(*)begin
        case (select_data)
            2'b11: output_data = output_data_3;
            2'b10: output_data = output_data_2;
            2'b01: output_data = output_data_1;
            2'b00: output_data = output_data_0;
            default:output_data = 80'd0;
        endcase
    end
endmodule 


module mux8(
input wire [15:0] input_data_0,
input wire [15:0] input_data_1,
input wire [15:0] input_data_2,
input wire [15:0] input_data_3,
input wire [15:0] input_data_4,
input wire [15:0] input_data_5,
input wire [15:0] input_data_6,
input wire [15:0] input_data_7,
input wire [2:0] select_data,
output reg [15:0] output_data
);
    always @(*)begin
        case (select_data)
            3'b111: output_data = input_data_7;
            3'b110: output_data = input_data_6;
            3'b101: output_data = input_data_5;
            3'b100: output_data = input_data_4;
            3'b011: output_data = input_data_3;
            3'b010: output_data = input_data_2;
            3'b001: output_data = input_data_1;
            3'b000: output_data = input_data_0;
            default:output_data = 16'd0;
        endcase
    end
endmodule 
