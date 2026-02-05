`timescale 1ns / 1ps

module student_id_sender(
    input clk,
    input rst,
    input trigger,
    input uart_ready,     
    output reg [7:0] tx_data,
    output reg tx_valid
);

    reg [7:0] student_id [0:9];
    reg [3:0] send_index;
    reg sending;
    reg trigger_prev;

    localparam IDLE = 1'b0;
    localparam SENDING = 1'b1;
    
    reg state;

    initial begin
        student_id[0] = "2";  // ASCII '2'
        student_id[1] = "0";  // ASCII '0'
        student_id[2] = "2";  // ASCII '2'
        student_id[3] = "4";  // ASCII '4'
        student_id[4] = "3";  // ASCII '3'
        student_id[5] = "1";  // ASCII '1'
        student_id[6] = "1";  // ASCII '3'
        student_id[7] = "6";  // ASCII '6'
        student_id[8] = "6";  // ASCII '6'
        student_id[9] = "8";  // ASCII '8'
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            trigger_prev <= 1'b0;
        end else begin
            trigger_prev <= trigger;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin

                    if (!trigger_prev && trigger) begin
                        if (uart_ready) begin  
                            tx_valid <= 1'b1;
                        end else begin
                            tx_valid <= 1'b0;
                        end
                    end else begin
                        tx_valid <= 1'b0;
                    end
                end
                
                SENDING: begin
                    if (tx_valid) begin
                        tx_valid <= 1'b0;
                    end else if (uart_ready) begin
                        if (send_index < 4'd9) begin
                            tx_valid <= 1'b1;
                        end else begin
                            tx_valid <= 1'b0;
                        end
                    end else begin
                        tx_valid <= 1'b0;
                    end
                end
                
                default: begin
                    tx_valid <= 1'b0;
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data <= 8'b0;
        end else begin
            case (state)
                IDLE: begin

                    if (!trigger_prev && trigger) begin
                        if (uart_ready) begin  
                            tx_data <= student_id[0];
                        end
                    end
                end
                
                SENDING: begin
                    if (!tx_valid && uart_ready) begin
                        if (send_index < 4'd9) begin
                            tx_data <= student_id[send_index + 1];
                        end
                    end
                end
            endcase
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_index <= 4'b0;
        end else begin
            case (state)
                IDLE: begin

                    if (!trigger_prev && trigger) begin
                        if (uart_ready) begin  
                            send_index <= 4'b0;
                        end
                    end
                end
                
                SENDING: begin
                    if (!tx_valid && uart_ready) begin

                        if (send_index < 4'd9) begin
                            send_index <= send_index + 1;
                        end else begin
                            send_index <= 4'b0;
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sending <= 1'b0;
        end else begin
            case (state)
                IDLE: begin

                    if (!trigger_prev && trigger) begin
                        if (uart_ready) begin  
                            sending <= 1'b1;
                        end
                    end
                end
                
                SENDING: begin
                    if (!tx_valid && uart_ready) begin

                        if (send_index >= 4'd9) begin
 
                            sending <= 1'b0;
                        end
                    end
                end
            endcase
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin

                    if (!trigger_prev && trigger) begin
                        if (uart_ready) begin  
                            state <= SENDING;
                        end
                    end
                end
                
                SENDING: begin
                    if (!tx_valid && uart_ready) begin

                        if (send_index >= 4'd9) begin

                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end

endmodule