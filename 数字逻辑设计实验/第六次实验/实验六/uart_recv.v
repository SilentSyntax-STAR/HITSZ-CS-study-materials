`timescale 1ns / 1ps

module uart_recv(
    input clk,
    input rst,
    input din,
    output reg valid,
    output reg [7:0] data
);

    // 状态定义
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;
    
    // 波特率参数 - 修正计算
    localparam CLK_FREQ = 100_000_000;//100MHz
    localparam BAUD_RATE = 9600;//波特率
    localparam BIT_CYCLES = CLK_FREQ / BAUD_RATE;  // 10416
    localparam BIT_CYCLES_HALF = BIT_CYCLES / 2;   // 5208
    
    // 状态寄存器
    reg [2:0] current_state, next_state;
    
    // 计数器
    reg [13:0] bit_counter;
    reg [2:0] bit_index;
    reg [7:0] data_shift;
    
    // 输入同步寄存器，防止亚稳态
     reg din_sync1, din_sync2, din_sync3;
    
      always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_sync1 <= 1'b1;
            din_sync2 <= 1'b1;
            din_sync3 <= 1'b1;
        end else begin
            din_sync1 <= din;      // 第一级同步
            din_sync2 <= din_sync1; // 第二级同步
            din_sync3 <= din_sync2; // 第三级同步
        end
    end
    
    // ==================== 状态转移逻辑 ====================
    always @(posedge clk or posedge rst) begin
        if (rst) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end
    
    // ==================== 下一状态逻辑 ====================
    always @(*) begin
        case (current_state)
            IDLE:  next_state = (!din_sync2) ? START : IDLE;  // 检测起始位
            START: next_state = (bit_counter == BIT_CYCLES - 1) ? DATA : START;  // 修正条件
            DATA:  next_state = (bit_index == 3'd7 && bit_counter == BIT_CYCLES - 1) ? STOP : DATA;
            STOP:  next_state = (bit_counter == BIT_CYCLES - 1) ? IDLE : STOP;
            default: next_state = IDLE;
        endcase
    end
    
    // ==================== 位计数器控制 ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_counter <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    bit_counter <= 0;
                end
                
                START, DATA, STOP: begin
                    if (bit_counter < BIT_CYCLES - 1)
                        bit_counter <= bit_counter + 1;
                    else
                        bit_counter <= 0;
                end
                
                default: begin
                    bit_counter <= 0;
                end
            endcase
        end
    end
    
    // ==================== 位索引控制 ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_index <= 0;
        end else begin
            if (current_state == DATA) begin
                if (bit_counter == BIT_CYCLES - 1) begin
                    if (bit_index < 3'd7)
                        bit_index <= bit_index + 1;
                    else
                        bit_index <= 0;
                end
            end else begin
                bit_index <= 0;
            end
        end
    end
    
    // ==================== 数据移位控制 ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_shift <= 0;
        end else begin
            if (current_state == DATA) begin
                if (bit_counter == BIT_CYCLES_HALF - 1) begin  // 在数据位中间采样
                    data_shift <= {din_sync3, data_shift[7:1]};
                end
            end else if (current_state == IDLE) begin
                data_shift <= 0;
            end
        end
    end
   
    // ==================== 有效信号控制 ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 1'b0;
        end else begin
            valid <= 1'b0;  // 默认valid为0
            
            if (current_state == STOP) begin
                if (bit_counter == BIT_CYCLES_HALF - 1) begin
                    valid <= 1'b1;  // 在停止位中间时刻输出有效数据
                end
            end
        end
    end
    
    // ==================== 数据输出控制 ====================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data <= 8'b0;
        end else begin
            if (current_state == STOP) begin
                if (bit_counter == BIT_CYCLES_HALF - 1) begin
                    data <= data_shift;  // 在停止位中间时刻输出数据
                end
            end
        end
    end

endmodule