module toggle_ff(
    input wire clk,
    input wire rst,
    input wire toggle,
    output reg out
);

    reg toggle_delay;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 1'b0;
            toggle_delay <= 1'b0;
        end else begin
            toggle_delay <= toggle;
            
            // 检测上升沿
            if (toggle & ~toggle_delay)
                out <= ~out;
        end
    end

endmodule