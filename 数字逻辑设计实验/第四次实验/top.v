
module top(
    input wire clk,
    input wire sw0,
    input wire s1,     // S1作为异步复位
    input wire s2,     // S2作为计数器启停控制
    input wire s3,     // S3作为计数按键
    output wire [7:0] led_en,
    output wire [7:0] led_cx
);

    // 学号后两位
    localparam STUDENT_ID_HIGH = 4'h6;  // 学号十位
    localparam STUDENT_ID_LOW  = 4'h8;  // 学号个位

    // 内部信号定义
    wire [6:0] count_no_debounce;    // 无消抖计数 (0-99)
    wire [6:0] count_with_debounce;  // 有消抖计数 (0-99)
    wire [4:0] decimal_count;        // 十进制计数 (0-30)
    wire [3:0] decimal_ten;          // 十进制十位
    wire [3:0] decimal_unit;         // 十进制个位
    wire debounced_s3;               // 消抖后的S3信号
    wire debounced_s2;               // 消抖后的S2信号
    wire s3_edge;                    // S3边沿检测
    wire s3_debounced_edge;          // 消抖后S3边沿检测
    wire s2_debounced_edge;          // 消抖后S2边沿检测
    wire counter_enable;             // 计数器使能
    
    // S2按键消抖模块实例化
    debounce u_debounce_s2(
        .clk(clk),
        .rst(s1),
        .key_in(s2),
        .key_out(debounced_s2)
    );
    
    // S3按键消抖模块实例化
    debounce u_debounce_s3(
        .clk(clk),
        .rst(s1),
        .key_in(s3),
        .key_out(debounced_s3)
    );
    
    // 边沿检测模块实例化
    edge_detector u_edge_detector_s3(
        .clk(clk),
        .rst(s1),
        .signal_in(s3),
        .pos_edge(s3_edge)
    );
    
    edge_detector u_edge_detector_s3_debounced(
        .clk(clk),
        .rst(s1),
        .signal_in(debounced_s3),
        .pos_edge(s3_debounced_edge)
    );
    
    edge_detector u_edge_detector_s2_debounced(
        .clk(clk),
        .rst(s1),
        .signal_in(debounced_s2),
        .pos_edge(s2_debounced_edge)
    );
    
    // 无消抖计数器 (0-99)
    counter_0to99 u_counter_no_debounce(
        .clk(clk),
        .rst(s1),
        .en(s3_edge),           // 使用未消抖的边沿信号
        .count(count_no_debounce)
    );
    
    // 有消抖计数器 (0-99)
    counter_0to99 u_counter_with_debounce(
        .clk(clk),
        .rst(s1),
        .en(s3_debounced_edge), // 使用消抖后的边沿信号
        .count(count_with_debounce)
    );
    
    // 十进制计数器控制
    toggle_ff u_toggle_ff(
        .clk(clk),
        .rst(s1),
        .toggle(s2_debounced_edge),
        .out(counter_enable)
    );
    
    // 0.1s间隔的0-30计数器
    decimal_counter u_decimal_counter(
        .clk(clk),
        .rst(s1),
        .enable(counter_enable),
        .count(decimal_count),
        .display_ten(decimal_ten),
        .display_unit(decimal_unit)
    );
    
    // 将7位计数器拆分为十位和个位显示 (0-99)
    wire [3:0] no_debounce_ten;   // 无消抖计数十位
    wire [3:0] no_debounce_unit;  // 无消抖计数个位
    wire [3:0] with_debounce_ten; // 有消抖计数十位  
    wire [3:0] with_debounce_unit;// 有消抖计数个位
    
    // 7位计数器值拆分为十位和个位 (0-99)
    assign no_debounce_ten = count_no_debounce / 7'd10;
    assign no_debounce_unit = count_no_debounce % 7'd10;
    
    assign with_debounce_ten = count_with_debounce / 7'd10;
    assign with_debounce_unit = count_with_debounce % 7'd10;
    
    // 数码管显示数据组合
    wire [31:0] display_data;
    assign display_data = {
        STUDENT_ID_HIGH,        // DK7 - 学号十位
        STUDENT_ID_LOW,         // DK6 - 学号个位
        no_debounce_ten,        // DK5 - 无消抖计数十位
        no_debounce_unit,       // DK4 - 无消抖计数个位
        with_debounce_ten,      // DK3 - 有消抖计数十位
        with_debounce_unit,     // DK2 - 有消抖计数个位
        decimal_ten,            // DK1 - 十进制计数十位
        decimal_unit            // DK0 - 十进制计数个位
    };
    
    // 数码管控制模块
    led_ctrl_unit u_led_ctrl_unit(
        .rst(s1),
        .clk(clk),
        .display(display_data),
        .enable(sw0),
        .led_en(led_en),
        .led_cx(led_cx)
    );

endmodule
