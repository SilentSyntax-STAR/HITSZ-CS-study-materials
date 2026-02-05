`timescale 1ns / 1ps

module reg8file_tb ();

    reg clk;
    reg clr;
    reg en;
    reg [2:0] wsel;  
    reg [2:0] rsel;  
    reg [7:0] d;
    wire [7:0] q;

    reg8file u_reg8file (
        .clk(clk),   // 时钟连接
        .clr(clr),   // 复位连接
        .en(en),     // 写使能连接
        .wsel(wsel), // 写地址连接
        .rsel(rsel), // 读地址连接
        .d(d),       // 写入数据连接
        .q(q)        // 读出数据连接
    );


    initial begin
        clk = 1'b0;          // 初始时钟为0
        forever #10 clk = ~clk; // 每10ns翻转一次（时钟周期20ns，50MHz）
    end

    // ------------------- 测试激励序列 -------------------
    initial begin
        // 阶段1：复位测试（异步清零所有寄存器）
        clr = 1'b1;  // 复位有效（高电平）
        en  = 1'b0;  // 写使能关闭
        wsel = 3'b000;
        rsel = 3'b000;
        d    = 8'h00;
        #20;  // 等待20ns（1个时钟周期），观察复位效果

        // 阶段2：写操作测试（向不同寄存器写入数据）
        clr = 1'b0;  // 释放复位
        en  = 1'b1;  // 使能写操作

        wsel = 3'b000; // 写“第0号寄存器”
        d    = 8'hAA;  // 写入数据0xAA
        #20;           // 时钟上升沿触发写操作

        wsel = 3'b001; // 写“第1号寄存器”
        d    = 8'h55;  // 写入数据0x55
        #20;

        wsel = 3'b010; // 写“第2号寄存器”
        d    = 8'hFF;  // 写入数据0xFF
        #20;

        // 阶段3：读操作测试（关闭写使能，读不同寄存器）
        en = 1'b0;     // 关闭写使能

        rsel = 3'b000; // 读“第0号寄存器”（预期q=0xAA）
        #20;

        rsel = 3'b001; // 读“第1号寄存器”（预期q=0x55）
        #20;

        rsel = 3'b010; // 读“第2号寄存器”（预期q=0xFF）
        #20;

        // 阶段4：覆盖写测试（重新写第0号寄存器）
        en = 1'b1;
        wsel = 3'b000;
        d    = 8'hCC;  // 写入新数据0xCC
        #20;

        en = 1'b0;
        rsel = 3'b000; // 读“第0号寄存器”（预期q=0xCC）
        #20;

        // 阶段5：再次复位测试（验证异步清零）
        clr = 1'b1;    // 复位有效
        #20;

        clr = 1'b0;
        rsel = 3'b000; // 读“第0号寄存器”（预期q=0x00）
        #20;

        $finish; // 结束仿真
    end

    // ------------------- 调试辅助：打印信号 -------------------
    always @(posedge clk) begin
        $display("Time=%t: clr=%b, en=%b, wsel=%b, rsel=%b, d=%h, q=%h", 
                 $time, clr, en, wsel, rsel, d, q);
    end

endmodule