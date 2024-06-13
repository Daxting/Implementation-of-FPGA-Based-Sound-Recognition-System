module buffer_design (
    input wire clk,
    input wire reset,
    input wire new_sample,
    input wire sample_clk_48k,
    input wire [23:0] line_in_l,
    input wire w_ready,
    output reg r_ready,
    output reg [15:0] audio_output
);

    always @(posedge sample_clk_48k or negedge reset) begin: audio_output_control
        if(!reset) begin
            audio_output <= 16'b0;
        end
        else begin
            audio_output <= line_in_l[23:8];
        end
    end

    reg lock;
    always @(posedge clk or negedge reset) begin: r_ready_control
        if(!reset) begin
            r_ready <= 1'b0;
            lock <= 1'b0;
        end
        else if(w_ready && new_sample && !lock) begin
            r_ready <= 1'b1;
            lock <= 1'b1;
        end
        else if(!w_ready)begin
            r_ready <= 1'b1;
            lock <= 1'b0;
        end
        else if(w_ready && !new_sample && !lock) begin
            r_ready <= 1'b0;
            lock <= 1'b0;
        end
        else begin
            r_ready <= r_ready;
            lock <= lock;
        end
    end
endmodule