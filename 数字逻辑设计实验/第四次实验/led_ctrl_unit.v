module led_ctrl_unit(
    input wire rst,
    input wire clk,
    input wire [31:0] display,  // 待显示的8个十六进制字符
    input wire enable,          // 整体使能信号
    output reg [7:0] led_en,    // 位选信号
    output reg [7:0] led_cx     // 段选信号
);

    // 分频计数器 - 1ms刷新周期 (100MHz -> 1ms)
    // 修复：99,999需要17位，不是16位
    reg [16:0] refresh_counter;  // 改为17位
    wire refresh_tick;
    
    // 数码管选择计数器
    reg [2:0] digit_select;
    
    // 七段数码管编码表 (共阴极)
    parameter [7:0] SEG_0  = 8'b00000011; // 0
    parameter [7:0] SEG_1  = 8'b10011111; // 1
    parameter [7:0] SEG_2  = 8'b00100101; // 2
    parameter [7:0] SEG_3  = 8'b00001101; // 3
    parameter [7:0] SEG_4  = 8'b10011001; // 4
    parameter [7:0] SEG_5  = 8'b01001001; // 5
    parameter [7:0] SEG_6  = 8'b01000001; // 6
    parameter [7:0] SEG_7  = 8'b00011111; // 7
    parameter [7:0] SEG_8  = 8'b00000001; // 8
    parameter [7:0] SEG_9  = 8'b00001001; // 9
    parameter [7:0] SEG_A  = 8'b00010001; // A
    parameter [7:0] SEG_B  = 8'b11000001; // b
    parameter [7:0] SEG_C  = 8'b01100011; // C
    parameter [7:0] SEG_D  = 8'b10000101; // d
    parameter [7:0] SEG_E  = 8'b01100001; // E
    parameter [7:0] SEG_F  = 8'b01110001; // F
    parameter [7:0] SEG_OFF= 8'b11111111; // 熄灭
    
    // 1ms刷新计数器
    always @(posedge clk or posedge rst) begin
        if (rst)
            refresh_counter <= 17'd0;
        else
            refresh_counter <= refresh_counter + 17'd1;
    end
    
    assign refresh_tick = (refresh_counter == 17'd99_999); // 100,000 cycles = 1ms
    
    // 数码管选择计数器
    always @(posedge clk or posedge rst) begin
        if (rst)
            digit_select <= 3'd0;
        else if (refresh_tick)
            digit_select <= digit_select + 3'd1;
    end
    
    // 位选信号生成
    always @(*) begin
        if (!enable) begin
            led_en = 8'b11111111; // 全部熄灭
        end else begin
            case (digit_select)
                3'd0: led_en = 8'b11111110; // DK0
                3'd1: led_en = 8'b11111101; // DK1
                3'd2: led_en = 8'b11111011; // DK2
                3'd3: led_en = 8'b11110111; // DK3
                3'd4: led_en = 8'b11101111; // DK4
                3'd5: led_en = 8'b11011111; // DK5
                3'd6: led_en = 8'b10111111; // DK6
                3'd7: led_en = 8'b01111111; // DK7
                default: led_en = 8'b11111111;
            endcase
        end
    end
    
    // 段选信号生成
    always @(*) begin
        case (display[{digit_select, 2'b0} +: 4]) // 选择当前数码管对应的4位数据
            4'h0: led_cx = SEG_0;
            4'h1: led_cx = SEG_1;
            4'h2: led_cx = SEG_2;
            4'h3: led_cx = SEG_3;
            4'h4: led_cx = SEG_4;
            4'h5: led_cx = SEG_5;
            4'h6: led_cx = SEG_6;
            4'h7: led_cx = SEG_7;
            4'h8: led_cx = SEG_8;
            4'h9: led_cx = SEG_9;
            4'hA: led_cx = SEG_A;
            4'hB: led_cx = SEG_B;
            4'hC: led_cx = SEG_C;
            4'hD: led_cx = SEG_D;
            4'hE: led_cx = SEG_E;
            4'hF: led_cx = SEG_F;
            default: led_cx = SEG_OFF;
        endcase
    end

endmodule