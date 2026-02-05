`timescale 1ns / 1ps

module top_uart(
    input clk,
    input rst,       
    input din,        
    input s3_btn,     
    output tx,      
    output [7:0] seg_en, 
    output [7:0] seg_out  
);

    wire [7:0] uart_rx_data;
    wire uart_rx_valid;
    wire [7:0] student_id_data;
    wire student_id_valid;
    wire btn_debounced;
    wire uart_send_ready;

    uart_recv u_uart_recv(
        .clk(clk),
        .rst(rst),
        .din(din),
        .valid(uart_rx_valid),
        .data(uart_rx_data)
    );

    debounce u_debounce(
        .clk(clk),
        .rst(rst),
        .btn_in(s3_btn),
        .btn_out(btn_debounced)
    );

    uart_send u_uart_send(
        .clk(clk),
        .rst(rst),
        .valid(student_id_valid),   
        .data(student_id_data),   
        .dout(tx),                  
        .ready(uart_send_ready)     
    );
    
    student_id_sender u_student_id(
        .clk(clk),
        .rst(rst),
        .trigger(btn_debounced),
        .uart_ready(uart_send_ready),
        .tx_data(student_id_data),
        .tx_valid(student_id_valid)
    );

    seg_display u_seg_display(
        .clk(clk),
        .rst(rst),
        .rx_data(uart_rx_data),
        .rx_valid(uart_rx_valid),
        .seg_en(seg_en),
        .seg_out(seg_out)
    );

endmodule