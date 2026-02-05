`timescale 1ns / 1ps

module tb_uart_string_match();

reg clk;
reg rst;
reg uart_rx;
wire uart_tx;

// 实例化顶层模块
top u_top(
    .clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .uart_tx(uart_tx)
);

// 时钟生成：100MHz
always #5 clk = ~clk;

// 串口发送任务：9600bps, 104.16us per bit
task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
        // 起始位
        uart_rx = 1'b0;
        #10416;
        
        // 数据位（LSB first）
        for(i=0; i<8; i=i+1) begin
            uart_rx = data[i];
            #10416;
        end
        
        // 停止位
        uart_rx = 1'b1;
        #10416;
    end
endtask

// 串口接收监控
reg [7:0] received_data;
reg data_valid;
integer bit_count;
real bit_time = 10416.0; // 9600bps 对应的时间

always @(negedge uart_tx) begin
    if(uart_tx === 1'b0) begin // 检测到起始位
        #(bit_time/2); // 等待到比特中间采样
        data_valid = 0;
        received_data = 8'd0;
        for(bit_count=0; bit_count<8; bit_count=bit_count+1) begin
            #bit_time;
            received_data[bit_count] = uart_tx;
        end
        #bit_time; // 停止位
        data_valid = 1;
        #1 data_valid = 0;
    end
end

// 监控输出
always @(posedge data_valid) begin
    case(received_data)
        8'h30: $display("    收到回复: 0 (未匹配)");
        8'h31: $display("    收到回复: 1 (匹配start)");
        8'h32: $display("    收到回复: 2 (匹配stop)");
        8'h33: $display("    收到回复: 3 (匹配hitsz)");
        default: $display("    收到回复: 0x%h", received_data);
    endcase
end

// 测试用例
initial begin
    // 初始化
    clk = 0;
    rst = 1;
    uart_rx = 1;
    
    // 复位
    #100 rst = 0;
    #100;
    
    $display("=== 开始字符串匹配测试 ===");
    
    // 测试用例1: 匹配 "start"
    $display("[测试1] 发送: start");
    uart_send_byte("s");
    uart_send_byte("t");
    uart_send_byte("a");
    uart_send_byte("r");
    uart_send_byte("t");
    #200000;
    
    // 测试用例2: 匹配 "stop"  
    $display("[测试2] 发送: stop");
    uart_send_byte("s");
    uart_send_byte("t");
    uart_send_byte("o");
    uart_send_byte("p");
    #200000;
    
    // 测试用例3: 匹配 "hitsz"
    $display("[测试3] 发送: hitsz");
    uart_send_byte("h");
    uart_send_byte("i");
    uart_send_byte("t");
    uart_send_byte("s");
    uart_send_byte("z");
    #200000;
    
    // 测试用例4: 未匹配字符串
    $display("[测试4] 发送: hello");
    uart_send_byte("h");
    uart_send_byte("e");
    uart_send_byte("l");
    uart_send_byte("l");
    uart_send_byte("o");
    #200000;
    
    // 测试用例5: 连续测试 - start后立即跟stop
    $display("[测试5] 连续发送: startstop");
    uart_send_byte("s");
    uart_send_byte("t");
    uart_send_byte("a");
    uart_send_byte("r");
    uart_send_byte("t");
    uart_send_byte("s");
    uart_send_byte("t");
    uart_send_byte("o");
    uart_send_byte("p");
    #200000;
    
    // 测试用例6: 部分匹配后中断
    $display("[测试6] 发送: starthitsz");
    uart_send_byte("s");
    uart_send_byte("t");
    uart_send_byte("a");
    uart_send_byte("r");
    uart_send_byte("t");
    uart_send_byte("h");
    uart_send_byte("i");
    uart_send_byte("t");
    uart_send_byte("s");
    uart_send_byte("z");
    #200000;
    
    $display("=== 测试完成 ===");
    $finish;
end

// === 添加这部分代码 ===
// 生成VCD文件用于波形分析
initial begin
    $dumpfile("uart_string_match.vcd");
    $dumpvars(0, tb_uart_string_match);
end

endmodule