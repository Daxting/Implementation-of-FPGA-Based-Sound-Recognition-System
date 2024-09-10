`timescale 1ns / 1ns
// 3*3³Ì¤j¦À¤Æ¼h
module MaxPool33(
    output  logic   signed[15:0]        out,
    input   logic   signed[8:0][15:0]   in
);

    logic   signed[7:0][15:0]   comp_result;

    assign comp_result[0] = ( in[0] > in[1] ) ? in[0] : in[1];
    assign comp_result[1] = ( in[2] > in[3] ) ? in[2] : in[3];
    assign comp_result[2] = ( in[4] > in[5] ) ? in[4] : in[5];
    assign comp_result[3] = ( in[6] > in[7] ) ? in[6] : in[7];
    assign comp_result[4] = ( comp_result[1] > comp_result[2] ) ? comp_result[1] : comp_result[2];
    assign comp_result[5] = ( comp_result[3] > in[8] ) ? comp_result[3] : in[8];
    assign comp_result[6] = ( comp_result[0] > comp_result[4] ) ? comp_result[0] : comp_result[4];
    assign comp_result[7] = ( comp_result[5] > comp_result[6] ) ? comp_result[5] : comp_result[6];
    assign out = comp_result[7];

endmodule