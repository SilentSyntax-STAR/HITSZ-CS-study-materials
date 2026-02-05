`timescale 1ns / 1ps

module uart_send(
    input clk,
    input rst,
    input valid,        
    input [7:0] data,   
    output reg dout,
    output reg ready    // 添加 ready 信号
);

    // 状态定义
    localparam IDLE  = 2'b00;   
    localparam START = 2'b01;   
    localparam DATA  = 2'b10;   
    localparam STOP  = 2'b11;   
    
    // 波特率参数
    localparam CLOCK_FREQ = 100_000_000;  
    localparam BAUD_RATE = 9600;
    localparam DIVIDER = CLOCK_FREQ / BAUD_RATE - 1;  

    // 状态寄存器
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // 内部寄存器
    reg [13:0] baud_counter; 
    reg [2:0] bit_counter;   
    reg [7:0] shift_reg;     

    // ==================== 第一段：状态寄存器（时序逻辑） ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // ==================== 第二段：次态逻辑（组合逻辑） ====================
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (valid) 
                    next_state = START;
                else 
                    next_state = IDLE;
            end
            
            START: begin
                if (baud_counter == DIVIDER) 
                    next_state = DATA;
                else 
                    next_state = START;
            end
            
            DATA: begin
                if ((baud_counter == DIVIDER) && (bit_counter == 3'd7)) 
                    next_state = STOP;
                else 
                    next_state = DATA;
            end
            
            STOP: begin
                if (baud_counter == DIVIDER) 
                    next_state = IDLE;
                else 
                    next_state = STOP;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // ==================== 第三段：输出逻辑（时序逻辑） ====================
    // dout 输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= 1'b1;
        end else begin
            case (current_state)
                IDLE: begin
                    dout <= 1'b1;
                end
                
                START: begin
                    dout <= 1'b0;
                end
                
                DATA: begin
                    dout <= shift_reg[0];
                end
                
                STOP: begin
                    dout <= 1'b1;
                end
                
                default: begin
                    dout <= 1'b1;
                end
            endcase
        end
    end

    // ready 输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ready <= 1'b1;
        end else begin
            if (current_state == IDLE && !valid) begin
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end

    // baud_counter 输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_counter <= 14'd0;
        end else begin
            if (current_state == IDLE) begin
                baud_counter <= 14'd0;
            end else begin
                if (baud_counter == DIVIDER) begin
                    baud_counter <= 14'd0;
                end else begin
                    baud_counter <= baud_counter + 14'd1;
                end
            end
        end
    end

    // bit_counter 输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 3'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    bit_counter <= 3'd0;
                end
                
                START: begin
                    if (baud_counter == DIVIDER) begin
                        bit_counter <= 3'd0;
                    end
                end
                
                DATA: begin
                    if (baud_counter == DIVIDER) begin
                        bit_counter <= bit_counter + 3'd1;
                    end
                end
                
                STOP: begin
                    if (baud_counter == DIVIDER) begin
                        bit_counter <= 3'd0;
                    end
                end
                
                default: begin
                    bit_counter <= 3'd0;
                end
            endcase
        end
    end

    // shift_reg 输出逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    if (valid) begin
                        shift_reg <= data;
                    end
                end
                
                DATA: begin
                    if (baud_counter == DIVIDER) begin
                        shift_reg <= {1'b0, shift_reg[7:1]};
                    end
                end
                
                default: begin
                    // 其他状态保持shift_reg不变
                end
            endcase
        end
    end

endmodule