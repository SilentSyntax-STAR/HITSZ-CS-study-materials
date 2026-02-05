module uart_send(
    input        clk,        
    input        rst,        
    input        valid,       // 为1表明接下来的8位data有效，只维持一个时钟周期
    input [7:0]  data,        // 待发送的8位数据
    output reg   dout         // 发送信号
);

localparam IDLE  = 2'b00;   // 空闲态，发送高电平
localparam START = 2'b01;   // 起始态，发送起始位
localparam DATA  = 2'b10;   // 数据态，将8位数据位发送出去
localparam STOP  = 2'b11;   // 停止态，发送停止位

reg [1:0] current_state;
reg [1:0] next_state;

reg [2:0] bit_cnt;

reg [13:0] baud_cnt;
localparam BAUD_MAX = 14'd10416;
wire baud_done = (baud_cnt == BAUD_MAX - 1);

//状态寄存器（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

//次态逻辑（组合逻辑）
always @(*) begin
    case (current_state)
        IDLE: begin
            if (valid) begin
                next_state = START;
            end else begin
                next_state = IDLE;
            end
        end
        START: begin
            if (baud_done) begin
                next_state = DATA;
            end else begin
                next_state = START;
            end
        end
        DATA: begin
            if (baud_done && (bit_cnt == 3'd7)) begin
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

//输出逻辑 - 位计数器（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bit_cnt <= 3'd0;
    end else begin
        if (current_state == DATA) begin
            if (baud_done) begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end else begin
            bit_cnt <= 3'd0;
        end
    end
end
//数据锁存寄存器（时序逻辑）
reg [7:0] data_reg;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_reg <= 8'd0;
    end else begin
        if (valid && current_state == IDLE) begin
            data_reg <= data;
        end
    end
end
// 输出逻辑 - 串行数据输出（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dout <= 1'b1;
    end else begin
        case (current_state)
            IDLE:  dout <= 1'b1;
            START: dout <= 1'b0;
            DATA:  dout <= data_reg[bit_cnt];
            STOP:  dout <= 1'b1;
            default: dout <= 1'b1;
        endcase
    end
end

// 波特率计数器（时序逻辑）
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