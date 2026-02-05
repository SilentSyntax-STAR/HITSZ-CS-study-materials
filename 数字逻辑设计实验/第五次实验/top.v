`timescale 1ns / 1ps

module top(
    input clk,          // 系统时钟
    input rst,          // 复位信号（按键开关S1）
    output uart_tx      // UART发送引脚
);

// 参数定义
localparam CLOCK_FREQ = 100_000_000;  // 100MHz
localparam CHAR_INTERVAL = CLOCK_FREQ / 100;     // 字符间隔0.01s = 1,000,000周期
localparam STRING_INTERVAL = CLOCK_FREQ / 5;     // 字符串间隔0.2s = 20,000,000周期

// 要发送的字符串："hitsz2024311668" (共15个字符)
localparam STRING_LEN = 15;

// 字符串ROM - 使用参数定义
reg [7:0] string_rom [0:STRING_LEN-1];

// 字符索引计数器
reg [4:0] char_index;  // 0-14 (15个字符，需要5位)
reg [31:0] interval_counter;
reg send_valid;
reg [7:0] send_data;

// UART发送模块实例化
uart_send u_uart_send(
    .clk(clk),
    .rst(rst),
    .valid(send_valid),
    .data(send_data),
    .dout(uart_tx)
);

// 字符串发送控制状态机 - 使用三段式
reg [1:0] current_state;
reg [1:0] next_state;

localparam S_IDLE = 2'b00;
localparam S_SEND_CHAR = 2'b01;
localparam S_CHAR_WAIT = 2'b10;
localparam S_STRING_WAIT = 2'b11;

// 第一段：状态寄存器（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= S_IDLE;
    end else begin
        current_state <= next_state;
    end
end

// 第二段：次态逻辑（组合逻辑）
always @(*) begin
    case (current_state)
        S_IDLE: begin
            next_state = S_SEND_CHAR;
        end
        
        S_SEND_CHAR: begin
            next_state = S_CHAR_WAIT;
        end
        
        S_CHAR_WAIT: begin
            if (interval_counter >= CHAR_INTERVAL) begin
                if (char_index == STRING_LEN - 1) begin
                    next_state = S_STRING_WAIT;
                end else begin
                    next_state = S_SEND_CHAR;
                end
            end else begin
                next_state = S_CHAR_WAIT;
            end
        end
        
        S_STRING_WAIT: begin
            if (interval_counter >= STRING_INTERVAL) begin
                next_state = S_SEND_CHAR;
            end else begin
                next_state = S_STRING_WAIT;
            end
        end
        
        default: next_state = S_IDLE;
    endcase
end

// 第三段：char_index输出逻辑（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        char_index <= 5'd0;
    end else begin
        case (current_state)
            S_IDLE: begin
                char_index <= 5'd0;
            end
            
            S_CHAR_WAIT: begin
                if (interval_counter >= CHAR_INTERVAL) begin
                    if (char_index == STRING_LEN - 1) begin
                        char_index <= 5'd0;
                    end else begin
                        char_index <= char_index + 5'd1;
                    end
                end
            end
            
            default: begin
                // 其他状态保持char_index不变
            end
        endcase
    end
end

// 第四段：interval_counter输出逻辑（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        interval_counter <= 32'd0;
    end else begin
        case (current_state)
            S_IDLE: begin
                interval_counter <= 32'd0;
            end
            
            S_SEND_CHAR: begin
                interval_counter <= 32'd0;
            end
            
            S_CHAR_WAIT: begin
                if (interval_counter >= CHAR_INTERVAL) begin
                    interval_counter <= 32'd0;
                end else begin
                    interval_counter <= interval_counter + 32'd1;
                end
            end
            
            S_STRING_WAIT: begin
                if (interval_counter >= STRING_INTERVAL) begin
                    interval_counter <= 32'd0;
                end else begin
                    interval_counter <= interval_counter + 32'd1;
                end
            end
            
            default: begin
                interval_counter <= 32'd0;
            end
        endcase
    end
end

// 第五段：send_valid输出逻辑（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        send_valid <= 1'b0;
    end else begin
        case (current_state)
            S_IDLE: begin
                send_valid <= 1'b0;
            end
            
            S_SEND_CHAR: begin
                send_valid <= 1'b1;
            end
            
            S_CHAR_WAIT: begin
                send_valid <= 1'b0;
            end
            
            S_STRING_WAIT: begin
                send_valid <= 1'b0;
            end
            
            default: begin
                send_valid <= 1'b0;
            end
        endcase
    end
end

// 第六段：send_data输出逻辑（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        send_data <= 8'd0;
    end else begin
        case (current_state)
            S_SEND_CHAR: begin
                send_data <= string_rom[char_index];
            end
            
            default: begin
                // 其他状态保持send_data不变，或者可以赋默认值
                // send_data <= 8'd0;
            end
        endcase
    end
end

// 第七段：string_rom初始化逻辑（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        string_rom[0]  <= 8'h68;  // h
        string_rom[1]  <= 8'h69;  // i
        string_rom[2]  <= 8'h74;  // t
        string_rom[3]  <= 8'h73;  // s
        string_rom[4]  <= 8'h7A;  // z
        string_rom[5]  <= 8'h32;  // 2
        string_rom[6]  <= 8'h30;  // 0
        string_rom[7]  <= 8'h32;  // 2
        string_rom[8]  <= 8'h34;  // 4
        string_rom[9]  <= 8'h33;  // 3
        string_rom[10] <= 8'h31;  // 1
        string_rom[11] <= 8'h31;  // 1
        string_rom[12] <= 8'h36;  // 6
        string_rom[13] <= 8'h36;  // 6
        string_rom[14] <= 8'h38;  // 8
    end
end

endmodule