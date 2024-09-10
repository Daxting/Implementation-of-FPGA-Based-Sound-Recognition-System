`timescale 1ns / 1ns

module ShuffleNetCombine(
    output      Result,
    output      shuffleNet_Result_Ready,
    output[5:0] Stage,
    output      log10_result_Wready,
    input       log10_result_Rready,
    input[15:0] log10_result,
    input       clk, reset,
    output      select_bramA
);

    // memory_control and FSM port
    wire        feature_map_ready;      
    wire        write_featuremap_enable;      
    wire        read_featuremap_enable;       
    wire        read_kernel_enable;           
    wire[5:0]   stage_count_next;        
    wire[6:0]   kernel_count_7bit_next;  
    //memory_control and shuffleNet port (from 3 to 1)
    wire[63:0]  shuffleNet_output_bus;  
    wire[63:0]  shuffleNet_input_bus;   
    wire[63:0]  shuffleNet_inputB_bus;  
    wire[319:0] weight_bus;


    memory_control memory_control_0(
        .clk(clk),
        .rst_n(reset),
        .mfsc_result_Rready(log10_result_Rready),
        .mfsc_result_Wready(log10_result_Wready),
        .mfsc_result_data(log10_result),
        .feature_map_ready(feature_map_ready),
        .write_featuremap_enable(write_featuremap_enable),
        .read_featuremap_enable(read_featuremap_enable),
        .read_kernel_enable(read_kernel_enable),
        .stage_count_next(stage_count_next),
        .stage_count(Stage),
        .kernel_count_7bit_next(kernel_count_7bit_next),
        .shuffleNet_Result_Ready(shuffleNet_Result_Ready),
        .shuffleNet_output_bus(shuffleNet_output_bus),
        .shuffleNet_input_bus(shuffleNet_input_bus),
        .shuffleNet_inputB_bus(shuffleNet_inputB_bus),
        .weight_bus(weight_bus),
        .select_bramA(select_bramA)
    );

    wire[6:0]           Kernel_Cnt;
    wire[6:0]           Step_Cnt;

    ShuffleNet shufflenet0(
        .Result_Ready(shuffleNet_Result_Ready),
        .Result(Result),
        .out_bus(shuffleNet_output_bus),
        .inA_bus(shuffleNet_input_bus), .inB_bus(shuffleNet_inputB_bus),
        .weight_bus(weight_bus),
        .Stage(Stage), .next_Stage(stage_count_next),
        .Kernel_Cnt(Kernel_Cnt), .next_Kernel_Cnt(kernel_count_7bit_next),
        .Step_Cnt(Step_Cnt),
        .Write_Require(write_featuremap_enable),
        .Kernel_Require(read_kernel_enable),
        .Input_Require_WP(read_featuremap_enable),
        .MFSC_Ready(feature_map_ready),
        .CLK(clk), .RST_N(reset)
    );
endmodule
