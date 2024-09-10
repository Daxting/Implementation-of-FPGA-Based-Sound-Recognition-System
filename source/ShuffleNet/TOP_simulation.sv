 module entity(
    input            clk_125,
    input wire       RST_N,
    input wire       sample_clk_48k,
    input wire[15:0] audio_input_signal,

    output           LED1, LED2, LED3, LED4_b, LED5_b
 );
    wire            clk_25, clk_100;
    wire[15:0]      buffer_output;
    wire            log10_result_Rready, log10_result_Wready;
    wire [15:0]     log10_result;
    wire            fftoff;
    wire            Result;
    wire            shuffleNet_Result_Ready;
    wire[5:0]       Stage;
    wire            select_bramA;
    reg             result_reg;

    assign LED1 =   |(buffer_output[15:4]) && !(&(buffer_output[15:4]));
    assign LED2 =   fftoff;
    assign LED3 =   select_bramA;
    assign LED4_b = shuffleNet_Result_Ready;
    assign LED5_b = result_reg;


    always @(posedge clk_25 or negedge RST_N) begin
        if(!RST_N) result_reg <= 1'b0;
        else begin
            if(Stage == 6'd38) result_reg <= Result;
            else result_reg <= result_reg;
        end
    end


    clk_wiz_0 clk_wiz_0(
        // Clock out ports
        .CLK_25(clk_25),
        .CLK_100(clk_100),
        // Status and control signals
        .resetn(RST_N),
        // Clock in ports
        .CLK_125(clk_125)
    );
    wire new_sample;

    wire[2:0]       wea;
    wire[1:0]       select; // select bram
    wire[8:0]       bram_A_in_addr;
    wire[15:0]      bram_A_in_data;
    wire[8:0]       bram_A_out_addr;
    wire[15:0]      bram_A_out_data;
    wire[8:0]       bram_B_in_addr;
    wire[15:0]      bram_B_in_data;
    wire[8:0]       bram_B_out_addr;
    wire[15:0]      bram_B_out_data;
    wire[8:0]       bram_C_in_addr;
    wire[15:0]      bram_C_in_data;
    wire[8:0]       bram_C_out_addr;
    wire[15:0]      bram_C_out_data;
    
    audio_input audio_input0(
        .RST_N(RST_N),
        .new_sample(new_sample),
        .sample_clk_48k(sample_clk_48k),
        .audio_input_signal(audio_input_signal),
        .wea(wea),
        .select(select),
        .bram_A_in_addr(bram_A_in_addr),
        .bram_A_in_data(bram_A_in_data),
        .bram_B_in_addr(bram_B_in_addr),
        .bram_B_in_data(bram_B_in_data),
        .bram_C_in_addr(bram_C_in_addr),
        .bram_C_in_data(bram_C_in_data)
    );

    sound_buffer_bram bram_A(
        .clka(sample_clk_48k),
        .wea(wea[0]),
        .addra(bram_A_in_addr),
        .dina(bram_A_in_data),
        .clkb(clk_25),
        .addrb(bram_A_out_addr),
        .doutb(bram_A_out_data)
    );

    sound_buffer_bram bram_B(
        .clka(sample_clk_48k),
        .wea(wea[1]),
        .addra(bram_B_in_addr),
        .dina(bram_B_in_data),
        .clkb(clk_25),
        .addrb(bram_B_out_addr),
        .doutb(bram_B_out_data)
    );
    
    sound_buffer_bram bram_C(
        .clka(sample_clk_48k),
        .wea(wea[2]),
        .addra(bram_C_in_addr),
        .dina(bram_C_in_data),
        .clkb(clk_25),
        .addrb(bram_C_out_addr),
        .doutb(bram_C_out_data)
    );

    wire[15:0]      sound_input;
    assign sound_input = buffer_output;
    wire[8:0]       bram_addr; // bram address
    wire            bram_A_enable; // bram A enable
    wire            bram_B_enable; // bram B enable
    wire            bram_C_enable; // bram C enable
    wire            bram_write_enable; // write = 1, read = 0 


    sound_buffer_output_selector sound_buffer_output_selector(
        .RST_N(RST_N),
        .bram_A_enable(bram_A_enable),
        .bram_B_enable(bram_B_enable),
        .bram_C_enable(bram_C_enable),
        .bram_addr(bram_addr),
        .bram_A_out_addr(bram_A_out_addr),
        .bram_B_out_addr(bram_B_out_addr),
        .bram_C_out_addr(bram_C_out_addr),
        .bram_A_out_data(bram_A_out_data),
        .bram_B_out_data(bram_B_out_data),
        .bram_C_out_data(bram_C_out_data),
        .buffer_output(buffer_output)
    );

    SignalPreAnalysis SignalPreAnalysisU0(
        .clk(clk_25),
        .reset(RST_N),
        .select(select),
        .sound_input(sound_input),
        .log10_result_Wready(log10_result_Wready),
        .bram_addr(bram_addr),
        .bram_A_enable(bram_A_enable),
        .bram_B_enable(bram_B_enable),
        .bram_C_enable(bram_C_enable),
        .bram_write_enable(bram_write_enable),
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
