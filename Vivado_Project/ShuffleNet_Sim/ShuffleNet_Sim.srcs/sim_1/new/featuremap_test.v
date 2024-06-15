`timescale 1ns / 1ps

module featuremap_test();
    
    wire Result;
    wire shuffleNet_Result_Ready;
    wire [5:0] Stage;             
    wire log10_result_Wready;
    wire select_bramA;
    
    reg log10_result_Rready;
    reg [15:0] log10_result;
    reg clk;
    reg reset;
    
    ShuffleNetCombine ShuffleNetCombine_0(
                                            .Result(Result),
                                            .shuffleNet_Result_Ready(shuffleNet_Result_Ready),
                                            .Stage(Stage),
                                            .log10_result_Wready(log10_result_Wready),
                                            .log10_result_Rready(log10_result_Rready),
                                            .log10_result(log10_result),
                                            .clk(clk),
                                            .reset(reset),
                                            .select_bramA(select_bramA)
                                          );
    
    initial begin
        clk=1'b1;
        forever #5 clk=~clk;
    end 
    
    initial begin
        #100;   reset=1'b1;
        #10;     reset=1'b0; log10_result_Rready = 1'b0;log10_result = 16'b0;
        #10;     reset=1'b1; 
        forever  #400 log10_result_Rready = ~log10_result_Rready;
    end
    
    initial begin
        #8000000; $finish;
    end
endmodule
