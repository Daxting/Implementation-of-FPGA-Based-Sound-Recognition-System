module memory_control(
    //general port
    input wire clk,
    input wire rst_n,
    //mfsc port
    input wire mfsc_result_Rready,
    output wire mfsc_result_Wready,     
    input wire [15:0] mfsc_result_data,
    // FSM port
    output wire feature_map_ready,             
    input wire write_featuremap_enable,      
    input wire read_featuremap_enable,       
    input wire read_kernel_enable,           
    input wire [5:0]stage_count_next,
    input wire [5:0]stage_count,        
    input wire [6:0]kernel_count_7bit_next,  
    input wire shuffleNet_Result_Ready,
    // ShuffleNet port (from 3 to 1)
    input  wire[63:0]    shuffleNet_output_bus,  
    output wire[63:0]    shuffleNet_input_bus,   
    output wire[63:0]    shuffleNet_inputB_bus,  
    output wire[319:0]   weight_bus,
    output  wire          select_bramA         
);


    wire [10:0] bram_A0_in_addr;     
    wire [15:0] bram_A0_in_data;     
    wire bram_A0_in_we;              
    wire [10:0] bram_A0_out_addr;    
    wire [15:0] bram_A0_out_data;
    wire [10:0] bram_A1_in_addr;     
    wire [15:0] bram_A1_in_data;     
    wire bram_A1_in_we;              
    wire [10:0] bram_A1_out_addr;   
    wire [15:0] bram_A1_out_data;
    wire [10:0] bram_A2_in_addr;     
    wire [15:0] bram_A2_in_data;     
    wire bram_A2_in_we;              
    wire [10:0] bram_A2_out_addr;    
    wire [15:0] bram_A2_out_data;
    wire [10:0] bram_A3_in_addr;     
    wire [15:0] bram_A3_in_data;     
    wire bram_A3_in_we;              
    wire [10:0] bram_A3_out_addr;    
    wire [15:0] bram_A3_out_data;
    wire [10:0] bram_C0_in_addr;     
    wire [15:0] bram_C0_in_data;     
    wire bram_C0_in_we;              
    wire [10:0] bram_C0_out_addr;    
    wire [15:0] bram_C0_out_data;
    wire [10:0] bram_C1_in_addr;     
    wire [15:0] bram_C1_in_data;     
    wire bram_C1_in_we;              
    wire [10:0] bram_C1_out_addr;    
    wire [15:0] bram_C1_out_data;
    wire [10:0] bram_C2_in_addr;     
    wire [15:0] bram_C2_in_data;     
    wire bram_C2_in_we;              
    wire [10:0] bram_C2_out_addr;    
    wire [15:0] bram_C2_out_data;
    wire [10:0] bram_C3_in_addr;     
    wire [15:0] bram_C3_in_data;     
    wire bram_C3_in_we;              
    wire [10:0] bram_C3_out_addr;    
    wire [15:0] bram_C3_out_data;
    wire [9:0] bram_B0_in_addr;      
    wire [15:0] bram_B0_in_data;     
    wire bram_B0_in_we;              
    wire [9:0] bram_B0_out_addr;     
    wire [15:0] bram_B0_out_data;
    wire [9:0] bram_B1_in_addr;         
    wire [15:0] bram_B1_in_data;        
    wire bram_B1_in_we;                 
    wire [9:0] bram_B1_out_addr;       
    wire [15:0] bram_B1_out_data;
    wire [9:0] bram_B2_in_addr;        
    wire [15:0] bram_B2_in_data;        
    wire bram_B2_in_we;                 
    wire [9:0] bram_B2_out_addr;        
    wire [15:0] bram_B2_out_data;
    wire [9:0] bram_B3_in_addr;         
    wire [15:0] bram_B3_in_data;        
    wire bram_B3_in_we;                 
    wire [9:0] bram_B3_out_addr;        
    wire [15:0] bram_B3_out_data;
    // kernel
    wire [8:0] read_kernel_addr;
    wire [79:0] kernel_0_out_data;
    wire [79:0] kernel_1_out_data;
    wire [79:0] kernel_2_out_data;   
    wire [79:0] kernel_3_out_data;
    // constant_for_kernel
    wire kernel_write_enable;       
    wire [79:0]kernel_write_in_data;

    
    BRAM_A_0 BRAM_A0(
        .clka(clk),
        .wea(bram_A0_in_we),
        .addra(bram_A0_in_addr),
        .dina(bram_A0_in_data),
        .clkb(clk),
        .addrb(bram_A0_out_addr),
        .doutb(bram_A0_out_data)
    );
    BRAM_A_1 BRAM_A1(
        .clka(clk),
        .wea(bram_A1_in_we),
        .addra(bram_A1_in_addr),
        .dina(bram_A1_in_data),
        .clkb(clk),
        .addrb(bram_A1_out_addr),
        .doutb(bram_A1_out_data)
    );
    BRAM_A_2 BRAM_A2(
        .clka(clk),
        .wea(bram_A2_in_we),
        .addra(bram_A2_in_addr),
        .dina(bram_A2_in_data),
        .clkb(clk),
        .addrb(bram_A2_out_addr),
        .doutb(bram_A2_out_data)
    );
    BRAM_A_3 BRAM_A3(
        .clka(clk),
        .wea(bram_A3_in_we),
        .addra(bram_A3_in_addr),
        .dina(bram_A3_in_data),
        .clkb(clk),
        .addrb(bram_A3_out_addr),
        .doutb(bram_A3_out_data)
    );
    BRAM_C_0 BRAM_C0(
        .clka(clk),
        .wea(bram_C0_in_we),
        .addra(bram_C0_in_addr),
        .dina(bram_C0_in_data),
        .clkb(clk),
        .addrb(bram_C0_out_addr),
        .doutb(bram_C0_out_data)
    );
    BRAM_C_1 BRAM_C1(
        .clka(clk),
        .wea(bram_C1_in_we),
        .addra(bram_C1_in_addr),
        .dina(bram_C1_in_data),
        .clkb(clk),
        .addrb(bram_C1_out_addr),
        .doutb(bram_C1_out_data)
    );
    BRAM_C_2 BRAM_C2(
        .clka(clk),
        .wea(bram_C2_in_we),
        .addra(bram_C2_in_addr),
        .dina(bram_C2_in_data),
        .clkb(clk),
        .addrb(bram_C2_out_addr),
        .doutb(bram_C2_out_data)
    );
    BRAM_C_3 BRAM_C3(
        .clka(clk),
        .wea(bram_C3_in_we),
        .addra(bram_C3_in_addr),
        .dina(bram_C3_in_data),
        .clkb(clk),
        .addrb(bram_C3_out_addr),
        .doutb(bram_C3_out_data)
    );

    BRAM_B BRAM_B0(
        .clka(clk),
        .wea(bram_B0_in_we),
        .addra(bram_B0_in_addr),
        .dina(bram_B0_in_data),
        .clkb(clk),
        .addrb(bram_B0_out_addr),
        .doutb(bram_B0_out_data)
    );
    BRAM_B BRAM_B1(
        .clka(clk),
        .wea(bram_B1_in_we),
        .addra(bram_B1_in_addr),
        .dina(bram_B1_in_data),
        .clkb(clk),
        .addrb(bram_B1_out_addr),
        .doutb(bram_B1_out_data)
    );
    BRAM_B BRAM_B2(
        .clka(clk),
        .wea(bram_B2_in_we),
        .addra(bram_B2_in_addr),
        .dina(bram_B2_in_data),
        .clkb(clk),
        .addrb(bram_B2_out_addr),
        .doutb(bram_B2_out_data)
    );
    BRAM_B BRAM_B3(
        .clka(clk),
        .wea(bram_B3_in_we),
        .addra(bram_B3_in_addr),
        .dina(bram_B3_in_data),
        .clkb(clk),
        .addrb(bram_B3_out_addr),
        .doutb(bram_B3_out_data)
    );

    kernel_0 kernel_0(
        .clka(clk),
        .wea(kernel_write_enable),
        .addra(read_kernel_addr),
        .dina(kernel_write_in_data),
        .douta(kernel_0_out_data)
    );
    kernel_1 kernel_1(
        .clka(clk),
        .wea(kernel_write_enable),
        .addra(read_kernel_addr),
        .dina(kernel_write_in_data),
        .douta(kernel_1_out_data)
    );
    kernel_2 kernel_2(
        .clka(clk),
        .wea(kernel_write_enable),
        .addra(read_kernel_addr),
        .dina(kernel_write_in_data),
        .douta(kernel_2_out_data)
    );
    kernel_3 kernel_3(
        .clka(clk),
        .wea(kernel_write_enable),
        .addra(read_kernel_addr),
        .dina(kernel_write_in_data),
        .douta(kernel_3_out_data)
    );


    memory_control_private_ip_test memory_control_private_ip(
        //general port
        .clk(clk),
        .rst_n(rst_n),
        //mfsc port
        .mfsc_result_Rready(mfsc_result_Rready),
        .mfsc_result_Wready(mfsc_result_Wready),         
        .mfsc_result_data(mfsc_result_data),
        // bram_A0
        .bram_A0_in_addr(bram_A0_in_addr),     
        .bram_A0_in_data(bram_A0_in_data),    
        .bram_A0_in_we(bram_A0_in_we),             
        .bram_A0_out_addr(bram_A0_out_addr),   
        .bram_A0_out_data(bram_A0_out_data),
        // bram_A1  
        .bram_A1_in_addr(bram_A1_in_addr),    
        .bram_A1_in_data(bram_A1_in_data),    
        .bram_A1_in_we(bram_A1_in_we),            
        .bram_A1_out_addr(bram_A1_out_addr),   
        .bram_A1_out_data(bram_A1_out_data),
        // bram_A2
        .bram_A2_in_addr(bram_A2_in_addr),    
        .bram_A2_in_data(bram_A2_in_data),     
        .bram_A2_in_we(bram_A2_in_we),           
        .bram_A2_out_addr(bram_A2_out_addr),   
        .bram_A2_out_data(bram_A2_out_data),
        // bram_A3
        .bram_A3_in_addr(bram_A3_in_addr),   
        .bram_A3_in_data(bram_A3_in_data),    
        .bram_A3_in_we(bram_A3_in_we),             
        .bram_A3_out_addr(bram_A3_out_addr),    
        .bram_A3_out_data(bram_A3_out_data),
        // bram_C0
        .bram_C0_in_addr(bram_C0_in_addr),     
        .bram_C0_in_data(bram_C0_in_data),     
        .bram_C0_in_we(bram_C0_in_we),              
        .bram_C0_out_addr(bram_C0_out_addr),   
        .bram_C0_out_data(bram_C0_out_data),
        // bram_C1
        .bram_C1_in_addr(bram_C1_in_addr),     
        .bram_C1_in_data(bram_C1_in_data),    
        .bram_C1_in_we(bram_C1_in_we),           
        .bram_C1_out_addr(bram_C1_out_addr),   
        .bram_C1_out_data(bram_C1_out_data),
        // bram_C2
        .bram_C2_in_addr(bram_C2_in_addr),     
        .bram_C2_in_data(bram_C2_in_data),   
        .bram_C2_in_we(bram_C2_in_we),             
        .bram_C2_out_addr(bram_C2_out_addr),   
        .bram_C2_out_data(bram_C2_out_data),
        // bram_C3
        .bram_C3_in_addr(bram_C3_in_addr),     
        .bram_C3_in_data(bram_C3_in_data),     
        .bram_C3_in_we(bram_C3_in_we),             
        .bram_C3_out_addr(bram_C3_out_addr),    
        .bram_C3_out_data(bram_C3_out_data),
        // bram_B0
        .bram_B0_in_addr(bram_B0_in_addr),        
        .bram_B0_in_data(bram_B0_in_data),        
        .bram_B0_in_we(bram_B0_in_we),             
        .bram_B0_out_addr(bram_B0_out_addr),       
        .bram_B0_out_data(bram_B0_out_data),
        // bram_B1
        .bram_B1_in_addr(bram_B1_in_addr),         
        .bram_B1_in_data(bram_B1_in_data),        
        .bram_B1_in_we(bram_B1_in_we),            
        .bram_B1_out_addr(bram_B1_out_addr),      
        .bram_B1_out_data(bram_B1_out_data),
        // bram_B2
        .bram_B2_in_addr(bram_B2_in_addr),        
        .bram_B2_in_data(bram_B2_in_data),        
        .bram_B2_in_we(bram_B2_in_we),            
        .bram_B2_out_addr(bram_B2_out_addr),      
        .bram_B2_out_data(bram_B2_out_data),
        // bram_B3
        .bram_B3_in_addr(bram_B3_in_addr),        
        .bram_B3_in_data(bram_B3_in_data),        
        .bram_B3_in_we(bram_B3_in_we),             
        .bram_B3_out_addr(bram_B3_out_addr),       
        .bram_B3_out_data(bram_B3_out_data),
        // kernel
        .read_kernel_addr(read_kernel_addr),       
        .kernel_0_out_data(kernel_0_out_data),
        .kernel_1_out_data(kernel_1_out_data),
        .kernel_2_out_data(kernel_2_out_data),   
        .kernel_3_out_data(kernel_3_out_data),
        // constant_for_kernel
        .kernel_write_enable(kernel_write_enable),       
        .kernel_write_in_data(kernel_write_in_data),     
        // FSM port
        .feature_map_ready(feature_map_ready),           
        .write_featuremap_enable(write_featuremap_enable),      
        .read_featuremap_enable(read_featuremap_enable),       
        .read_kernel_enable(read_kernel_enable),           
        .stage_count_next(stage_count_next),        
        .stage_count(stage_count),
        .kernel_count_7bit_next(kernel_count_7bit_next),  
        .shuffleNet_Result_Ready(shuffleNet_Result_Ready),
        // ShuffleNet port (from 3 to 1)
        .shuffleNet_output_bus(shuffleNet_output_bus),  
        .shuffleNet_input_bus(shuffleNet_input_bus),   
        .shuffleNet_inputB_bus(shuffleNet_inputB_bus), 
        .weight_bus(weight_bus),
        .select_bramA(select_bramA)
    );                     

endmodule
