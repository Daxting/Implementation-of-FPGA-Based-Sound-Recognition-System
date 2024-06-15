module initial_memory_control(
input  wire clk,
input  wire reset,
input  wire shuffle_net_result_ready, // from cnn
input  wire log10_result_Rready, //from mfsc
output reg  log10_result_Wready, //to mfsc
//following signals are for initial_mux_A(port B), and initial_mux_C(port A)
output reg [3:0] write_enable,   //0 for ram0, 1 for ram1, 2 for ram2, 3 for ram3              
output reg [10:0] bram_address_0,//control address
output reg [10:0] bram_address_1,//control address
output reg [10:0] bram_address_2,//control address
output reg [10:0] bram_address_3,//control address
output reg BRAM_ready,// to cnn
output reg select_bramA//if 1 stands for bram A, if 0 stands for bram C.
);
 
    // control counter64_melf and counter64_time and log10_result_Wready
    reg [5:0] counter64_melf;
    reg [5:0] counter64_time;
    reg gate, gate1;
    always @(posedge clk, negedge reset)begin 
        if(!reset)begin
            counter64_melf <=6'd63;
            counter64_time <=6'd63;
            gate <= 1'b0;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b1;
        end
        else if (log10_result_Rready && gate == 1'b0 && counter64_melf==6'd63 && counter64_time==6'd63 && !shuffle_net_result_ready)begin
            counter64_melf <= 6'd0;
            counter64_time <= counter64_time + 6'd1;
            gate <= 1'b1;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b0;
        end
        else if (log10_result_Rready && gate == 1'b0 && counter64_melf==6'd63 && counter64_time==6'd63 && shuffle_net_result_ready)begin
            counter64_melf <= 6'd0;
            counter64_time <= 6'd0;
            gate <= 1'b1;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b0;
        end
        else if (log10_result_Rready && gate == 1'b0 && counter64_melf==6'd63 && counter64_time<6'd63)begin
            counter64_melf <= 6'd0;
            counter64_time <= counter64_time + 6'd1;
            gate <= 1'b1;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b0;
        end
        else if (log10_result_Rready && gate == 1'b0 && counter64_melf<6'd63)begin
            counter64_melf <= counter64_melf + 6'd1;
            counter64_time <= counter64_time;
            gate <= 1'b1;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b0;
        end
        else if (!log10_result_Rready && gate == 1'b1 && !(counter64_time==6'd63 && counter64_melf==6'd63))begin
            counter64_melf <= counter64_melf;
            counter64_time <= counter64_time;
            gate <= 1'b0;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b1;
        end
        else if (!log10_result_Rready && gate == 1'b1 && counter64_time==6'd63 && counter64_melf==6'd63 && shuffle_net_result_ready)begin
            counter64_melf <= counter64_melf;
            counter64_time <= counter64_time;
            gate <= 1'b0;
            gate1<= 1'b0;
            log10_result_Wready <= 1'b1;
        end
        else if (write_enable!=4'b0000 && gate1 == 1'b0 && !(counter64_time==6'd63 && counter64_melf==6'd63 && !shuffle_net_result_ready))begin
            counter64_melf <= counter64_melf;
            counter64_time <= counter64_time;
            gate <= gate;
            gate1<= 1'b1;
            log10_result_Wready <= 1'b0;
        end
        else if (write_enable!=4'b0000 && gate1 == 1'b1)begin
            counter64_melf <= counter64_melf;
            counter64_time <= counter64_time;
            gate <= gate;
            gate1<= 1'b1;
            log10_result_Wready <= 1'b1;
        end
        else begin
            counter64_melf <= counter64_melf;
            counter64_time <= counter64_time;
            gate <= gate;
            log10_result_Wready <= log10_result_Wready;
        end
    end
    
    //control bram_address and counter64_melf_next and write_enable
    reg [5:0] counter64_melf_next;
    reg time_buffer;
    wire unlock;
    assign unlock = (counter64_melf==counter64_melf_next); 
    always @(posedge clk, negedge reset)begin
        if(!reset)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= 6'd0;
            bram_address_0 <= {11{1'b1}};
            bram_address_1 <= {11{1'b1}};
            bram_address_2 <= {11{1'b1}};
            bram_address_3 <= {11{1'b1}};
            write_enable <= 4'b0000;
        end
        else if(counter64_melf<6'd16 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0+ 11'd1;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3;
            write_enable <= 4'b0001;
        end
        else if(counter64_melf==6'd16 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0+ 11'd1;
            bram_address_1<=bram_address_1+ 11'd1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3;
            write_enable <= 4'b0011;
        end
        else if(counter64_melf<6'd32 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1+ 11'd1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3;
            write_enable <= 4'b0010;
        end
        else if(counter64_melf==6'd32 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1+ 11'd1;
            bram_address_2<=bram_address_2+ 11'd1;
            bram_address_3<=bram_address_3;
            write_enable <= 4'b0110;
        end
        else if(counter64_melf<6'd48 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2+ 11'd1;
            bram_address_3<=bram_address_3;
            write_enable <= 4'b0100;
        end
        else if(counter64_melf==6'd48 && counter64_time==6'd0 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2+ 11'd1;
            bram_address_3<=bram_address_3+ 11'd1;
            write_enable <= 4'b1100;
        end
        else if(counter64_melf==6'd48 && counter64_time>6'd0 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2+ 11'd1;
            bram_address_3<=bram_address_3+ 11'd2;
            write_enable <= 4'b1100;
        end
        else if(counter64_melf<6'd63 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf+6'd1;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3+ 11'd1;
            write_enable <= 4'b1000;
        end
        else if(counter64_melf==6'd63 && unlock && log10_result_Rready && write_enable==4'b0000)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= 6'd0;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3+11'd1;
            write_enable <= 4'b1000;
        end
        else if(!unlock && !time_buffer && counter64_melf==6'd63 && counter64_time==6'd63 && write_enable==4'b0000 && shuffle_net_result_ready)begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf_next;
            bram_address_0 <= {11{1'b1}};
            bram_address_1 <= {11{1'b1}};
            bram_address_2 <= {11{1'b1}};
            bram_address_3 <= {11{1'b1}};
            write_enable <= write_enable;
        end
        else if(!unlock && !time_buffer && bram_address_0 != {11{1'b1}})begin
            counter64_melf_next <= counter64_melf_next;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3;
            write_enable <= write_enable;
            time_buffer <= 1'b1;
        end

        else begin
            time_buffer <= 1'b0;
            counter64_melf_next <= counter64_melf_next;
            bram_address_0<=bram_address_0;
            bram_address_1<=bram_address_1;
            bram_address_2<=bram_address_2;
            bram_address_3<=bram_address_3;
            write_enable <= 4'b0000;
        end
    end

    //control bram_ready and select_bramA
    reg single_bram_full;
    reg lock;
    always @(posedge clk, negedge reset)begin
        if(!reset)begin
            single_bram_full <= 1'b0;
            BRAM_ready <= 1'b0;
            select_bramA <= 1'b0;
            lock<=1'b1;
        end
        else if (!lock && !BRAM_ready && !single_bram_full && shuffle_net_result_ready && counter64_time==6'd63 && counter64_melf==6'd63 && counter64_melf_next==6'd0&& write_enable==4'b0000)begin
            single_bram_full <= 1'b1;
            BRAM_ready <= 1'b0;
            select_bramA <= select_bramA;
            lock<=1'b1;
        end
        else if (shuffle_net_result_ready && single_bram_full)begin
            single_bram_full <= 1'b0;
            BRAM_ready <= 1'b1;
            select_bramA <= ~select_bramA;
            lock<=lock;
        end
        else if (counter64_time==6'd0 && counter64_melf==6'd0 )begin
            single_bram_full <= single_bram_full;
            BRAM_ready <= 1'b0;
            select_bramA <= select_bramA;
            lock<=1'b0;
        end
        else if (!shuffle_net_result_ready)begin
            single_bram_full <= single_bram_full;
            BRAM_ready <= 1'b0;
            select_bramA <= select_bramA;
            lock<=lock;
        end
        else begin
            single_bram_full <= single_bram_full;
            BRAM_ready <= BRAM_ready;
            select_bramA <= select_bramA;
            lock<=lock;
        end
    end
endmodule
