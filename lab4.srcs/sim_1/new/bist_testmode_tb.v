module bist_testmode_tb;
    reg clk;
    reg rst;
    reg start;
    reg [7:0] a;
    reg [7:0] b;
    reg test_btn;
    wire [15:0] y;
    wire busy;
    wire test_mode_enabled;

    bist uut (
        .clk_i(clk),
        .rst_i(rst),
        .start_i(start),
        .a_bi(a),
        .b_bi(b),
        .test_btn_i(test_btn),
        .y_bo(y),
        .busy_o(busy),
        .test_mode_enabled(test_mode_enabled)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
        test_btn = 0;
        #10;

        rst = 0;
        #10;
        test_btn = 1;
        #1000;
        test_btn = 0;

        start = 1;
        a = 8'd255;
        b = 8'd255;
        #10000;

        start = 0;

        while (busy) begin
            #20;
        end

        $display("Result for a = %d, b = %d, crc8 = %b, tests_n = %d, y = %d, test_mode_enabled=%d", a, b, y[7:0], y[15:8], y, test_mode_enabled);
        
        start = 1;
        #10000;
        start = 0;
        
        while (busy) begin
            #20;
        end
        
        $display("Result for a = %d, b = %d, crc8 = %b, tests_n = %d, y = %d, test_mode_enabled=%d", a, b, y[7:0], y[15:8], y, test_mode_enabled);
        
        start = 1;
        #10000;
        start = 0;
        
        while (busy) begin
            #20;
        end
        
        $display("Result for a = %d, b = %d, crc8 = %b, tests_n = %d, y = %d, test_mode_enabled=%d", a, b, y[7:0], y[15:8], y, test_mode_enabled);
        
        test_btn = 1;
        #1000;
        test_btn = 0;
        
        start = 1;
        #10000;
        start = 0;
        
        while (busy) begin
            #20;
        end
        
        $display("Result for a = %d, b = %d, crc8 = %b, tests_n = %d, y = %d, test_mode_enabled=%d", a, b, y[7:0], y[15:8], y, test_mode_enabled);
    end
endmodule