`timescale 1ns / 1ps

module tb_flowing_water_lights;

    // 激励信号定义
    reg clk;
    reg rst;
    reg button;
    reg [1:0] freq_set;
    reg dir_set;
    // 输出信号监测
    wire [7:0] led;
    // 内部信号监测（方便调试）
    wire clk_en;
    wire pos_edge_button;
    wire running;

    // 例化顶层模块
    flowing_water_lights uut (
        .clk(clk),
        .rst(rst),
        .button(button),
        .freq_set(freq_set),
        .dir_set(dir_set),
        .led(led)
    );

    // 绑定内部信号（用于监控，需根据实际模块层次调整）
    assign clk_en = uut.clk_en;
    assign pos_edge_button = uut.pos_edge_button;
    assign running = uut.running;

    // 生成100MHz时钟（周期10ns）
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;  // 每5ns翻转一次
    end

    // 仿真测试流程（优化版：缩短等待时间，确保LED多次移位）
    initial begin
        // 1. 初始化：复位有效，所有输入置默认值
        rst = 1'b1;
        button = 1'b0;
        freq_set = 2'b00;  // 初始100Hz（仿真中实际更快）
        dir_set = 1'b0;    // 初始右移
        #20;               // 复位保持20ns（2个时钟周期）

        // 2. 释放复位（进入初始状态：LED0亮，running=0）
        rst = 1'b0;
        #10;               // 等待10ns稳定

        // 3. 第一次按button：启动流水灯（上升沿触发）
        // 按钮动作：0→1（10ns）→0，确保边沿检测能捕捉
        button = 1'b1;
        #10;
        button = 1'b0;
        // 等待足够多的移位周期（当前freq_set=00，仿真中加速后约10us移位一次）
        #100000;  // 100,000ns = 0.1ms，足够观察5-10次移位

        // 4. 切换方向为左移（dir_set=1）
        dir_set = 1'b1;
        #100000;  // 再观察5-10次左移

        // 5. 切换频率为10Hz（freq_set=01，仿真中周期更长但仍可观察）
        freq_set = 2'b01;
        #200000;  // 等待200,000ns，观察移位变慢

        // 6. 第二次按button：暂停流水灯
        button = 1'b1;
        #10;
        button = 1'b0;
        #50000;   // 暂停50,000ns，LED应保持不变

        // 7. 第三次按button：重新启动
        button = 1'b1;
        #10;
        button = 1'b0;
        #150000;  // 再观察几次移位

        // 8. 切换频率为4Hz（freq_set=10）
        freq_set = 2'b10;
        #300000;  // 观察更低频率的移位

        // 9. 复位测试：强制回到初始状态
        rst = 1'b1;
        #20;
        rst = 1'b0;
        #50000;   // 观察LED是否复位为00000001

        // 结束仿真
        $finish;
    end

    // 波形记录（保存所有信号，方便用波形工具查看）
    initial begin
        $dumpfile("tb_flowing_water_lights.vcd");
        $dumpvars(0, tb_flowing_water_lights);  // 记录整个测试模块的信号
    end

    // 实时打印关键信号（终端输出，直观观察变化）
    initial begin
        $monitor(
            "Time=%0tns, 复位=%b, 运行状态=%b, 方向=%b, 频率设置=%b, 分频使能=%b, LED输出=%b",
            $time, rst, running, dir_set, freq_set, clk_en, led
        );
    end

endmodule