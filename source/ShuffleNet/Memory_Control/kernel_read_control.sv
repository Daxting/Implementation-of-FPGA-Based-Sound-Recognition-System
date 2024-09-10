module kernel_control(
output reg [8:0] read_kernel_addr,          // the address of the kernel to be read
output reg [1:0]  kernel_select_0,        // 0 for kernel_0,  1 for kernel 1, 2 for kernel 2, 3 for kernel 3 // first step of conv
output reg [1:0]  kernel_select_1,
output reg [1:0]  kernel_select_2,
output reg [1:0]  kernel_select_3,   
input wire clk,
input wire reset,
input wire cnn_result_ready,
input wire [5:0]stage_count_next,            //the next stage(0 for idle)
input wire [4:0]kernel_count_next,           //the next used kernel in the stage(0 for idle)
input wire read_kernel_enable           
);
    reg [1:0][1:0] kernel_select_0_next;
    reg [1:0][1:0] kernel_select_1_next;
    reg [1:0][1:0] kernel_select_2_next;
    reg [1:0][1:0] kernel_select_3_next;
    always_comb begin : kernel_select_next_control
        if(!reset)begin
            kernel_select_0_next[0] = 2'b00;
            kernel_select_1_next[0] = 2'b00;
            kernel_select_2_next[0] = 2'b00;
            kernel_select_3_next[0] = 2'b00;
        end
        else if(stage_count_next==6'd0)begin
            kernel_select_0_next[0] = 2'b00;
            kernel_select_1_next[0] = 2'b00;
            kernel_select_2_next[0] = 2'b00;
            kernel_select_3_next[0] = 2'b00;        
        end
        else if(stage_count_next==6'd1 && kernel_count_next<5'd5)begin
            kernel_select_0_next[0] = 2'b00;
            kernel_select_1_next[0] = 2'b00;
            kernel_select_2_next[0] = 2'b00;
            kernel_select_3_next[0] = 2'b00;
        end
        else if(stage_count_next==6'd1 && kernel_count_next<5'd9)begin
            kernel_select_0_next[0] = 2'b01;
            kernel_select_1_next[0] = 2'b01;
            kernel_select_2_next[0] = 2'b01;
            kernel_select_3_next[0] = 2'b01;
        end
        else if(stage_count_next==6'd1 && kernel_count_next<5'd13)begin
            kernel_select_0_next[0] = 2'b10;
            kernel_select_1_next[0] = 2'b10;
            kernel_select_2_next[0] = 2'b10;
            kernel_select_3_next[0] = 2'b10;
        end
        else if(stage_count_next==6'd1 && kernel_count_next<5'd17)begin
            kernel_select_0_next[0] = 2'b11;
            kernel_select_1_next[0] = 2'b11;
            kernel_select_2_next[0] = 2'b11;
            kernel_select_3_next[0] = 2'b11;
        end
        else begin
            kernel_select_0_next[0] = 2'b00;
            kernel_select_1_next[0] = 2'b01;
            kernel_select_2_next[0] = 2'b10;
            kernel_select_3_next[0] = 2'b11;
        end
    end

    always_ff @(posedge clk, negedge reset) begin : kernel_select_control
        if(!reset)begin
            kernel_select_0_next[1] <= 2'b00;
            kernel_select_1_next[1] <= 2'b00;
            kernel_select_2_next[1] <= 2'b00;
            kernel_select_3_next[1] <= 2'b00;
            kernel_select_0 <= 2'b00;
            kernel_select_1 <= 2'b00;
            kernel_select_2 <= 2'b00;
            kernel_select_3 <= 2'b00;
        end
        else begin
            kernel_select_0_next[1] <= kernel_select_0_next[0];
            kernel_select_1_next[1] <= kernel_select_1_next[0];
            kernel_select_2_next[1] <= kernel_select_2_next[0];
            kernel_select_3_next[1] <= kernel_select_3_next[0];
            kernel_select_0 <= kernel_select_0_next[1];
            kernel_select_1 <= kernel_select_1_next[1];
            kernel_select_2 <= kernel_select_2_next[1];
            kernel_select_3 <= kernel_select_3_next[1];
        end
    end

    reg [8:0] read_kernel_addr_offset;
    reg [4:0] kernel_row_size_next;

    reg [4:0] kernel_count_record;
    reg [4:0] kernel_row_number;

    always_ff @(posedge clk, negedge reset) begin : offest_control_and_size_control
        if(!reset)begin
            kernel_row_size_next <= 5'd0;
            read_kernel_addr_offset <= 9'd0;
        end
        else begin
            case(stage_count_next)
                6'd1:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd0;
                end
                6'd3:begin
                    kernel_row_size_next <= 5'd4;
                    read_kernel_addr_offset <= 9'd8;
                end
                6'd4:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd16;
                end
                6'd5:begin
                    kernel_row_size_next <= 5'd1;
                    read_kernel_addr_offset <= 9'd20;
                end
                6'd6:begin
                    kernel_row_size_next <= 5'd1;
                    read_kernel_addr_offset <= 9'd22;
                end
                6'd7:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd24;
                end
                6'd8:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd40;
                end
                6'd9:begin
                    kernel_row_size_next <= 5'd1;
                    read_kernel_addr_offset <= 9'd44;
                end
                6'd10:begin
                    kernel_row_size_next <= 5'd1;
                    read_kernel_addr_offset <= 9'd48;
                end
                6'd13:begin
                    kernel_row_size_next <= 5'd4;
                    read_kernel_addr_offset <= 9'd52;
                end
                6'd14:begin
                    kernel_row_size_next <= 5'd4;
                    read_kernel_addr_offset <= 9'd60;
                end
                6'd15:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd68;
                end
                6'd16:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd76;
                end
                6'd17:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd84;
                end
                6'd18:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd92;
                end
                6'd19:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd108;
                end
                6'd20:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd124;
                end
                6'd21:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd132;
                end
                6'd22:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd148;
                end
                6'd24:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd164;
                end
                6'd25:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd180;
                end
                6'd26:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd196;
                end
                6'd27:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd204;
                end
                6'd28:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd220;
                end
                6'd29:begin
                    kernel_row_size_next <= 5'd0;
                    read_kernel_addr_offset <= 9'd236;
                end
                6'd30:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd236;
                end
                6'd31:begin
                    kernel_row_size_next <= 5'd8;
                    read_kernel_addr_offset <= 9'd252;
                end
                6'd32:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd268;
                end
                6'd33:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd276;
                end
                6'd34:begin
                    kernel_row_size_next <= 5'd2;
                    read_kernel_addr_offset <= 9'd292;
                end
                6'd37:begin
                    kernel_row_size_next <= 5'd16;
                    read_kernel_addr_offset <= 9'd308;
                end
                default:begin
                    kernel_row_size_next <= 5'd0;
                    read_kernel_addr_offset <= 9'd0;
                end
            endcase
        end
    end

    always_ff @(posedge clk, negedge reset) begin : read_kernel_addr_control
        if(!reset || stage_count_next == 6'd38)begin
            read_kernel_addr <= 9'd0;
            kernel_count_record <= 5'd0;
            kernel_row_number <= 5'd0;
        end
        else if(read_kernel_enable)begin
            if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && kernel_count_next==5'd1)begin
                read_kernel_addr <= read_kernel_addr_offset;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && kernel_count_next==5'd2)begin
                read_kernel_addr <= read_kernel_addr_offset+kernel_row_size_next;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && kernel_count_next==5'd3)begin
                read_kernel_addr <= read_kernel_addr_offset+kernel_row_size_next*5'd2;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && kernel_count_next==5'd4)begin
                read_kernel_addr <= read_kernel_addr_offset+kernel_row_size_next*5'd3;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && read_kernel_addr == 6 && (kernel_count_next== 5 || kernel_count_next== 9|| kernel_count_next== 13))begin
                read_kernel_addr <= 0;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && read_kernel_addr == 1 && (kernel_count_next== 6 || kernel_count_next== 10|| kernel_count_next== 14))begin
                read_kernel_addr <= 2;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && read_kernel_addr == 2 && (kernel_count_next== 7 || kernel_count_next== 11|| kernel_count_next== 15))begin
                read_kernel_addr <= 4;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && read_kernel_addr == 5 && (kernel_count_next== 8 || kernel_count_next== 12|| kernel_count_next== 16))begin
                read_kernel_addr <= 6;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && (kernel_count_next==5'd5 || kernel_count_next==5'd9 || kernel_count_next==5'd13))begin
                read_kernel_addr <= read_kernel_addr_offset;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
             else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && (kernel_count_next==5'd6 || kernel_count_next==5'd10 || kernel_count_next==5'd14))begin
                read_kernel_addr <= read_kernel_addr_offset+kernel_row_size_next;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && (kernel_count_next==5'd7 || kernel_count_next==5'd11 || kernel_count_next==5'd15))begin
                read_kernel_addr <= read_kernel_addr_offset+kernel_row_size_next*5'd2;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if(stage_count_next==6'd1 && kernel_row_number==kernel_row_size_next-5'd1 && (kernel_count_next==5'd8 || kernel_count_next==5'd12 || kernel_count_next==5'd16))begin
                read_kernel_addr <= read_kernel_addr_offset+kernel_row_size_next*5'd3;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else if((stage_count_next!=1 || stage_count_next==1 && kernel_count_next < 5)&& kernel_count_record!=kernel_count_next)begin
                read_kernel_addr <= read_kernel_addr_offset+(kernel_count_next-5'd1)*kernel_row_size_next;
                kernel_count_record <= kernel_count_next;
                kernel_row_number <= 5'd0;
            end
            else if((stage_count_next!=1 || stage_count_next==1 && kernel_count_next < 5) && kernel_row_number==kernel_row_size_next-5'd1)begin
                read_kernel_addr <= read_kernel_addr_offset+(kernel_count_next-5'd1)*kernel_row_size_next;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= 5'd0;
            end
            else begin
                read_kernel_addr <= read_kernel_addr+9'b1;
                kernel_count_record <= kernel_count_record;
                kernel_row_number <= kernel_row_number+1;
            end
        end
        else begin
            read_kernel_addr <= read_kernel_addr;
            kernel_count_record <= kernel_count_record;
            kernel_row_number <= kernel_row_number;
        end
    end



endmodule 