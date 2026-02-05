module edge_detector(
    input wire clk,
    input wire rst,
    input wire signal_in,
    output wire pos_edge
);

    reg signal_delay;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            signal_delay <= 1'b0;
        else
            signal_delay <= signal_in;
    end
    
    assign pos_edge = signal_in & ~signal_delay;

endmodule