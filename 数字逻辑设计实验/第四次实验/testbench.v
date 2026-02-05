`timescale 1ns / 1ps

module top_tb;

    // 输入信号
    reg clk;
    reg sw0;
    reg s1;     // 异步复位
    reg s2;     // 计数器启停控制
    reg s3;     // 计数按键
    
    // 输出信号
    wire [7:0] led_en;
    wire [7:0] led_cx;
    
    // 实例化顶层模块
    top uut (
        .clk(clk),
        .sw0(sw0),
        .s1(s1),
        .s2(s2),
        .s3(s3),
        .led_en(led_en),
        .led_cx(led_cx)
    );
    
    // 时钟生成 - 100MHz
    always #5 clk = ~clk;
    
    // 数码管段选信号解码函数
    function [7:0] decode_segment;
        input [7:0] seg;
        begin
            case (seg)
                8'b00000011: decode_segment = "0";
                8'b10011111: decode_segment = "1";
                8'b00100101: decode_segment = "2";
                8'b00001101: decode_segment = "3";
                8'b10011001: decode_segment = "4";
                8'b01001001: decode_segment = "5";
                8'b01000001: decode_segment = "6";
                8'b00011111: decode_segment = "7";
                8'b00000001: decode_segment = "8";
                8'b00001001: decode_segment = "9";
                8'b00010001: decode_segment = "A";
                8'b11000001: decode_segment = "b";
                8'b01100011: decode_segment = "C";
                8'b10000101: decode_segment = "d";
                8'b01100001: decode_segment = "E";
                8'b01110001: decode_segment = "F";
                8'b11111111: decode_segment = " ";
                default:     decode_segment = "?";
            endcase
        end
    endfunction
    
    integer i;
    reg [7:0] current_digit;
    
    initial begin
        // 初始化信号
        clk = 0;
        sw0 = 0;
        s1 = 1;  // 初始复位
        s2 = 1;  // 按键默认高电平（未按下）
        s3 = 1;  // 按键默认高电平（未按下）
        
        // 输出仿真信息
        $display("=== 开始仿真 ===");
        $display("时钟频率: 100MHz");
        $display("学号: 68");
        $display("================");
        
        // 释放复位
        #100 s1 = 0;
        sw0 = 1;  // 使能数码管显示
        
        $display("\n=== 测试1: 数码管轮询功能 ===");
        test_led_scan();
        
        $display("\n=== 测试2: 按键消抖功能 ===");
        test_debounce();
        
        $display("\n=== 测试3: 按键计数功能 ===");
        test_counter();
        
        $display("\n=== 仿真完成 ===");
        #1000000 $finish;
    end
    
    // 测试1: 数码管轮询
    task test_led_scan;
    begin
        $display("观察数码管轮询扫描...");
        $display("时间(ns) | 数码管使能 | 当前数码管 | 段选显示");
        $display("---------|------------|------------|----------");
        
        // 监测一轮完整的数码管扫描（8个数码管）
        for (i = 0; i < 8; i = i + 1) begin
            // 等待1ms刷新周期
            #1000000;
            
            // 解码当前显示的字符
            current_digit = decode_segment(led_cx);
            
            $display("%8t | %8b |     DK%d    |    %s", 
                     $time, led_en, i, current_digit);
        end
    end
    endtask
    
    // 测试2: 按键消抖
    task test_debounce;
    begin
        $display("模拟带抖动的S3按键输入...");
        $display("时间(ns) | S3输入");
        $display("---------|--------");
        
        // 初始状态
        s3 = 1;
        #100000;
        
        // 模拟按键按下时的抖动
        $display("按键按下抖动:");
        s3 = 0;  // 开始按下
        #100000; // 100us
        s3 = 1;  // 反弹
        #50000;  // 50us
        s3 = 0;  // 再次按下
        #80000;  // 80us
        s3 = 1;  // 再次反弹
        #60000;  // 60us
        s3 = 0;  // 稳定按下
        #2000000; // 保持2ms
        $display("%8t |   0 -> 1", $time);
        
        // 模拟按键释放时的抖动
        $display("按键释放抖动:");
        s3 = 1;  // 开始释放
        #70000;  // 70us
        s3 = 0;  // 反弹
        #40000;  // 40us
        s3 = 1;  // 再次释放
        #90000;  // 90us
        s3 = 0;  // 再次反弹
        #30000;  // 30us
        s3 = 1;  // 稳定释放
        #2000000; // 保持2ms
        $display("%8t |   1 -> 0", $time);
    end
    endtask
    
    // 测试3: 按键计数
    task test_counter;
    begin
        $display("模拟2次有效按键计数...");
        $display("时间(ns) | 按键动作 | 计数变化");
        $display("---------|----------|----------");
        
        // 初始状态
        s3 = 1;
        #1000000;
        
        $display("%8t | 初始状态 | 计数: 0", $time);
        
        // 第一次有效按键
        $display("%8t | 第一次按键 |", $time);
        s3 = 0;  // 按下
        #20000000; // 保持20ms（超过消抖时间）
        s3 = 1;  // 释放
        #20000000; // 保持20ms
        $display("%8t | 按键完成 | 计数: 1", $time);
        
        // 第二次有效按键
        $display("%8t | 第二次按键 |", $time);
        s3 = 0;  // 按下
        #20000000; // 保持20ms
        s3 = 1;  // 释放
        #20000000; // 保持20ms
        $display("%8t | 按键完成 | 计数: 2", $time);
        
        // 测试S2启停控制
        $display("\n测试S2启停控制...");
        $display("%8t | S2启动计数器 |", $time);
        s2 = 0;  // 按下
        #20000000; // 保持20ms
        s2 = 1;  // 释放
        #20000000; // 保持20ms
        $display("%8t | S2启动完成 |", $time);
        
        #50000000; // 等待50ms，观察十进制计数变化
        
        $display("%8t | S2停止计数器 |", $time);
        s2 = 0;  // 按下
        #20000000; // 保持20ms
        s2 = 1;  // 释放
        #20000000; // 保持20ms
        $display("%8t | S2停止完成 |", $time);
    end
    endtask

endmodule