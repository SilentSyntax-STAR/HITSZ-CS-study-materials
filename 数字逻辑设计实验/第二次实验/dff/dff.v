`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/24 16:00:13
// Design Name: 
// Module Name: dff
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module dff (
    input      clk,
    input      clr,
    input      en ,
    input      d  ,
    output reg q
);
always @(posedge clk or posedge clr) begin
    if (clr == 1'b1) begin  // 第一步：先看清零信号是否生效（1'b1表示二进制1）
        q <= 1'b0;          // 清零：q直接变成0（<=是时序赋值，必须用这个）
    end
    else if (en == 1'b1) begin  // 第二步：如果不清零，看使能是否允许
        q <= d;                 // 允许：在时钟上升沿，把d的值传给q（存数据）
    end
end
endmodule
