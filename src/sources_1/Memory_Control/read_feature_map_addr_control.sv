module feature_map_read_control(
output reg [10:0] read_addr_A0,
output reg [10:0] read_addr_A1,
output reg [10:0] read_addr_A2,
output reg [10:0] read_addr_A3,
output reg [9:0]  read_addr_B0,
output reg [9:0]  read_addr_B1,
output reg [9:0]  read_addr_B2,
output reg [9:0]  read_addr_B3,
output reg [2:0]  read_ram_select0,           //connect to input ram0 mux : 0 for AC0, 1 for AC1,..., 4 for B0..., 7 for B3 // point-wise conv
output reg [2:0]  read_ram_select1,           //connect to input ram1 mux : 0 for AC0, 1 for AC1,..., 4 for B0..., 7 for B3 // point-wise conv
output reg [2:0]  read_ram_select2,           //connect to input ram2 mux : 0 for AC0, 1 for AC1,..., 4 for B0..., 7 for B3 // point-wise conv
output reg [2:0]  read_ram_select3,           //connect to input ram3 mux : 0 for AC0, 1 for AC1,..., 4 for B0..., 7 for B3 // point-wise conv
input wire clk,
input wire reset,
input wire [5:0]stage_count_next,             //the next stage(0 for idle)
input wire read   
);
    // three main kind of read: point-wise conv, avg_pool, depth-wise conv(add)
    // special read: global depth-wise conv, fully connected
    
    // point-wise conv:         switch feature map every "read" time for several cycles
    // full connection:         switch feature map every "read" time for one cycles
    reg [5:0] feature_map_total_number_next;        //the total feature map number in the stage
    reg [3:0] feature_map_size_next;                //all the feature map are square except the first stage  
    // avg_pool:                use the z type of reading style for one time parallelly

    // depth-wise conv:         normal reading sequence for one time parallelly
    // Global depth-wise conv:  normal reading sequence for 16 time parallelly
    
    reg [3:0] feature_map_addr_X_next;        //the next feature map X in the stage
    reg [3:0] feature_map_addr_Y_next;        //the next feature map Y in the stage
    reg [5:0] feature_map_count_next;         //the current calculated feature map in the stage
    reg [5:0] stage_count_record;             //the record of the stage count, using for the feature map count control

    reg [3:0] offset_addr_X_next;             //the next offset_X in the stage, maximum 15
    reg [5:0] offset_addr_Y_next;             //the next offset_Y in the stage, maximum 63

    always_ff @(posedge clk or negedge reset)begin: feature_map_constant_control
        if(!reset)begin
            feature_map_total_number_next <= 6'd0;
            feature_map_size_next <= 4'd0;
        end
        else begin
            case(stage_count_next)
                6'd1: begin
                    feature_map_total_number_next <= 6'd0;
                    feature_map_size_next <= 4'd0;//not a square, 17*64
                end
                6'd2: begin
                    feature_map_total_number_next <= 6'd3;
                    feature_map_size_next <= 4'd15;
                end
                6'd3: begin
                    feature_map_total_number_next <= 6'd15;
                    feature_map_size_next <= 4'd15;
                end
                6'd4: begin
                    feature_map_total_number_next <= 6'd1;
                    feature_map_size_next <= 4'd15;
                end
                6'd5, 6'd6: begin
                    feature_map_total_number_next <= 6'd3;
                    feature_map_size_next <= 4'd7;
                end
                6'd7: begin
                    feature_map_total_number_next <= 6'd31;
                    feature_map_size_next <= 4'd7;
                end
                6'd8: begin
                    feature_map_total_number_next <= 6'd1;
                    feature_map_size_next <= 4'd7;
                end
                6'd9, 6'd10: begin
                    feature_map_total_number_next <= 6'd3;
                    feature_map_size_next <= 4'd7;
                end
                6'd11: begin
                    feature_map_total_number_next <= 6'd1;
                    feature_map_size_next <= 4'd15;
                end
                6'd12: begin
                    feature_map_total_number_next <= 6'd7;
                    feature_map_size_next <= 4'd7;
                end
                6'd13, 6'd14: begin
                    feature_map_total_number_next <= 6'd15;
                    feature_map_size_next <= 4'd7;
                end
                6'd15: begin
                    feature_map_total_number_next <= 6'd3;
                    feature_map_size_next <= 4'd7;
                end
                6'd16, 6'd17: begin
                    feature_map_total_number_next <= 6'd3;
                    feature_map_size_next <= 4'd7;
                end
                6'd18, 6'd19, 6'd24, 6'd25, 6'd30, 6'd31: begin
                    feature_map_total_number_next <= 6'd31;
                    feature_map_size_next <= 4'd3;
                end
                6'd20, 6'd26, 6'd32: begin
                    feature_map_total_number_next <= 6'd3;
                    feature_map_size_next <= 4'd3;
                end
                6'd21, 6'd22, 6'd27, 6'd28, 6'd33, 6'd34: begin
                    feature_map_total_number_next <= 6'd7;
                    feature_map_size_next <= 4'd3;
                end
                6'd23, 6'd29, 6'd35: begin
                    feature_map_total_number_next <= 6'd0;
                    feature_map_size_next <= 4'd15;
                end
                6'd36: begin
                    feature_map_total_number_next <= 6'd15;
                    feature_map_size_next <= 4'd3;
                end
                6'd37: begin
                    feature_map_total_number_next <= 6'd63;
                    feature_map_size_next <= 4'd0;
                end
                default: begin
                    feature_map_total_number_next <= 6'd0;
                    feature_map_size_next <= 4'd0;
                end
            endcase
        end
    end


    reg [1:0] counter4; //for the avg_pool2_2
    always_ff @(posedge clk or negedge reset)begin: counter4_control
        if(!reset)begin
            counter4 <= 2'd3;
        end
        else if(read && (stage_count_next == 6'd2 || stage_count_next == 6'd12) )begin
            counter4 <= counter4 + 2'd1;
        end
        else if(read && !(stage_count_next == 6'd2 || stage_count_next == 6'd12))begin
            counter4 <= 2'd3;
        end
        else begin
            counter4 <= counter4;
        end
    end

    reg [3:0] counter16; //for the avg_pool4_4
    always_ff @(posedge clk or negedge reset)begin: counter16_control
        if(!reset)begin
            counter16 <= 4'd15;
        end
        else if(read && stage_count_next == 6'd36)begin
            counter16 <= counter16 + 4'd1;
        end
        else if(read && stage_count_next != 6'd36)begin
            counter16 <= 4'd15;
        end
        else begin
            counter16 <= counter16;
        end
    end

    //don't need to deal with the first stage
    //1. point-wise conv & full connection   : switch count every "read" time 
    //2. avg_pool2x2 & avg_pool4x4           : z type reading style
    //3. depth-wise conv&add                 : normal reading sequence
    always_ff @(posedge clk or negedge reset)begin: feature_map_addr_and_count_next_control
        // feature_map_total_number_next
        // feature_map_size_next
        if(!reset)begin
            feature_map_addr_X_next = 4'd0;
            feature_map_addr_Y_next = 4'd0;
            feature_map_count_next = 6'd0;
            stage_count_record = 6'd0;
        end
        else if(read)begin
            case(stage_count_next)
                6'd2, 6'd12: begin: avg_pool2_2
                    if(stage_count_record != stage_count_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_next;
                    end
                    else if(feature_map_count_next == feature_map_total_number_next && feature_map_addr_Y_next == feature_map_size_next && feature_map_addr_X_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_record;
                    end
                    else if(feature_map_addr_X_next == feature_map_size_next && feature_map_addr_Y_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = feature_map_count_next + 6'd1;
                        stage_count_record = stage_count_record;
                    end
                    else if(counter4==2'd0 || counter4==2'd2)begin
                        feature_map_addr_X_next = feature_map_addr_X_next + 4'd1;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else if(counter4==2'd1)begin
                        feature_map_addr_X_next = feature_map_addr_X_next - 4'd1;
                        feature_map_addr_Y_next = feature_map_addr_Y_next + 4'd1;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else if(counter4==2'd3 && feature_map_addr_X_next==feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = feature_map_addr_Y_next + 4'd1;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else if(counter4 == 2'd3)begin
                        feature_map_addr_X_next = feature_map_addr_X_next + 4'd1;
                        feature_map_addr_Y_next = feature_map_addr_Y_next - 4'd1;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else begin // exception
                        feature_map_addr_X_next = feature_map_addr_X_next;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                end

                6'd36: begin: avg_pool4_4
                    if(stage_count_record != stage_count_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_next;
                    end
                    else if(feature_map_count_next == feature_map_total_number_next && feature_map_addr_Y_next == feature_map_size_next && feature_map_addr_X_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_record;
                    end
                    else if(feature_map_addr_X_next == feature_map_size_next && feature_map_addr_Y_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = feature_map_count_next + 6'd1;
                        stage_count_record = stage_count_record;
                    end
                    else if(counter16==4'd0 || counter16==4'd1 || counter16==4'd2 || counter16==4'd4 || counter16==4'd5 || counter16==4'd6 || counter16==4'd8 || counter16==4'd9 || counter16==4'd10 || counter16==4'd12 || counter16==4'd13 || counter16==4'd14)begin
                        feature_map_addr_X_next = feature_map_addr_X_next + 4'd1;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else if(counter16==4'd3 || counter16==4'd7 || counter16==4'd11 || counter16==4'd15)begin
                        feature_map_addr_X_next = feature_map_addr_X_next - 4'd3;
                        feature_map_addr_Y_next = feature_map_addr_Y_next + 4'd1;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else begin // exception
                        feature_map_addr_X_next = feature_map_addr_X_next;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                end

                6'd3, 6'd5, 6'd6, 6'd7, 6'd9, 6'd10, 6'd13, 6'd14, 6'd16, 6'd17, 6'd18, 6'd19, 6'd21, 6'd22, 6'd24, 6'd25, 6'd27, 6'd28, 6'd30, 6'd31, 6'd33, 6'd34, 6'd37: begin: point_wise_conv_full_connection
                    if(stage_count_record != stage_count_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_next;
                    end
                    else if(feature_map_addr_Y_next==feature_map_size_next && feature_map_addr_X_next==feature_map_size_next && feature_map_count_next==feature_map_total_number_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_record;
                    end
                    else if(feature_map_addr_X_next==feature_map_size_next && feature_map_count_next==feature_map_total_number_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = feature_map_addr_Y_next + 4'd1;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_record;
                    end
                    else if(feature_map_count_next==feature_map_total_number_next)begin
                        feature_map_addr_X_next = feature_map_addr_X_next + 4'd1;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_record;
                    end
                    else begin
                        feature_map_addr_X_next = feature_map_addr_X_next;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = feature_map_count_next+6'd1;
                        stage_count_record = stage_count_record;
                    end
                end
                6'd4, 6'd8, 6'd11, 6'd15, 6'd20, 6'd23, 6'd26, 6'd29, 6'd32, 6'd35: begin: depth_wise_conv_add
                    if(stage_count_record != stage_count_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_next;
                    end
                    else if(feature_map_count_next == feature_map_total_number_next && feature_map_addr_Y_next == feature_map_size_next && feature_map_addr_X_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = 6'd0;
                        stage_count_record = stage_count_record;
                    end
                    else if(feature_map_addr_X_next == feature_map_size_next && feature_map_addr_Y_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = 4'd0;
                        feature_map_count_next = feature_map_count_next + 6'd1;
                        stage_count_record = stage_count_record;
                    end
                    else if(feature_map_addr_X_next == feature_map_size_next)begin
                        feature_map_addr_X_next = 4'd0;
                        feature_map_addr_Y_next = feature_map_addr_Y_next + 4'd1;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                    else begin
                        feature_map_addr_X_next = feature_map_addr_X_next + 4'd1;
                        feature_map_addr_Y_next = feature_map_addr_Y_next;
                        feature_map_count_next = feature_map_count_next;
                        stage_count_record = stage_count_record;
                    end
                end
                default: begin // first stage & exception
                    feature_map_addr_X_next = 4'd0;
                    feature_map_addr_Y_next = 4'd0;
                    feature_map_count_next = 6'd0;
                    stage_count_record = 4'd0;
                end        
            endcase
        end
        else begin
            feature_map_addr_X_next = feature_map_addr_X_next;
            feature_map_addr_Y_next = feature_map_addr_Y_next;
            feature_map_count_next = feature_map_count_next;
        end
    end

    always_ff @(posedge clk or negedge reset)begin: offset_addr_next_control
        if(!reset)begin
            offset_addr_X_next = 4'd0;
            offset_addr_Y_next = 6'd0;
        end
        else begin
            case(stage_count_next)
                6'd2:begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd2: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd48;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd3:begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd48;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd4: begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd5: begin
                    offset_addr_X_next = 4'd0;
                    offset_addr_Y_next = 6'd0;
                end
                6'd6: begin
                    offset_addr_X_next = 4'd8;
                    offset_addr_Y_next = 6'd0;
                end
                6'd7: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd16, 6'd17, 6'd18, 6'd19: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd20, 6'd21, 6'd22, 6'd23: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd24, 6'd25, 6'd26, 6'd27: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd28, 6'd29, 6'd30, 6'd31: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd24;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd8: begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd9: begin
                    offset_addr_X_next = 4'd0;
                    offset_addr_Y_next = 6'd32;
                end
                6'd10: begin
                    offset_addr_X_next = 4'd8;
                    offset_addr_Y_next = 6'd32;
                end
                6'd11: begin
                     case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd12: begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd32;
                        end
                        6'd2: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd40;
                        end
                        6'd3: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd40;
                        end
                        6'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd48;
                        end
                        6'd5: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd48;
                        end
                        6'd6: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd56;
                        end
                        6'd7: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd56;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd13: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd14: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd24;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd15: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd16: begin
                    offset_addr_X_next = 4'd0;
                    offset_addr_Y_next = 6'd0;
                end
                6'd17: begin
                    offset_addr_X_next = 4'd8;
                    offset_addr_Y_next = 6'd0;
                end
                6'd18, 6'd30: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd16, 6'd17, 6'd18, 6'd19: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd4;
                        end
                        6'd20, 6'd21, 6'd22, 6'd23: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd4;
                        end
                        6'd24, 6'd25, 6'd26, 6'd27: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd4;
                        end
                        6'd28, 6'd29, 6'd30, 6'd31: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd4;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd19, 6'd31: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd8;
                        end
                        6'd16, 6'd17, 6'd18, 6'd19: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd12;
                        end
                        6'd20, 6'd21, 6'd22, 6'd23: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd12;
                        end
                        6'd24, 6'd25, 6'd26, 6'd27: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd12;
                        end
                        6'd28, 6'd29, 6'd30, 6'd31: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd12;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd20, 6'd32: begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd2: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd4;
                        end
                        6'd3: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd4;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd21, 6'd33: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end     
                6'd22, 6'd34: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd23, 6'd35: begin
                    offset_addr_X_next = 4'd0;
                    offset_addr_Y_next = 6'd0;
                end
                6'd24: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd16, 6'd17, 6'd18, 6'd19: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd20, 6'd21, 6'd22, 6'd23: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd24, 6'd25, 6'd26, 6'd27: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd28, 6'd29, 6'd30, 6'd31: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd20;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd25: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd16, 6'd17, 6'd18, 6'd19: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd28;
                        end
                        6'd20, 6'd21, 6'd22, 6'd23: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd28;
                        end
                        6'd24, 6'd25, 6'd26, 6'd27: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd28;
                        end
                        6'd28, 6'd29, 6'd30, 6'd31: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd28;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd26: begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd27: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd28: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd29: begin
                    offset_addr_X_next = 4'd0;
                    offset_addr_Y_next = 6'd16;
                end
                6'd36: begin
                    case(feature_map_count_next)
                        6'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd16;
                        end
                        6'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd5: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd6: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd20;
                        end
                        6'd8: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd9: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd10: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd11: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd24;
                        end
                        6'd12: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd28;
                        end
                        6'd13: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd28;
                        end
                        6'd14: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd28;
                        end
                        6'd15: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd28;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                6'd37: begin
                    case(feature_map_count_next)
                        6'd0, 6'd1, 6'd2, 6'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd4, 6'd5, 6'd6, 6'd7: begin
                            offset_addr_X_next = 4'd1;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd8, 6'd9, 6'd10, 6'd11: begin
                            offset_addr_X_next = 4'd2;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd12, 6'd13, 6'd14, 6'd15: begin
                            offset_addr_X_next = 4'd3;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd16, 6'd17, 6'd18, 6'd19: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd20, 6'd21, 6'd22, 6'd23: begin
                            offset_addr_X_next = 4'd5;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd24, 6'd25, 6'd26, 6'd27: begin
                            offset_addr_X_next = 4'd6;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd28, 6'd29, 6'd30, 6'd31: begin
                            offset_addr_X_next = 4'd7;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd32, 6'd33, 6'd34, 6'd35: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd36, 6'd37, 6'd38, 6'd39: begin
                            offset_addr_X_next = 4'd9;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd40, 6'd41, 6'd42, 6'd43: begin
                            offset_addr_X_next = 4'd10;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd44, 6'd45, 6'd46, 6'd47: begin
                            offset_addr_X_next = 4'd11;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd48, 6'd49, 6'd50, 6'd51: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd52, 6'd53, 6'd54, 6'd55: begin
                            offset_addr_X_next = 4'd13;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd56, 6'd57, 6'd58, 6'd59: begin
                            offset_addr_X_next = 4'd14;
                            offset_addr_Y_next = 6'd0;
                        end
                        6'd60, 6'd61, 6'd62, 6'd63: begin
                            offset_addr_X_next = 4'd15;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase
                end
                default: begin
                    offset_addr_X_next = 4'd0;
                    offset_addr_Y_next = 6'd0;
                end
            endcase
        end
    end


    reg [4:0] feature_map_addr_X_first_stage_next;        //the next feature map X in the stage
    reg [5:0] feature_map_addr_Y_first_stage_next;        //the next feature map Y in the stage
    always_ff @(posedge clk or negedge reset)begin:  feature_map_addr_first_stage_next_control
        if(!reset)begin
            feature_map_addr_X_first_stage_next <= 5'd16;
            feature_map_addr_Y_first_stage_next <= 6'd63;
        end
        else if(stage_count_next == 6'd1)begin
            if(read)begin
                if(feature_map_addr_Y_first_stage_next==6'd63 && feature_map_addr_X_first_stage_next==5'd16)begin
                    feature_map_addr_X_first_stage_next <= 5'd0;
                    feature_map_addr_Y_first_stage_next <= 6'd0;
                end
                else if(feature_map_addr_X_first_stage_next==5'd16)begin
                    feature_map_addr_X_first_stage_next <= 5'd0;
                    feature_map_addr_Y_first_stage_next <= feature_map_addr_Y_first_stage_next+6'd1;
                end
                else begin
                    feature_map_addr_X_first_stage_next <= feature_map_addr_X_first_stage_next+5'd1;
                    feature_map_addr_Y_first_stage_next <= feature_map_addr_Y_first_stage_next;
                end
            end
            else begin
                feature_map_addr_X_first_stage_next <= feature_map_addr_X_first_stage_next;
                feature_map_addr_Y_first_stage_next <= feature_map_addr_Y_first_stage_next;
            end
        end
        else begin
            feature_map_addr_X_first_stage_next <= 5'd16;
            feature_map_addr_Y_first_stage_next <= 6'd63;
        end
    end

    always_comb begin: read_addr_control
        if(!reset)begin
            read_addr_A0 = 11'd0;
            read_addr_A1 = 11'd0;
            read_addr_A2 = 11'd0;
            read_addr_A3 = 11'd0;
            read_addr_B0 = 10'd0;
            read_addr_B1 = 10'd0;
            read_addr_B2 = 10'd0;
            read_addr_B3 = 10'd0;
        end
        else begin
            case(stage_count_next)
                6'd1: begin: first_stage
                    read_addr_A0 = feature_map_addr_X_first_stage_next+feature_map_addr_Y_first_stage_next*17;
                    read_addr_A1 = feature_map_addr_X_first_stage_next+feature_map_addr_Y_first_stage_next*17;
                    read_addr_A2 = feature_map_addr_X_first_stage_next+feature_map_addr_Y_first_stage_next*17;
                    read_addr_A3 = feature_map_addr_X_first_stage_next+feature_map_addr_Y_first_stage_next*17;
                    read_addr_B0 = 10'd0;
                    read_addr_B1 = 10'd0;
                    read_addr_B2 = 10'd0;
                    read_addr_B3 = 10'd0;
                end
                6'd4, 6'd7, 6'd9, 6'd10, 6'd12, 6'd13, 6'd14, 6'd16, 6'd17, 6'd20, 6'd26, 6'd32, 6'd37: begin: depth_point_average_read_AC
                    read_addr_A0 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_A1 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_A2 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_A3 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_B0 = 10'd0;
                    read_addr_B1 = 10'd0;
                    read_addr_B2 = 10'd0;
                    read_addr_B3 = 10'd0;
                end
                6'd2, 6'd3, 6'd5, 6'd6, 6'd8, 6'd15, 6'd18, 6'd19, 6'd21, 6'd22, 6'd24, 6'd25, 6'd27, 6'd28, 6'd30, 6'd31, 6'd33, 6'd34, 6'd36: begin: depth_point_average_read_B
                    read_addr_A0 = 11'd0;
                    read_addr_A1 = 11'd0;
                    read_addr_A2 = 11'd0;
                    read_addr_A3 = 11'd0;
                    read_addr_B0 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_B1 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_B2 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next+offset_addr_X_next);
                    read_addr_B3 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next+offset_addr_X_next);
                end
                6'd11, 6'd23, 6'd35: begin: ADD0_ADD1_ADD3
                    read_addr_A0 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_A1 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_A2 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_A3 = (feature_map_addr_Y_next+offset_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_B0 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                    read_addr_B1 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                    read_addr_B2 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                    read_addr_B3 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                end
                6'd29: begin: ADD2
                    read_addr_A0 = (feature_map_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_A1 = (feature_map_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_A2 = (feature_map_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_A3 = (feature_map_addr_Y_next)*17+(feature_map_addr_X_next);
                    read_addr_B0 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                    read_addr_B1 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                    read_addr_B2 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                    read_addr_B3 = (feature_map_addr_Y_next+offset_addr_Y_next)*16+(feature_map_addr_X_next);
                end
                default: begin
                    read_addr_A0 = 11'd0;
                    read_addr_A1 = 11'd0;
                    read_addr_A2 = 11'd0;
                    read_addr_A3 = 11'd0;
                    read_addr_B0 = 10'd0;
                    read_addr_B1 = 10'd0;
                    read_addr_B2 = 10'd0;
                    read_addr_B3 = 10'd0;
                end
            endcase
        end
    end

    reg [1:0][2:0]  read_ram_select0_temp;  //because the output of the ram delay one cycle 
    reg [1:0][2:0]  read_ram_select1_temp;  //because the output of the ram delay one cycle          
    reg [1:0][2:0]  read_ram_select2_temp;  //because the output of the ram delay one cycle       
    reg [1:0][2:0]  read_ram_select3_temp;  //because the output of the ram delay one cycle

    always_ff @(posedge clk or negedge reset)begin: read_ram_select_temp_control
        if(!reset)begin
            read_ram_select0_temp[0] <= 3'd0;
            read_ram_select1_temp[0] <= 3'd0;
            read_ram_select2_temp[0] <= 3'd0;
            read_ram_select3_temp[0] <= 3'd0;
        end
        else begin
            case(stage_count_next)
                6'd1, 6'd4, 6'd11, 6'd12, 6'd20, 6'd23, 6'd26, 6'd29, 6'd32, 6'd35: begin: depth_wise_conv_average_add_read_AC
                    read_ram_select0_temp[0] <= 3'd0;
                    read_ram_select1_temp[0] <= 3'd1;
                    read_ram_select2_temp[0] <= 3'd2;
                    read_ram_select3_temp[0] <= 3'd3;
                end
                6'd2, 6'd8, 6'd15, 6'd36: begin: depth_wise_conv_average_read_B
                    read_ram_select0_temp[0] <= 3'd4;
                    read_ram_select1_temp[0] <= 3'd5;
                    read_ram_select2_temp[0] <= 3'd6;
                    read_ram_select3_temp[0] <= 3'd7;
                end
                6'd7, 6'd9, 6'd10, 6'd13, 6'd14, 6'd16, 6'd17, 6'd37: begin: point_wise_conv_full_read_AC
                    case (feature_map_count_next)
                        6'd0, 6'd4, 6'd8, 6'd12, 6'd16, 6'd20, 6'd24, 6'd28: begin
                            read_ram_select0_temp[0] <= 3'd0;
                            read_ram_select1_temp[0] <= 3'd0;
                            read_ram_select2_temp[0] <= 3'd0;
                            read_ram_select3_temp[0] <= 3'd0;
                        end
                        6'd1, 6'd5, 6'd9, 6'd13, 6'd17, 6'd21, 6'd25, 6'd29: begin
                            read_ram_select0_temp[0] <= 3'd1;
                            read_ram_select1_temp[0] <= 3'd1;
                            read_ram_select2_temp[0] <= 3'd1;
                            read_ram_select3_temp[0] <= 3'd1;
                        end
                        6'd2, 6'd6, 6'd10, 6'd14, 6'd18, 6'd22, 6'd26, 6'd30: begin
                            read_ram_select0_temp[0] <= 3'd2;
                            read_ram_select1_temp[0] <= 3'd2;
                            read_ram_select2_temp[0] <= 3'd2;
                            read_ram_select3_temp[0] <= 3'd2;
                        end
                        6'd3, 6'd7, 6'd11, 6'd15, 6'd19, 6'd23, 6'd27, 6'd31: begin
                            read_ram_select0_temp[0] <= 3'd3;
                            read_ram_select1_temp[0] <= 3'd3;
                            read_ram_select2_temp[0] <= 3'd3;
                            read_ram_select3_temp[0] <= 3'd3;
                        end
                    endcase
                end
                6'd3, 6'd5, 6'd6, 6'd18, 6'd19, 6'd21, 6'd22, 6'd24, 6'd25, 6'd27, 6'd28, 6'd30, 6'd31, 6'd33, 6'd34: begin: point_wise_conv_read_B
                    case (feature_map_count_next)
                        6'd0, 6'd4, 6'd8, 6'd12, 6'd16, 6'd20, 6'd24, 6'd28: begin
                            read_ram_select0_temp[0] <= 3'd4;
                            read_ram_select1_temp[0] <= 3'd4;
                            read_ram_select2_temp[0] <= 3'd4;
                            read_ram_select3_temp[0] <= 3'd4;
                        end
                        6'd1, 6'd5, 6'd9, 6'd13, 6'd17, 6'd21, 6'd25, 6'd29: begin
                            read_ram_select0_temp[0] <= 3'd5;
                            read_ram_select1_temp[0] <= 3'd5;
                            read_ram_select2_temp[0] <= 3'd5;
                            read_ram_select3_temp[0] <= 3'd5;
                        end
                        6'd2, 6'd6, 6'd10, 6'd14, 6'd18, 6'd22, 6'd26, 6'd30: begin
                            read_ram_select0_temp[0] <= 3'd6;
                            read_ram_select1_temp[0] <= 3'd6;
                            read_ram_select2_temp[0] <= 3'd6;
                            read_ram_select3_temp[0] <= 3'd6;
                        end
                        6'd3, 6'd7, 6'd11, 6'd15, 6'd19, 6'd23, 6'd27, 6'd31: begin
                            read_ram_select0_temp[0] <= 3'd7;
                            read_ram_select1_temp[0] <= 3'd7;
                            read_ram_select2_temp[0] <= 3'd7;
                            read_ram_select3_temp[0] <= 3'd7;
                        end
                    endcase
                end
                default: begin
                    read_ram_select0_temp[0] <= 3'd0;
                    read_ram_select1_temp[0] <= 3'd0;
                    read_ram_select2_temp[0] <= 3'd0;
                    read_ram_select3_temp[0] <= 3'd0;
                end
            endcase
        end
    end

    always_ff @(posedge clk, negedge reset)begin: read_ram_select_control
        if(!reset)begin
            read_ram_select0_temp[1] <= 3'd0;
            read_ram_select1_temp[1] <= 3'd0;
            read_ram_select2_temp[1] <= 3'd0;
            read_ram_select3_temp[1] <= 3'd0;
            read_ram_select0 <= 3'd0;
            read_ram_select1 <= 3'd0;
            read_ram_select2 <= 3'd0;
            read_ram_select3 <= 3'd0;
        end
        else begin
            read_ram_select0_temp[1] <= read_ram_select0_temp[0];
            read_ram_select1_temp[1] <= read_ram_select1_temp[0];
            read_ram_select2_temp[1] <= read_ram_select2_temp[0];
            read_ram_select3_temp[1] <= read_ram_select3_temp[0];
            read_ram_select0 <= read_ram_select0_temp[1];
            read_ram_select1 <= read_ram_select1_temp[1];
            read_ram_select2 <= read_ram_select2_temp[1];
            read_ram_select3 <= read_ram_select3_temp[1];
        end
    end

endmodule 