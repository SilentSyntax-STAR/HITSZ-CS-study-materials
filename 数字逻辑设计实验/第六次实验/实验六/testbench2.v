`timescale 1ns / 1ps

module tb_student_id();

reg clk;
reg rst;
reg trigger;
wire [7:0] tx_data;
wire tx_valid;
wire dout;
wire ready;

// 实例化学生学号发送模块
student_id_sender uut (
    .clk(clk),
    .rst(rst),
    .trigger(trigger),
    .uart_ready(ready),
    .tx_data(tx_data),
    .tx_valid(tx_valid)
);

// 实例化UART发送模块用于验证
uart_send uart_tx (
    .clk(clk),
    .rst(rst),
    .valid(tx_valid),
    .data(tx_data),
    .dout(dout),
    .ready(ready)
);

// 时钟生成 - 100MHz
always #5 clk = ~clk;

// 监控接收到的字符
reg [7:0] received_data [0:9];
integer received_count;
reg [7:0] current_char;

always @(posedge clk) begin
    if (tx_valid) begin
        received_data[received_count] = tx_data;
        current_char = tx_data;
        received_count = received_count + 1;
    end
end

initial begin
    // 初始化
    clk = 0;
    rst = 1;
    trigger = 0;
    received_count = 0;
    current_char = 0;
    
    // 复位
    #100;
    rst = 0;
    #100;
    
    $display("=== 开始个人学号发送仿真 ===");
    $display("时间: %t", $time);
    
    // 等待UART发送模块就绪
    wait(ready == 1'b1);
    $display("UART发送模块已就绪");
    
    // 模拟按键触发
    #100;
    trigger = 1;
    #1000; // 保持触发信号一段时间
    trigger = 0;
    
    $display("触发信号已发送");
    
    // 等待发送完成 (10个字符)
    #500000; // 等待足够长时间确保所有字符发送完成
    
    // 显示接收到的学号
    $display("=== 接收到的个人学号 ===");
    $display("学号长度: %0d 个字符", received_count);
    
    for (integer i = 0; i < received_count; i = i + 1) begin
        $display("字符 %0d: 0x%h -> ASCII: '%s'", 
                i, received_data[i], received_data[i]);
    end
    
    // 验证学号正确性
    if (received_count == 10 && 
        received_data[0] == "2" &&
        received_data[1] == "0" &&
        received_data[2] == "2" &&
        received_data[3] == "4" &&
        received_data[4] == "3" &&
        received_data[5] == "1" &&
        received_data[6] == "1" &&
        received_data[7] == "6" &&
        received_data[8] == "6" &&
        received_data[9] == "8") begin
        $display("=== 验证结果: PASS ===");
        $display("学号 '2024311668' 发送正确!");
    end else begin
        $display("=== 验证结果: FAIL ===");
        $display("学号发送不正确!");
    end
    
    #1000;
    $finish;
end

// 实时监控状态变化
always @(posedge clk) begin
    if (tx_valid) begin
        $display("时间 %t: 发送字符 0x%h ('%s')", $time, tx_data, tx_data);
    end
end

endmodule