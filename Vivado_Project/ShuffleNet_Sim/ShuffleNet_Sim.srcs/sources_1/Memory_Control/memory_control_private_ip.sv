module memory_control_private_ip_test(
    //general port
    input logic clk,
    input logic rst_n,
    //mfsc port
    input logic mfsc_result_Rready,
    output logic mfsc_result_Wready,         
    input logic [15:0] mfsc_result_data,
    // bram_A0
    output logic [10:0] bram_A0_in_addr,     
    output logic [15:0] bram_A0_in_data,     
    output logic bram_A0_in_we,              
    output logic [10:0] bram_A0_out_addr,    
    input logic [15:0] bram_A0_out_data,
    // bram_A1 
    output logic [10:0] bram_A1_in_addr,     
    output logic [15:0] bram_A1_in_data,     
    output logic bram_A1_in_we,              
    output logic [10:0] bram_A1_out_addr,    
    input logic [15:0] bram_A1_out_data,
    // bram_A
    output logic [10:0] bram_A2_in_addr,     
    output logic [15:0] bram_A2_in_data,     
    output logic bram_A2_in_we,              
    output logic [10:0] bram_A2_out_addr,    
    input logic [15:0] bram_A2_out_data,
    // bram_A
    output logic [10:0] bram_A3_in_addr,     
    output logic [15:0] bram_A3_in_data,     
    output logic bram_A3_in_we,              
    output logic [10:0] bram_A3_out_addr,    
    input logic [15:0] bram_A3_out_data,
    // bram_C
    output logic [10:0] bram_C0_in_addr,     
    output logic [15:0] bram_C0_in_data,     
    output logic bram_C0_in_we,              
    output logic [10:0] bram_C0_out_addr,    
    input logic [15:0] bram_C0_out_data,
    // bram_C
    output logic [10:0] bram_C1_in_addr,     
    output logic [15:0] bram_C1_in_data,     
    output logic bram_C1_in_we,              
    output logic [10:0] bram_C1_out_addr,    
    input logic [15:0] bram_C1_out_data,
    // bram_C
    output logic [10:0] bram_C2_in_addr,     
    output logic [15:0] bram_C2_in_data,     
    output logic bram_C2_in_we,              
    output logic [10:0] bram_C2_out_addr,    
    input logic [15:0] bram_C2_out_data,
    // bram_C
    output logic [10:0] bram_C3_in_addr,     
    output logic [15:0] bram_C3_in_data,     
    output logic bram_C3_in_we,              
    output logic [10:0] bram_C3_out_addr,    
    input logic [15:0] bram_C3_out_data,
    // bram_B
    output logic [9:0] bram_B0_in_addr,      
    output logic [15:0] bram_B0_in_data,     
    output logic bram_B0_in_we,              
    output logic [9:0] bram_B0_out_addr,     
    input logic [15:0] bram_B0_out_data,
    // bram_B
    output logic [9:0] bram_B1_in_addr,      
    output logic [15:0] bram_B1_in_data,     
    output logic bram_B1_in_we,              
    output logic [9:0] bram_B1_out_addr,     
    input logic [15:0] bram_B1_out_data,
    // bram_B
    output logic [9:0] bram_B2_in_addr,      
    output logic [15:0] bram_B2_in_data,     
    output logic bram_B2_in_we,              
    output logic [9:0] bram_B2_out_addr,     
    input logic [15:0] bram_B2_out_data,
    // bram_B
    output logic [9:0] bram_B3_in_addr,      
    output logic [15:0] bram_B3_in_data,     
    output logic bram_B3_in_we,              
    output logic [9:0] bram_B3_out_addr,     
    input logic [15:0] bram_B3_out_data,
    // kerne
    output logic [8:0] read_kernel_addr,     
    input logic [79:0] kernel_0_out_data,
    input logic [79:0] kernel_1_out_data,
    input logic [79:0] kernel_2_out_data,  
    input logic [79:0] kernel_3_out_data,
    // constant_for_kerne
    output logic kernel_write_enable,        
    output logic [79:0]kernel_write_in_data, 
    // FSM por
    output logic feature_map_ready,          
    input logic write_featuremap_enable,     
    input logic read_featuremap_enable,      
    input logic read_kernel_enable,          
    input logic [5:0]stage_count_next,
    input logic [5:0]stage_count,       
    input logic [6:0]kernel_count_7bit_next,  
    input logic shuffleNet_Result_Ready,
    // ShuffleNet port (from 3 to 1)
    input  logic[63:0]    shuffleNet_output_bus,  
    output logic[63:0]    shuffleNet_input_bus,   
    output logic[63:0]    shuffleNet_inputB_bus,  
    output logic[319:0]   weight_bus,
    output  logic         select_bramA                      
);


