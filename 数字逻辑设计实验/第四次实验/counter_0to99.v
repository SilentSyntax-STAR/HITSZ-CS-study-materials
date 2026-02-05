
module counter_0to99(
    input wire clk,
    input wire rst,
    input wire en,
    output reg [6:0] count  // 7Î»£¬Ö§³Ö0-99
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            count <= 7'd0;
        else if (en) begin
            if (count >= 7'd99)
                count <= 7'd0;
            else
                count <= count + 7'd1;
        end
    end

endmodule
