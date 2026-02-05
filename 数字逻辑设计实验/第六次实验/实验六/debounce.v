`timescale 1ns / 1ps

module debounce(
    input clk,
    input rst,
    input btn_in,
    output reg btn_out
);

    reg [19:0] counter;
    reg btn_sync1, btn_sync2, btn_sync3;
    reg btn_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync1 <= 0;
            btn_sync2 <= 0;
            btn_sync3 <= 0;
        end else begin
            btn_sync1 <= btn_in;     
            btn_sync2 <= btn_sync1; 
            btn_sync3 <= btn_sync2;  
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_prev <= 0;
        end else begin
            btn_prev <= btn_sync3; 
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
        end else begin
            if (btn_prev != btn_sync3) begin
                counter <= 0;
            end else if (counter < 1000000) begin 
                counter <= counter + 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_out <= 0;
        end else begin

            if (btn_prev != btn_sync3) begin
                btn_out <= btn_out; 
            end else if (counter >= 1000000) begin 
                btn_out <= btn_sync3;  
            end
        end
    end

endmodule