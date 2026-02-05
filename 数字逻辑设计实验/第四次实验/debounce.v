
module debounce(
    input wire clk,
    input wire rst,
    input wire key_in,
    output reg key_out
);

    // 20ms消抖计数器 (100MHz -> 20ms需要2,000,000个周期)
    parameter DEBOUNCE_TIME = 21'd2_000_000;
    
    reg [20:0] counter;
    reg key_reg;
    reg key_stable;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 21'd0;
            key_reg <= 1'b0;
            key_stable <= 1'b0;
            key_out <= 1'b0;
        end else begin
            key_reg <= key_in;
            
            if (key_reg != key_stable) begin
                // 输入变化，重置计数器
                counter <= 21'd0;
                key_stable <= key_reg;
            end else if (counter < DEBOUNCE_TIME) begin
                // 计数中
                counter <= counter + 21'd1;
            end else begin
                // 计数完成，更新输出
                key_out <= key_stable;
            end
        end
    end

endmodule