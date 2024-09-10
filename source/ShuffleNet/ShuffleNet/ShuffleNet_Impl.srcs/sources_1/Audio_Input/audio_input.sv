module audio_input(
    input wire RST_N,
    input wire new_sample,
    input wire sample_clk_48k,
    input wire [15:0] audio_input_signal,//audio_output <= line_in_l[23:8]

    output reg [2:0] wea, //0 for bram_A, 1 for bram_B, 2 for bram_C
    output reg [1:0] select, // when A,B are done, select = 1, when B,C are done, select = 2, when A,C are done, select = 3
    output reg[8:0]  bram_A_in_addr,
    output reg[15:0] bram_A_in_data,
    output reg[8:0]  bram_B_in_addr,
    output reg[15:0] bram_B_in_data,
    output reg[8:0]  bram_C_in_addr,
    output reg[15:0] bram_C_in_data
);
    reg [10:0]   counter;// 11 bits counter
    //when counter[10:9] = 2'b00, write to bram_A, when counter[10:9] = 2'b01, write to bram_B, when counter[10:9] = 2'b10, write to bram_C

    always_ff @(posedge sample_clk_48k, negedge RST_N) begin: state_controller
        if(!RST_N)begin
            wea <= 3'b000;
            select <= 2'd0;
            counter <= 11'd0;
        end
        else begin
            if(counter[10:9] == 2'b00 && select == 2'd0) begin
                wea <= 3'b001;
                select <= 2'd0;
                counter <= counter + 11'd1;
                end
            else if(counter[10:9] == 2'b01 && select == 2'd0) begin
                wea <= 3'b010;
                select <= 2'd0;
                counter <= counter + 11'd1;
            end
            else if(counter[10:9] == 2'b10) begin
                wea <= 3'b100;
                select <= 2'd1;
                if(counter[8:0] == 9'b111111111) begin
                    counter <= 11'd0;
                end
                else begin
                    counter <= counter + 11'b1;
                end
            end
            else if(counter[10:9] == 2'b00) begin
                wea <= 3'b001;
                select <= 2'd2;
                counter <= counter + 11'd1;
            end
            else if(counter[10:9] == 2'b01) begin
                wea <= 3'b010;
                select <= 2'd3;
                counter <= counter + 11'd1;
            end
            else begin
                wea <= 3'b000;
                select <= 2'd0;
                counter <= 11'b11111111111;
            end
        end
    end

    always_comb begin : bram_in_controller
        if(!RST_N)begin
            bram_A_in_addr = 9'b0;
            bram_A_in_data = 16'b0;
            bram_B_in_addr = 9'b0;
            bram_B_in_data = 16'b0;
            bram_C_in_addr = 9'b0;
            bram_C_in_data = 16'b0;
        end
        else if(wea == 3'b001) begin
            bram_A_in_addr = counter[8:0];
            bram_A_in_data = audio_input_signal;
            bram_B_in_addr = 9'b0;
            bram_B_in_data = 16'b0;
            bram_C_in_addr = 9'b0;
            bram_C_in_data = 16'b0;
        end
        else if(wea == 3'b010) begin
            bram_A_in_addr = 9'b0;
            bram_A_in_data = 16'b0;
            bram_B_in_addr = counter[8:0];
            bram_B_in_data = audio_input_signal;
            bram_C_in_addr = 9'b0;
            bram_C_in_data = 16'b0;
        end
        else if(wea == 3'b100) begin
            bram_A_in_addr = 9'b0;
            bram_A_in_data = 16'b0;
            bram_B_in_addr = 9'b0;
            bram_B_in_data = 16'b0;
            bram_C_in_addr = counter[8:0];
            bram_C_in_data = audio_input_signal;
        end
        else begin
            bram_A_in_addr = 9'b0;
            bram_A_in_data = 16'b0;
            bram_B_in_addr = 9'b0;
            bram_B_in_data = 16'b0;
            bram_C_in_addr = 9'b0;
            bram_C_in_data = 16'b0;
        end
    end
endmodule

module sound_buffer_output_selector(
    input wire RST_N,
    input wire bram_A_enable,
    input wire bram_B_enable,
    input wire bram_C_enable,
    input wire [8:0] bram_addr,
    output reg [8:0] bram_A_out_addr,
    output reg [8:0] bram_B_out_addr,
    output reg [8:0] bram_C_out_addr,

    input wire [15:0] bram_A_out_data,
    input wire [15:0] bram_B_out_data,
    input wire [15:0] bram_C_out_data,
    output reg [15:0] buffer_output
);
    always_comb begin
        if(!RST_N)begin
            bram_A_out_addr = 9'b0;
            bram_B_out_addr = 9'b0;
            bram_C_out_addr = 9'b0;
            buffer_output = 16'b0;
        end
        else if(bram_A_enable) begin
            bram_A_out_addr = bram_addr;
            bram_B_out_addr = 9'b0;
            bram_C_out_addr = 9'b0;
            buffer_output = bram_A_out_data;
        end
        else if(bram_B_enable) begin
            bram_A_out_addr = 9'b0;
            bram_B_out_addr = bram_addr;
            bram_C_out_addr = 9'b0;
            buffer_output = bram_B_out_data;
        end
        else if(bram_C_enable) begin
            bram_A_out_addr = 9'b0;
            bram_B_out_addr = 9'b0;
            bram_C_out_addr = bram_addr;
            buffer_output = bram_C_out_data;
        end
        else begin
            bram_A_out_addr = 9'b0;
            bram_B_out_addr = 9'b0;
            bram_C_out_addr = 9'b0;
            buffer_output = 16'b0;
        end
    end
endmodule