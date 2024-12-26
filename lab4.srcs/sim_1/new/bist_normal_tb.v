module bist_normal_tb;
    reg clk;
    reg rst;
    reg start;
    reg [7:0] a;
    reg [7:0] b;
    reg test_btn;
    wire [15:0] y;
    wire busy;

    bist uut (
        .clk_i(clk),
        .rst_i(rst),
        .start_i(start),
        .a_bi(a),
        .b_bi(b),
        .test_btn_i(test_btn),
        .y_bo(y),
        .busy_o(busy)
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
        #20;

        rst = 0;
        #20;

        start = 1;
        a = 8'd255;
        b = 8'd255;
        #40;

        start = 0;

        #60;
        while (busy) begin
            #20;
        end

        $display("Result for a = %d, b = %d is y = %d", a, b, y);
    end

    initial begin
        $monitor("At time %d, y = %h, busy = %b", $time, y, busy);
    end
endmodule