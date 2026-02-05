
module decimal_counter(
    input wire clk,
    input wire rst,
    input wire enable,
    output reg [4:0] count,
    output wire [3:0] display_ten,  // 十位显示
    output wire [3:0] display_unit  // 个位显示
);

    // 0.1s计数器 (100MHz -> 0.1s需要10,000,000个周期)
    parameter COUNT_INTERVAL = 25'd10_000_000;
    
    reg [24:0] timer;
    wire timer_tick;
    
    // 0.1s定时器
    always @(posedge clk or posedge rst) begin
        if (rst)
            timer <= 25'd0;
        else if (enable) begin
            if (timer >= COUNT_INTERVAL - 25'd1)
                timer <= 25'd0;
            else
                timer <= timer + 25'd1;
        end
    end
    
    assign timer_tick = (timer == COUNT_INTERVAL - 25'd1) & enable;
    
    // 0-30计数器
    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 5'd0;
        else if (timer_tick) begin
            if (count >= 5'd30)
                count <= 5'd0;
            else
                count <= count + 5'd1;
        end
    end
    
    // 十进制显示拆分
    assign display_ten = (count < 5'd10) ? 4'd0 : 
                        (count < 5'd20) ? 4'd1 : 
                        (count < 5'd30) ? 4'd2 : 4'd3;
    
    assign display_unit = (count < 5'd10) ? count[3:0] : 
                         (count < 5'd20) ? (count - 5'd10) : 
                         (count < 5'd30) ? (count - 5'd20) : 4'd0;

endmodule
