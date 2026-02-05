`timescale 1ns / 1ps

module uart_recv(
    input                   clk,   
    input                   rst,   
    input                   din,   // 串口数据输入

    output reg              valid, // 为1表明输出的数据data有效，只维持一个时钟周期
    output reg [7:0]        data   
);

localparam    IDLE  = 2'b00;
localparam    START = 2'b01;
localparam    DATA  = 2'b10;
localparam    STOP  = 2'b11;

reg [1:0] current_state;
reg [1:0] next_state;

reg [3:0] bit_cnt;

reg [13:0] baud_cnt;
localparam BAUD_MAX = 14'd10416;
localparam BAUD_HALF = 14'd5208;
wire baud_done = (baud_cnt == BAUD_MAX - 1);
wire half_done = (baud_cnt == BAUD_HALF - 1);

reg valid1;

always @(posedge clk) begin
    if(current_state == IDLE && din == 1'b0)valid1<=1;
    else valid1<=0;
end

always @(posedge clk) begin
    if(current_state == STOP && half_done)valid<=1;
    else valid<=0;
end
//状态寄存器（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end
//次态寄存器（转移逻辑）
always @(*) begin
    case (current_state)
        IDLE: begin
            if (valid1) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end
        end
        START: begin
            if (half_done) begin
                next_state = DATA;
            end else begin
                next_state = START;
            end
        end
        DATA: begin
            if (baud_done && (bit_cnt == 4'd8)) begin
                next_state = STOP;
            end else begin
                next_state = DATA;
            end
        end
        STOP: begin
            if (baud_done) begin
                next_state = IDLE;
            end else begin
                next_state = STOP;
            end
        end
        default: next_state = IDLE;
    endcase
end

//输出逻辑（时序逻辑）-位计数器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bit_cnt <= 3'd0;
    end else begin
        if (current_state == DATA) begin
            if (half_done) begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end else begin
            bit_cnt <= 3'd0;
        end
    end
end
// 输出逻辑（时序逻辑）- 数据寄存器
always @ (posedge clk or posedge rst)begin
    if(rst)begin
        data<=8'd0;
    end else begin
        if(current_state == DATA && half_done) data[bit_cnt]<=din;
        else data<=data;
    end
end
// 输出逻辑（时序逻辑）- 波特率计数器
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_cnt <= 14'd0;
    end else begin
        if (current_state == IDLE) begin
            baud_cnt <= 14'd0;
        end else if (baud_done) begin
            baud_cnt <= 14'd0;
        end else begin
            baud_cnt <= baud_cnt + 1'b1;
        end
    end
end

endmodule