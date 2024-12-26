`timescale 1ns / 1ps

module functer_tb;
    reg clk;
    reg rst;
    reg start;
    reg [7:0] a;
    reg [7:0] b;

    wire [2:0] y;
    wire busy;

    reg [7:0] a_in [0:9];
    reg [7:0] b_in [0:9];
    reg [15:0] expected [0:9];

    functer func (
        .clk(clk),
        .rst(rst),
        .start_i(start),
        .a_bi(a),
        .b_bi(b),
        .y_bo(y),
        .busy_o(busy)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        start = 0;

        #20;
        rst = 0;

        a_in[0] = 8'd3;  b_in[0] = 8'd27; expected[0] = 16'd2; 
        a_in[1] = 8'd5;  b_in[1] = 8'd8;  expected[1] = 16'd1; 
        a_in[2] = 8'd2;  b_in[2] = 8'd1;  expected[2] = 16'd1; 
        a_in[3] = 8'd4;  b_in[3] = 8'd8;  expected[3] = 16'd1; 
        a_in[4] = 8'd9;  b_in[4] = 8'd16; expected[4] = 16'd2; 
        a_in[5] = 8'd15; b_in[5] = 8'd64; expected[5] = 16'd2; 
        a_in[6] = 8'd49; b_in[6] = 8'd49; expected[6] = 16'd3; 
        a_in[7] = 8'd100; b_in[7] = 8'd81; expected[7] = 16'd4; 
        a_in[8] = 8'd144; b_in[8] = 8'd64; expected[8] = 16'd5; 
        a_in[9] = 8'd255; b_in[9] = 8'd255; expected[9] = 16'd6; 

        for (integer i = 0; i < 10; i = i + 1) begin
            @(posedge clk);
            start = 1;
            a = a_in[i];
            b = b_in[i];
            
            $display("Starting Test %0d: a = %d, b = %d", i, a, b);
            
            @(posedge clk);
            start = 0;

            while (busy) begin
                @(posedge clk);
            end

            #10;

            if (y !== expected[i]) begin
                $display("Test %0d failed! Expected: %d, Got: %d", i, expected[i], y);
            end else begin
                $display("Test %0d passed! Output: %d", i, y);
            end
        end

        $stop;
    end
endmodule
