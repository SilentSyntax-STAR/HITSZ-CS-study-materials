`timescale 1ns / 1ps
module clock_divider(
    input wire clk,
    input wire rst,
    input wire [1:0] freq_set,
    output reg clk_en
);

    reg [31:0] counter;
    reg [31:0] max_count;

    always @(*) begin
        case (freq_set)
            2'b00: max_count = 100;  
            2'b01: max_count = 1000;
            2'b10: max_count = 5000 ;
            2'b11: max_count = 20000;
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 32'd0;
            clk_en <= 1'b0;
        end else if (counter >= max_count - 1) begin
            counter <= 32'd0;
            clk_en <= 1'b1; 
        end else begin
            counter <= counter + 1;
            clk_en <= 1'b0;
        end
    end
endmodule
