module feature_map_write_control(
output reg [10:0] write_addr_0,         //the write address for the RAM AC0 & RAM B0
output reg [10:0] write_addr_1,         //the write address for the RAM AC1 & RAM B1
output reg [10:0] write_addr_2,         //the write address for the RAM AC2 & RAM B2
output reg [10:0] write_addr_3,         //the write address for the RAM AC3 & RAM B3
output reg [7:0]  write_enable,         //0 for AC0, 1 for AC1,..., 4 for B0..., 7 for B3  
input wire clk,
input wire reset,
input wire [5:0]stage_count_next,       //the next stage(0 for idle)
input wire write                        //write signal from cnn
);
    reg [3:0] feature_map_size_next;          //the size of the feature map, maximum 15
    
    reg [3:0] feature_map_addr_X_next;        //the next feature map X in the stage
    reg [3:0] feature_map_addr_Y_next;        //the next feature map Y in the stage
    reg [3:0] feature_map_count_next;         //the next calculated feature map in the stage
    reg [5:0] stage_count_record;             //the record of the stage count, using for the feature map count control

    reg [3:0] offset_addr_X_next;             //the next offset_X in the stage, maximum 15
    reg [5:0] offset_addr_Y_next;             //the next offset_Y in the stage, maximum 63

    always_comb begin: feature_map_size_control
        if(!reset)  feature_map_size_next = 4'd0;
        else begin
            case (stage_count_next)
                6'd1, 6'd3, 6'd11, 6'd23, 6'd29, 6'd35: feature_map_size_next = 4'd15;
                6'd2, 6'd4, 6'd5, 6'd6, 6'd7, 6'd8, 6'd9, 6'd10, 6'd13, 6'd14 : feature_map_size_next = 4'd7;
                6'd12, 6'd15,6'd16, 6'd17, 6'd18, 6'd19, 6'd20, 6'd21, 6'd22, 6'd24, 6'd25, 6'd26, 6'd27, 6'd28, 6'd30, 6'd31, 6'd32, 6'd33, 6'd34: feature_map_size_next = 4'd3;
                6'd36: feature_map_size_next = 4'd0;
                default: feature_map_size_next = 4'd0;
            endcase
        end
    end

    always_comb begin: write_enable_control
        if(!reset)begin
            write_enable = 8'b0000_0000;
        end
        else if(write)begin
            case (stage_count_next)
                6'd1: begin
                    case (feature_map_count_next)
                        4'd0, 4'd4, 4'd8, 4'd12: write_enable = 8'b0001_0000; // write to B0
                        4'd1, 4'd5, 4'd9, 4'd13: write_enable = 8'b0010_0000; // write to B1
                        4'd2, 4'd6, 4'd10, 4'd14: write_enable = 8'b0100_0000; // write to B2
                        4'd3, 4'd7, 4'd11, 4'd15: write_enable = 8'b1000_0000; // write to B3
                        default: write_enable = 8'b0000_0000;
                    endcase
                end
                6'd2, 6'd3, 6'd5, 6'd6, 6'd8, 6'd11, 6'd15, 6'd18, 6'd19, 6'd21, 6'd22, 6'd24, 6'd25, 6'd27, 6'd28, 6'd30, 6'd31, 6'd33, 6'd34, 6'd36: write_enable = 8'b0000_1111; // write to AC0, AC1, AC2, AC3
                6'd4, 6'd7, 6'd9, 6'd10, 6'd12, 6'd13, 6'd14, 6'd16, 6'd17, 6'd20, 6'd23, 6'd26, 6'd29, 6'd32, 6'd35: write_enable = 8'b1111_0000; // write to B0, B1, B2, B3
                default: write_enable = 8'b0000_0000;   
            endcase 
        end
        else begin
            write_enable = 8'b0000_0000;
        end
    end
    
    always_ff@(posedge clk, negedge reset) begin: feature_map_addr_control_feature_map_count_control
        if(!reset)begin
            feature_map_addr_X_next = 4'd0;
            feature_map_addr_Y_next = 4'd0;
            feature_map_count_next = 4'd0;
            stage_count_record = 6'd0;
        end
        else if(write)begin
            if(feature_map_addr_Y_next == feature_map_size_next && feature_map_addr_X_next == feature_map_size_next)begin
                feature_map_addr_X_next = 4'd0;
                feature_map_addr_Y_next = 4'd0;
                feature_map_count_next = feature_map_count_next + 4'd1;
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
        else if(stage_count_record!=stage_count_next)begin
            feature_map_addr_X_next = 4'd0;
            feature_map_addr_Y_next = 4'd0;
            feature_map_count_next = 6'd0;
            stage_count_record = stage_count_next;
        end
        else begin
            feature_map_addr_X_next = feature_map_addr_X_next;
            feature_map_addr_Y_next = feature_map_addr_Y_next;
            feature_map_count_next = feature_map_count_next;
            stage_count_record = stage_count_record;
        end
    end

    always_ff@(posedge clk, negedge reset) begin: offset_addr_control
        if(!reset)begin
            offset_addr_X_next = 4'd0;
            offset_addr_Y_next = 6'd0;
        end
        else begin
            case (stage_count_next)
                6'd1: begin
                    case (feature_map_count_next)
                        4'd0, 4'd1, 4'd2, 4'd3: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd4, 4'd5, 4'd6, 4'd7: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd8, 4'd9, 4'd10, 4'd11: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        4'd12, 4'd13, 4'd14, 4'd15: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd48;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd2: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd3: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd4: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd5: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase                     
                end
                6'd6: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd24;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd24;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd7: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd8: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd32;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd9: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd10: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd24;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd24;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd11: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd32;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd48;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd12: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd5: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd6: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd4;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd13: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd1: begin
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
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd15: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd16: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd8;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd17: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd12;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd18, 6'd30: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd19, 6'd31: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd20, 6'd32: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd16;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd21, 6'd33: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd5: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd6: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd4;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd22, 6'd34: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd5: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd6: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd12;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd23, 6'd35: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd16;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd24: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd25: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd26: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd3: begin
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
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd5: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd6: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd4;
                        end
                        4'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd4;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd28: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd8;
                        end
                        4'd4: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd5: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd6: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd12;
                        end
                        4'd7: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd12;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd29: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        default: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                    endcase 
                end
                6'd36: begin
                    case (feature_map_count_next)
                        4'd0: begin
                            offset_addr_X_next = 4'd0;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd1: begin
                            offset_addr_X_next = 4'd1;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd2: begin
                            offset_addr_X_next = 4'd2;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd3: begin
                            offset_addr_X_next = 4'd3;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd4: begin
                            offset_addr_X_next = 4'd4;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd5: begin
                            offset_addr_X_next = 4'd5;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd6: begin
                            offset_addr_X_next = 4'd6;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd7: begin
                            offset_addr_X_next = 4'd7;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd8: begin
                            offset_addr_X_next = 4'd8;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd9: begin
                            offset_addr_X_next = 4'd9;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd10: begin
                            offset_addr_X_next = 4'd10;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd11: begin
                            offset_addr_X_next = 4'd11;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd12: begin
                            offset_addr_X_next = 4'd12;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd13: begin
                            offset_addr_X_next = 4'd13;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd14: begin
                            offset_addr_X_next = 4'd14;
                            offset_addr_Y_next = 6'd0;
                        end
                        4'd15: begin
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

    always_comb begin: write_addr_control
        if(!reset)begin
            write_addr_0 = 11'd0;
            write_addr_1 = 11'd0;
            write_addr_2 = 11'd0;
            write_addr_3 = 11'd0;
        end
        else if(6'd37>stage_count_next && stage_count_next>6'd0 && |write_enable[3:0])begin
            write_addr_0 = (feature_map_addr_Y_next + offset_addr_Y_next)*17 + (feature_map_addr_X_next + offset_addr_X_next);
            write_addr_1 = (feature_map_addr_Y_next + offset_addr_Y_next)*17 + (feature_map_addr_X_next + offset_addr_X_next);
            write_addr_2 = (feature_map_addr_Y_next + offset_addr_Y_next)*17 + (feature_map_addr_X_next + offset_addr_X_next);
            write_addr_3 = (feature_map_addr_Y_next + offset_addr_Y_next)*17 + (feature_map_addr_X_next + offset_addr_X_next);
        end
        else if(6'd37>stage_count_next && stage_count_next>6'd0 && |write_enable[7:4])begin
            write_addr_0 = (feature_map_addr_Y_next + offset_addr_Y_next)*16 + (feature_map_addr_X_next + offset_addr_X_next);
            write_addr_1 = (feature_map_addr_Y_next + offset_addr_Y_next)*16 + (feature_map_addr_X_next + offset_addr_X_next);
            write_addr_2 = (feature_map_addr_Y_next + offset_addr_Y_next)*16 + (feature_map_addr_X_next + offset_addr_X_next);
            write_addr_3 = (feature_map_addr_Y_next + offset_addr_Y_next)*16 + (feature_map_addr_X_next + offset_addr_X_next);
        end
        else begin
            write_addr_0 = 11'd0;
            write_addr_1 = 11'd0;
            write_addr_2 = 11'd0;
            write_addr_3 = 11'd0;
        end
    end
    
endmodule 