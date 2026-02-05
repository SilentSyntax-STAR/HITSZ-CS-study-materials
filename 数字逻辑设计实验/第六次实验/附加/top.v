`timescale 1ns / 1ps

module top(
    input wire clk,
    input wire rst,
    input wire uart_rx,
    output wire uart_tx
);

wire [7:0] data1,data2;
wire valid1,valid2;

uart_top u_uart_top(
    .clk(clk),
    .rst(rst),
    .valid1(valid1),
    .valid2(valid2),
    .data1(data1),
    .data2(data2)
);

uart_recv u_uart_recv(
    .clk(clk),
    .rst(rst),
    .din(uart_rx),
    .valid(valid1),
    .data(data1)
);

uart_send u_uart_send(
    .clk(clk),
    .rst(rst),
    .valid(valid2),
    .data(data2),
    .dout(uart_tx)
);

endmodule
