`timescale 1ns / 1ps

module uart_send(
    input clk,
    input rst,
    input valid,        
    input [7:0] data,   
    output reg dout
);

localparam IDLE  = 2'b00;   
localparam START = 2'b01;   
localparam DATA  = 2'b10;   
localparam STOP  = 2'b11;   


reg [1:0] current_state;
reg [1:0] next_state;


localparam CLOCK_FREQ = 100_000_000;  
localparam BAUD_RATE = 9600;
localparam DIVIDER = CLOCK_FREQ / BAUD_RATE - 1;  

reg [13:0] baud_counter; 
reg baud_tick;           


reg [2:0] bit_counter;   
reg [7:0] shift_reg;     


// µÚÒ»¶Î£º×´Ì¬¼Ä´æÆ÷£¨Ê±ÐòÂß¼­£©
always @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// µÚ¶þ¶Î£º´ÎÌ¬Âß¼­£¨×éºÏÂß¼­£©
always @(*) begin
    case (current_state)
        IDLE: begin
            if (valid) 
                next_state = START;
            else 
                next_state = IDLE;
        end
        
        START: begin
            if (baud_tick) 
                next_state = DATA;
            else 
                next_state = START;
        end
        
        DATA: begin
            if (baud_tick && (bit_counter == 3'd7)) 
                next_state = STOP;
            else 
                next_state = DATA;
        end
        
        STOP: begin
            if (baud_tick) 
                next_state = IDLE;
            else 
                next_state = STOP;
        end
        
        default: next_state = IDLE;
    endcase
end

// µÚÈý¶Î£ºdoutÊä³öÂß¼­£¨Ê±ÐòÂß¼­£©
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dout <= 1'b1;
    end else begin
        case (current_state)
            IDLE: begin
                dout <= 1'b1;
            end
            
            START: begin
                dout <= 1'b0;
            end
            
            DATA: begin
                dout <= shift_reg[0];
            end
            
            STOP: begin
                dout <= 1'b1;
            end
            
            default: begin
                dout <= 1'b1;
            end
        endcase
    end
end

// µÚËÄ¶Î£ºbaud_counterÊä³öÂß¼­£¨Ê±ÐòÂß¼­£©
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_counter <= 14'd0;
    end else begin
        if (current_state == IDLE) begin
            baud_counter <= 14'd0;
        end else begin
            if (baud_counter == DIVIDER) begin
                baud_counter <= 14'd0;
            end else begin
                baud_counter <= baud_counter + 14'd1;
            end
        end
    end
end

// µÚÎå¶Î£ºbaud_tickÊä³öÂß¼­£¨Ê±ÐòÂß¼­£©
always @(posedge clk or posedge rst) begin
    if (rst) begin
        baud_tick <= 1'b0;
    end else begin
        if (current_state == IDLE) begin
            baud_tick <= 1'b0;
        end else begin
            if (baud_counter == DIVIDER) begin
                baud_tick <= 1'b1;
            end else begin
                baud_tick <= 1'b0;
            end
        end
    end
end

// µÚÁù¶Î£ºbit_counterÊä³öÂß¼­£¨Ê±ÐòÂß¼­£©
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bit_counter <= 3'd0;
    end else begin
        case (current_state)
            IDLE: begin
                bit_counter <= 3'd0;
            end
            
            START: begin
                if (baud_tick) begin
                    bit_counter <= 3'd0;
                end
            end
            
            DATA: begin
                if (baud_tick) begin
                    bit_counter <= bit_counter + 3'd1;
                end
            end
            
            STOP: begin
                if (baud_tick) begin
                    bit_counter <= 3'd0;
                end
            end
            
            default: begin
                bit_counter <= 3'd0;
            end
        endcase
    end
end

// µÚÆß¶Î£ºshift_regÊä³öÂß¼­£¨Ê±ÐòÂß¼­£©
always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift_reg <= 8'd0;
    end else begin
        case (current_state)
            IDLE: begin
                if (valid) begin
                    shift_reg <= data;
                end
            end
            
            DATA: begin
                if (baud_tick) begin
                    shift_reg <= {1'b0, shift_reg[7:1]};
                end
            end
            
            default: begin
                // ÆäËû×´Ì¬±£³Öshift_reg²»±ä
            end
        endcase
    end
end

endmodule