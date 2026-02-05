`timescale 1ns / 1ps

module seg_display(
    input clk,
    input rst,
    input [7:0] rx_data,
    input rx_valid,
    output reg [7:0] seg_en,
    output reg [7:0] seg_out
);

    reg [7:0] display_buffer [7:0];

    reg [7:0] char_buffer [5:0];

    reg [7:0] char_count;

    reg [19:0] scan_counter;
    reg [2:0] scan_index;

    reg rx_valid_prev;

    function [7:0] seg_encoder;
        input [7:0] ascii_data;
        begin
            case (ascii_data)
                8'h30: seg_encoder = 8'hC0; // '0'
                8'h31: seg_encoder = 8'hF9; // '1'  
                8'h32: seg_encoder = 8'hA4; // '2'
                8'h33: seg_encoder = 8'hB0; // '3'
                8'h34: seg_encoder = 8'h99; // '4'
                8'h35: seg_encoder = 8'h92; // '5'
                8'h36: seg_encoder = 8'h82; // '6'
                8'h37: seg_encoder = 8'hF8; // '7'
                8'h38: seg_encoder = 8'h80; // '8'
                8'h39: seg_encoder = 8'h90; // '9'
                8'h41: seg_encoder = 8'h88; // 'A'
                8'h42: seg_encoder = 8'h83; // 'B'
                8'h43: seg_encoder = 8'hC6; // 'C'
                8'h44: seg_encoder = 8'hA1; // 'D'
                8'h45: seg_encoder = 8'h86; // 'E'
                8'h46: seg_encoder = 8'h8E; // 'F'
                8'h61: seg_encoder = 8'h88; // 'a'
                8'h62: seg_encoder = 8'h83; // 'b'
                8'h63: seg_encoder = 8'hC6; // 'c'
                8'h64: seg_encoder = 8'hA1; // 'd'
                8'h65: seg_encoder = 8'h86; // 'e'
                8'h66: seg_encoder = 8'h8E; // 'f'
                default: seg_encoder = 8'hFF;
            endcase
        end
    endfunction

    function [7:0] digit_to_seg;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: digit_to_seg = 8'hC0;
                4'h1: digit_to_seg = 8'hF9;
                4'h2: digit_to_seg = 8'hA4;
                4'h3: digit_to_seg = 8'hB0;
                4'h4: digit_to_seg = 8'h99;
                4'h5: digit_to_seg = 8'h92;
                4'h6: digit_to_seg = 8'h82;
                4'h7: digit_to_seg = 8'hF8;
                4'h8: digit_to_seg = 8'h80;
                4'h9: digit_to_seg = 8'h90;
                default: digit_to_seg = 8'hFF;
            endcase
        end
    endfunction
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_valid_prev <= 0;
        end else begin
            rx_valid_prev <= rx_valid;
        end
    end

    wire rx_posedge = rx_valid && !rx_valid_prev;
    wire is_valid_char = ((rx_data >= 8'h30 && rx_data <= 8'h39) ||  // 0-9
                         (rx_data >= 8'h41 && rx_data <= 8'h46) ||  // A-F
                         (rx_data >= 8'h61 && rx_data <= 8'h66));   // a-f
                         
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            char_count <= 0;
        end else begin
            if (rx_posedge && is_valid_char) begin
                char_count <= char_count + 1;
            end
        end
    end

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 6; i = i + 1)
                char_buffer[i] <= 8'h00;
        end else begin
            if (rx_posedge && is_valid_char) begin
                for (i = 0; i < 5; i = i + 1)
                    char_buffer[i] <= char_buffer[i + 1];
                char_buffer[5] <= rx_data;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1)
                display_buffer[i] <= 8'hFF;
        end else begin
            for (i = 0; i < 6; i = i + 1) begin
                display_buffer[7-i] <= (char_buffer[i] != 8'h00) ? 
                                      seg_encoder(char_buffer[i]) : 8'hFF;
            end
            display_buffer[1] <= digit_to_seg((char_count % 100) / 10);
            display_buffer[0] <= digit_to_seg(char_count % 10);
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_counter <= 0;
        end else begin
            if (scan_counter < 100000) begin
                scan_counter <= scan_counter + 1;
            end else begin
                scan_counter <= 0;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scan_index <= 0;
        end else begin
            if (scan_counter == 100000) begin
                if (scan_index == 3'd7) begin
                    scan_index <= 0;
                end else begin
                    scan_index <= scan_index + 1;
                end
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_out <= 8'hFF;
        end else begin
            seg_out <= display_buffer[scan_index];
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            seg_en <= 8'b11111111;
        end else begin
            seg_en <= ~(8'b1 << scan_index);
        end
    end
endmodule