logic [3:0] initial_write_enable_test;
assign initial_write_enable_test = 4'b0000;

// internal wires
logic [3:0] initial_write_enable;
logic [10:0] mfsc_bram_address_0;
logic [10:0] mfsc_bram_address_1;
logic [10:0] mfsc_bram_address_2;
logic [10:0] mfsc_bram_address_3;
//logic select_bramA; //-----------------------------------------------------------------


initial_memory_control initial_memory_control_inst(
    //input
    .clk(clk),
    .reset(rst_n),
    .shuffle_net_result_ready(shuffleNet_Result_Ready),
    .log10_result_Rready(mfsc_result_Rready),
    .log10_result_Wready(mfsc_result_Wready),
    //output
    .write_enable(initial_write_enable),
    .bram_address_0(mfsc_bram_address_0),
    .bram_address_1(mfsc_bram_address_1),
    .bram_address_2(mfsc_bram_address_2),
    .bram_address_3(mfsc_bram_address_3),
    .BRAM_ready(feature_map_ready),
    .select_bramA(select_bramA)
);

//internal wires for kernel control
logic [4:0] kernel_count_next;
assign kernel_count_next = kernel_count_7bit_next[4:0];
logic [1:0] kernel_select_0;
logic [1:0] kernel_select_1;
logic [1:0] kernel_select_2;
logic [1:0] kernel_select_3;
assign kernel_write_enable = 1'b0;
assign kernel_write_in_data = 80'b0;

kernel_control kernel_control_inst(
    //input
    .clk(clk),
    .reset(rst_n),
    .cnn_result_ready(shuffleNet_Result_Ready),
    .stage_count_next(stage_count_next),
    .kernel_count_next(kernel_count_next),
    .read_kernel_enable(read_kernel_enable),
    //output
    .read_kernel_addr(read_kernel_addr),
    .kernel_select_0(kernel_select_0),
    .kernel_select_1(kernel_select_1),
    .kernel_select_2(kernel_select_2),
    .kernel_select_3(kernel_select_3)
);

//internal wires for shuffleNet port
    assign shuffleNet_inputB_bus = {bram_B3_out_data, bram_B2_out_data, bram_B1_out_data, bram_B0_out_data};
    //weight_bus
    mux4_reverse_sequence mux4_reverse_sequence_inst_0(
        .input_data_0(kernel_0_out_data),
        .input_data_1(kernel_1_out_data),
        .input_data_2(kernel_2_out_data),
        .input_data_3(kernel_3_out_data),
        .select_data(kernel_select_0),
        .output_data(weight_bus[79:0])
    );
    mux4_reverse_sequence mux4_reverse_sequence_inst_1(
        .input_data_0(kernel_0_out_data),
        .input_data_1(kernel_1_out_data),
        .input_data_2(kernel_2_out_data),
        .input_data_3(kernel_3_out_data),
        .select_data(kernel_select_1),
        .output_data(weight_bus[159:80])
    );
    mux4_reverse_sequence mux4_reverse_sequence_inst_2(
        .input_data_0(kernel_0_out_data),
        .input_data_1(kernel_1_out_data),
        .input_data_2(kernel_2_out_data),
        .input_data_3(kernel_3_out_data),
        .select_data(kernel_select_2),
        .output_data(weight_bus[239:160])
    );
    mux4_reverse_sequence mux4_reverse_sequence_inst_3(
        .input_data_0(kernel_0_out_data),
        .input_data_1(kernel_1_out_data),
        .input_data_2(kernel_2_out_data),
        .input_data_3(kernel_3_out_data),
        .select_data(kernel_select_3),
        .output_data(weight_bus[319:240])
    );



//internal wires for read control
logic [2:0] read_ram_select0;
logic [2:0] read_ram_select1;
logic [2:0] read_ram_select2;
logic [2:0] read_ram_select3;
assign bram_C0_out_addr = bram_A0_out_addr;
assign bram_C1_out_addr = bram_A1_out_addr;
assign bram_C2_out_addr = bram_A2_out_addr;
assign bram_C3_out_addr = bram_A3_out_addr;


feature_map_read_control feature_map_read_control_inst(
    //input
    .clk(clk),
    .reset(rst_n),
    .stage_count_next(stage_count_next),
    .read(read_featuremap_enable),
    //output
    .read_addr_A0(bram_A0_out_addr),
    .read_addr_A1(bram_A1_out_addr),
    .read_addr_A2(bram_A2_out_addr),
    .read_addr_A3(bram_A3_out_addr),
    .read_addr_B0(bram_B0_out_addr),
    .read_addr_B1(bram_B1_out_addr),
    .read_addr_B2(bram_B2_out_addr),
    .read_addr_B3(bram_B3_out_addr),
    .read_ram_select0(read_ram_select0),
    .read_ram_select1(read_ram_select1),
    .read_ram_select2(read_ram_select2),
    .read_ram_select3(read_ram_select3)
);

