`timescale 1ns / 1ns

 module TOP(
    input           clk_125,

    // I2S
    output          AC_ADR0,
    output          AC_ADR1,
    output          AC_GPIO0,
    input           AC_GPIO1,
    input           AC_GPIO2,
    input           AC_GPIO3,
    output          AC_MCLK,

    // I2C
    output          AC_SCK,
    inout           AC_SDA,

    output          LED0, LED1, LED2, LED3, LED4_b, LED5_b
 );
    wire            clk_48, clk_25, clk_100;
    wire            RST_N;
    wire            LOCKED;

    reg[23:0]       hphone_l;
    reg             hphone_l_valid;
    reg[23:0]       hphone_r;
    reg             hphone_r_valid;
    wire[23:0]      line_in_l;
    wire[23:0]      line_in_r;
    wire            sample_clk_48k;
    wire            new_sample;
    wire[15:0]      buffer_output;
    wire            sound_input_Rready, sound_input_Wready;
    wire            log10_result_Rready, log10_result_Wready;
    wire [15:0]     log10_result;
    wire            fftoff;
    wire            Result;
    wire            shuffleNet_Result_Ready;
    wire[5:0]       Stage;

    wire            select_bramA;

    reg             result_reg;

    assign LED0 =   |(line_in_l) && !(&(line_in_l));
    assign LED1 =   |(buffer_output[15:4]) && !(&(buffer_output[15:4]));
    assign LED2 =   fftoff;
    assign LED3 =   select_bramA;
    assign LED4_b = shuffleNet_Result_Ready;
    assign LED5_b = result_reg;

    assign RST_N = 1'b1;

    always @(posedge clk_25 or negedge RST_N) begin
        if(!RST_N) result_reg <= 1'b0;
        else begin
            if(Stage == 6'd38) result_reg <= Result;
            else result_reg <= result_reg;
        end
    end

    audio_top audio_top0(    
        .clk_100(clk_100),      
        .AC_ADR0(AC_ADR0),
        .AC_ADR1(AC_ADR1),
        .AC_GPIO0(AC_GPIO0),
        .AC_GPIO1(AC_GPIO1),
        .AC_GPIO2(AC_GPIO2),
        .AC_GPIO3(AC_GPIO3),
        .AC_MCLK(AC_MCLK),        
        .AC_SCK(AC_SCK),
        .AC_SDA(AC_SDA),        
        .line_in_l(line_in_l),
        .line_in_r(line_in_r),      
        .new_sample(new_sample),
        .sample_clk_48k(sample_clk_48k)
    );

    clk_wiz_0 clk_wiz_0(
        // Clock out ports
        .CLK_25(clk_25),
        .CLK_100(clk_100),
        // Status and control signals
        .resetn(RST_N),
        // Clock in ports
        .CLK_125(clk_125)
    );

    buffer_design buffer_design(
        .clk(clk_100),
        .reset(RST_N),
        .sample_clk_48k(sample_clk_48k),
        .new_sample(new_sample),
        .line_in_l(line_in_l),
        .w_ready(sound_input_Wready),
        .r_ready(sound_input_Rready),
        .audio_output(buffer_output)
    );

    SignalPreAnalysis SignalPreAnalysisU0(
        .clk(clk_25),
        .reset(RST_N),
        .sound_input_Rready(sound_input_Rready),
        .sound_input(buffer_output),
        .log10_result_Wready(log10_result_Wready),
        .sound_input_Wready(sound_input_Wready),
        .log10_result(log10_result),
        .log10_result_Rready(log10_result_Rready),
        .fftoff(fftoff)
    );

    ShuffleNetCombine ShuffleNetCombine(
        .Result(Result),
        .shuffleNet_Result_Ready(shuffleNet_Result_Ready),
        .Stage(Stage),
        .log10_result_Wready(log10_result_Wready),
        .log10_result_Rready(log10_result_Rready),
        .log10_result(log10_result),
        .clk(clk_25), 
        .reset(RST_N),
        .select_bramA(select_bramA)
    );

endmodule
