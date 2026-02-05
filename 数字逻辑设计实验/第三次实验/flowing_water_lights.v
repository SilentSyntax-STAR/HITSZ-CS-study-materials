`timescale 1ns / 1ps
module flowing_water_lights(
    input wire clk,   
    input wire rst,   
    input wire button,  
    input wire [1:0] freq_set, 
    input wire dir_set,   
    output reg [7:0] led  
);

    wire clk_en;         
    wire pos_edge_button;  
    reg running;          
      
    edge_detect u_edge_detect(
        .clk(clk),
        .rst(rst),
        .signal(button),
        .pos_edge(pos_edge_button)
    );

    clock_divider u_clock_divider(
        .clk(clk),
        .rst(rst),
        .freq_set(freq_set),
        .clk_en(clk_en)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            running <= 1'b0;
        end else if (pos_edge_button) begin
            running <= ~running; 
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led <= 8'b00000001;
        end else if (clk_en && running) begin
            if (dir_set) begin
  
                led <= {led[6:0], led[7]};
            end else begin

                led <= {led[0], led[7:1]};
            end
        end
    end

endmodule