//internal wires for write control
logic [10:0] write_addr_0;
logic [10:0] write_addr_1;
logic [10:0] write_addr_2;
logic [10:0] write_addr_3;
logic [7:0]  write_featureMap_enable;
assign bram_B0_in_we = write_featureMap_enable[4];
assign bram_B1_in_we = write_featureMap_enable[5];
assign bram_B2_in_we = write_featureMap_enable[6];
assign bram_B3_in_we = write_featureMap_enable[7];
assign bram_B0_in_data = shuffleNet_output_bus[15:0];
assign bram_B1_in_data = shuffleNet_output_bus[31:16];
assign bram_B2_in_data = shuffleNet_output_bus[47:32];
assign bram_B3_in_data = shuffleNet_output_bus[63:48];
assign bram_B0_in_addr = write_addr_0[9:0];
assign bram_B1_in_addr = write_addr_1[9:0];
assign bram_B2_in_addr = write_addr_2[9:0];
assign bram_B3_in_addr = write_addr_3[9:0];


feature_map_write_control feature_map_write_control_inst(
    //input
    .clk(clk),
    .reset(rst_n),
    .stage_count_next(stage_count),
    .write(write_featuremap_enable),
    //output
    .write_addr_0(write_addr_0),
    .write_addr_1(write_addr_1),
    .write_addr_2(write_addr_2),
    .write_addr_3(write_addr_3),
    .write_enable(write_featureMap_enable)
);




//internal wires for AC
    initial_mux initial_mux_inst_A0(
        //input
        .A_data(shuffleNet_output_bus[15:0]),
        .B_data(mfsc_result_data),
        .A_addr(write_addr_0),
        .B_addr(mfsc_bram_address_0),
        .A_write_enable(write_featureMap_enable[0]),
        .B_write_enable(initial_write_enable_test[0]),
        .select_A(select_bramA),
        //output
        .addr(bram_A0_in_addr),
        .data(bram_A0_in_data),
        .write_enable(bram_A0_in_we)
    );
    initial_mux initial_mux_inst_A1(
        //input
        .A_data(shuffleNet_output_bus[31:16]),
        .B_data(mfsc_result_data),
        .A_addr(write_addr_1),
        .B_addr(mfsc_bram_address_1),
        .A_write_enable(write_featureMap_enable[1]),
        .B_write_enable(initial_write_enable_test[1]),
        .select_A(select_bramA),
        //output
        .addr(bram_A1_in_addr),
        .data(bram_A1_in_data),
        .write_enable(bram_A1_in_we)
    );
    initial_mux initial_mux_inst_A2(
        //input
        .A_data(shuffleNet_output_bus[47:32]),
        .B_data(mfsc_result_data),
        .A_addr(write_addr_2),
        .B_addr(mfsc_bram_address_2),
        .A_write_enable(write_featureMap_enable[2]),
        .B_write_enable(initial_write_enable_test[2]),
        .select_A(select_bramA),
        //output
        .addr(bram_A2_in_addr),
        .data(bram_A2_in_data),
        .write_enable(bram_A2_in_we)
    );
    initial_mux initial_mux_inst_A3(
        //input
        .A_data(shuffleNet_output_bus[63:48]),
        .B_data(mfsc_result_data),
        .A_addr(write_addr_3),
        .B_addr(mfsc_bram_address_3),
        .A_write_enable(write_featureMap_enable[3]),
        .B_write_enable(initial_write_enable_test[3]),
        .select_A(select_bramA),
        //output
        .addr(bram_A3_in_addr),
        .data(bram_A3_in_data),
        .write_enable(bram_A3_in_we)
    );
    initial_mux initial_mux_inst_C0(
        //input
        .A_data(mfsc_result_data),
        .B_data(shuffleNet_output_bus[15:0]),
        .A_addr(mfsc_bram_address_0),
        .B_addr(write_addr_0),
        .A_write_enable(initial_write_enable_test[0]),
        .B_write_enable(write_featureMap_enable[0]),
        .select_A(select_bramA),
        //output
        .addr(bram_C0_in_addr),
        .data(bram_C0_in_data),
        .write_enable(bram_C0_in_we)
    );
    initial_mux initial_mux_inst_C1(
        //input
        .A_data(mfsc_result_data),
        .B_data(shuffleNet_output_bus[31:16]),
        .A_addr(mfsc_bram_address_1),
        .B_addr(write_addr_1),
        .A_write_enable(initial_write_enable_test[1]),
        .B_write_enable(write_featureMap_enable[1]),
        .select_A(select_bramA),
        //output
        .addr(bram_C1_in_addr),
        .data(bram_C1_in_data),
        .write_enable(bram_C1_in_we)
    );
    initial_mux initial_mux_inst_C2(
        //input
        .A_data(mfsc_result_data),
        .B_data(shuffleNet_output_bus[47:32]),
        .A_addr(mfsc_bram_address_2),
        .B_addr(write_addr_2),
        .A_write_enable(initial_write_enable_test[2]),
        .B_write_enable(write_featureMap_enable[2]),
        .select_A(select_bramA),
        //output
        .addr(bram_C2_in_addr),
        .data(bram_C2_in_data),
        .write_enable(bram_C2_in_we)
    );
    initial_mux initial_mux_inst_C3(
        //input
        .A_data(mfsc_result_data),
        .B_data(shuffleNet_output_bus[63:48]),
        .A_addr(mfsc_bram_address_3),
        .B_addr(write_addr_3),
        .A_write_enable(initial_write_enable_test[3]),
        .B_write_enable(write_featureMap_enable[3]),
        .select_A(select_bramA),
        //output
        .addr(bram_C3_in_addr),
        .data(bram_C3_in_data),
        .write_enable(bram_C3_in_we)
    );




