`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/24 16:59:56
// Design Name: 
// Module Name: reg8file
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


module reg8file (
    input  wire clk,  
    input  wire clr,    
    input  wire en,
    input  wire [7:0] d,
    input  wire [2:0] wsel,
    input  wire [2:0] rsel,
    output reg  [7:0] q    
);
reg [7:0] regfile [7:0];
always @(posedge clk or posedge clr) begin
    if (clr == 1'b1) begin
        // 复位时：所有8个寄存器直接清零（无需时钟，异步生效）
        regfile[0] <= 8'b0;
        regfile[1] <= 8'b0;
        regfile[2] <= 8'b0;
        regfile[3] <= 8'b0;
        regfile[4] <= 8'b0;
        regfile[5] <= 8'b0;
        regfile[6] <= 8'b0;
        regfile[7] <= 8'b0;
    end else if (en == 1'b1) begin
        // 写使能有效时：在时钟上升沿，将输入d写入wsel指定的寄存器
        regfile[wsel] <= d;
    end
    // 若en=0：不执行写操作，寄存器保持原有值（无需额外代码，默认行为）
end

// 组合逻辑：异步读操作（地址变化时，输出立即更新）
always @(*) begin
    q = regfile[rsel]; // 直接读取rsel指定的寄存器值，无时钟延迟
end

endmodule
