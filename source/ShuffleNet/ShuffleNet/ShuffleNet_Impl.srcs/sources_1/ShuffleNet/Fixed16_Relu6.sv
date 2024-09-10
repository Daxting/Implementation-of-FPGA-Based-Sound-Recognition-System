`timescale 1ns / 1ns
// Fixed16ªºRelu6
module Fixed16_Relu6 (
    output  logic[15:0] out,
    input   logic[15:0] in
);

    always_comb begin
        if(in[15] == 1'b1) out = 16'b0000_0000_0000_0000; // 0
        else if(in[14] | in[13]) out = 16'b0001_1000_0000_0000; // 6
        else if(in[11] & in[12]) out = 16'b0001_1000_0000_0000; // 6
        else out = in;
    end
endmodule