logic [15:0] bram_AC0_data;
logic [15:0] bram_AC1_data;
logic [15:0] bram_AC2_data;
logic [15:0] bram_AC3_data;
    mux2 mux2_inst_0(
        //input
        .A_data(bram_A0_out_data),
        .B_data(bram_C0_out_data),
        .select_A(select_bramA),
        //output
        .data(bram_AC0_data)
    );
    mux2 mux2_inst_1(
        //input
        .A_data(bram_A1_out_data),
        .B_data(bram_C1_out_data),
        .select_A(select_bramA),
        //output
        .data(bram_AC1_data)
    );
    mux2 mux2_inst_2(
        //input
        .A_data(bram_A2_out_data),
        .B_data(bram_C2_out_data),
        .select_A(select_bramA),
        //output
        .data(bram_AC2_data)
    );
    mux2 mux2_inst_3(
        //input
        .A_data(bram_A3_out_data),
        .B_data(bram_C3_out_data),
        .select_A(select_bramA),
        //output
        .data(bram_AC3_data)
    );

    mux8 mux8_inst_0(
        //input
        .input_data_0(bram_AC0_data),
        .input_data_1(bram_AC1_data),
        .input_data_2(bram_AC2_data),
        .input_data_3(bram_AC3_data),
        .input_data_4(bram_B0_out_data),
        .input_data_5(bram_B1_out_data),
        .input_data_6(bram_B2_out_data),
        .input_data_7(bram_B3_out_data),
        .select_data(read_ram_select0),
        //output
        .output_data(shuffleNet_input_bus[15:0])
    );
    mux8 mux8_inst_1(
        //input
        .input_data_0(bram_AC0_data),
        .input_data_1(bram_AC1_data),
        .input_data_2(bram_AC2_data),
        .input_data_3(bram_AC3_data),
        .input_data_4(bram_B0_out_data),
        .input_data_5(bram_B1_out_data),
        .input_data_6(bram_B2_out_data),
        .input_data_7(bram_B3_out_data),
        .select_data(read_ram_select1),
        //output
        .output_data(shuffleNet_input_bus[31:16])
    );
    mux8 mux8_inst_2(
        //input
        .input_data_0(bram_AC0_data),
        .input_data_1(bram_AC1_data),
        .input_data_2(bram_AC2_data),
        .input_data_3(bram_AC3_data),
        .input_data_4(bram_B0_out_data),
        .input_data_5(bram_B1_out_data),
        .input_data_6(bram_B2_out_data),
        .input_data_7(bram_B3_out_data),
        .select_data(read_ram_select2),
        //output
        .output_data(shuffleNet_input_bus[47:32])
    );
    mux8 mux8_inst_3(
        //input
        .input_data_0(bram_AC0_data),
        .input_data_1(bram_AC1_data),
        .input_data_2(bram_AC2_data),
        .input_data_3(bram_AC3_data),
        .input_data_4(bram_B0_out_data),
        .input_data_5(bram_B1_out_data),
        .input_data_6(bram_B2_out_data),
        .input_data_7(bram_B3_out_data),
        .select_data(read_ram_select3),
        //output
        .output_data(shuffleNet_input_bus[63:48])
    );




endmodule
