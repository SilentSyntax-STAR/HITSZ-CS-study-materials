`timescale 1ns / 1ps

module uart_top(
    input wire clk,
    input wire rst,
    input wire [7:0] data1,
    input wire valid1,
    output reg valid2,
    output reg [7:0] data2
);
    
reg [30:0] baud_cnt;
localparam BAUD_MAX = 30'd20000000;
wire baud_done = (baud_cnt == BAUD_MAX - 1);

reg flag,f;

localparam S0 = 4'b0000;  
localparam S1 = 4'b0001;  
localparam S2 = 4'b0010;   
localparam S3 = 4'b0011;  
localparam S4 = 4'b0100;  
localparam S5 = 4'b0101;  
localparam S6 = 4'b0110;   
localparam S7 = 4'b0111;  
localparam S8 = 4'b1000;  
localparam S9 = 4'b1001;  
localparam S10 = 4'b1010;   
localparam S11 = 4'b1011;  
localparam S12 = 4'b1100;  
localparam S  = 8'h73;  // 's' - 115 (0x73)
localparam T  = 8'h74;  // 't' - 116 (0x74)  
localparam O  = 8'h6F;  // 'o' - 111 (0x6F)
localparam P  = 8'h70;  // 'p' - 112 (0x70)
localparam A  = 8'h61;  // 'a' - 97  (0x61)
localparam R  = 8'h72;  // 'r' - 114 (0x72)
localparam H  = 8'h68;  // 'h' - 104 (0x68)
localparam I  = 8'h69;  // 'i' - 105 (0x69)
localparam Z  = 8'h7A;  // 'z' - 122 (0x7A)

reg [3:0] current_state;
reg [3:0] next_state;

//状态寄存器（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= S0;
    end else begin
        current_state <= next_state;
    end
end

//次态逻辑（组合逻辑）
always @(*) begin
    if(!valid1)next_state = current_state;
    else if(baud_done)next_state = S0;
    else begin
    case (current_state)
        S0: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else next_state = S0;
        end
        S1: begin
            if (data1==T)next_state = S2;
            else if(data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else next_state = S0;
        end
        S2: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==O)next_state = S3;
            else if(data1==A)next_state = S5;
            else next_state = S0;
        end
        S3: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==P)next_state = S4;
            else next_state = S0;
        end
        S4: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else next_state = S0;
        end
        S5: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==R)next_state = S6;
            else next_state = S0;
        end
        S6: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==T)next_state = S7;
            else next_state = S0;
        end
        S7: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else next_state = S0;
        end
        S8: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==I)next_state = S9;
            else next_state = S0;
        end
        S9: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==T)next_state = S10;
            else next_state = S0;
        end
        S10: begin
            if (data1==S)next_state = S11;
            else if(data1==H)next_state = S8;
            else next_state = S0;
        end
        S11: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else if(data1==Z)next_state = S12;
            else if(data1==T)next_state = S2;
            else next_state = S0;
        end
        S12: begin
            if (data1==S)next_state = S1;
            else if(data1==H)next_state = S8;
            else next_state = S0;
        end
        default: next_state = S0;
    endcase
    end
end

//输出逻辑（时序逻辑）
always @ (posedge clk or posedge rst) begin
    if(rst)valid2<=0;
    else if(valid1)begin
        if(current_state==S3 && data1==P)valid2<=1;
        else if(current_state==S6 && data1==T)valid2<=1;
        else if(current_state==S11 && data1==Z)valid2<=1;
        else valid2<=0;
    end
    else if(baud_done && !flag)valid2<=1;
    else valid2<=0;
end

always @ (posedge clk or posedge rst) begin
    if(rst)data2<=0;
    else if(valid1)begin
        if(current_state==S3 && data1==P)data2<=8'h32;
        else if(current_state==S6 && data1==T)data2<=8'h31;
        else if(current_state==S11 && data1==Z)data2<=8'h33;
        else data2<=0;
    end
    else if(baud_done && !flag)data2<=8'h30;
    else data2<=0;
end
// 超时计数器（时序逻辑）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_cnt <= 14'd0;
    end else begin
        if (valid1) begin
            baud_cnt <= 14'd0;
        end else if (baud_done) begin
            baud_cnt <= 14'd0;
        end else begin
            baud_cnt <= baud_cnt + 1'b1;
        end
    end
end
// 标志位控制逻辑（时序逻辑）
always @ (posedge clk or posedge rst) begin
    if(rst)flag<=0;
    else if(valid2)flag<=1;
    else if(!f && valid1)flag<=0;
    else flag<=flag;
end
// 新数据标志（时序逻辑）
always @ (posedge clk or posedge rst) begin
    if(rst)f<=0;
    else if(valid1)f<=1;
    else if(baud_done)f<=0;
    else f<=f;
end
endmodule
