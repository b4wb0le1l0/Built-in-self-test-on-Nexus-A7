`timescale 1ns / 1ps

module bist(
    input clk_i,
    input rst_i,

    input [7:0] a_bi,
    input [7:0] b_bi,
    input start_i,

    input test_btn_i,

    output busy_o,
    output reg [15:0] y_bo,

    output test_mode_enabled
);

localparam IDLE = 3'b000;
localparam LFSR = 3'b001;
localparam LFSR_WAIT = 3'b010;
localparam FUNC = 3'b011;
localparam FUNC_WAIT = 3'b100;
localparam CRC8_WAIT = 3'b110;
localparam TEST_START = 3'b111;

reg [2:0] state;

assign busy_o = (state != IDLE);

reg [7:0] tests_counter = 0;
reg [7:0] counter = 0;

wire is_test_btn_o;
reg is_test_now = 0;
assign test_mode_enabled = is_test_now;
reg prev_is_test_now = 0;

button test_button (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .in(test_btn_i),
    .out(is_test_btn_o)
);

wire is_start_pressed;
reg is_starting_now = 0;
reg prev_is_starting_now = 0;

button start_button (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .in(start_i),
    .out(is_start_pressed)
);

reg [7:0] a_func_i;
reg [7:0] b_func_i;
reg start_func_i;
wire [2:0] y_func_o;
wire busy_func_o;

functer func (
    .clk(clk_i),
    .rst(rst_i),
    .a_bi(a_func_i),
    .b_bi(b_func_i),
    .start_i(start_func_i),
    .busy_o(busy_func_o),
    .y_bo(y_func_o)
);

reg lfsr1_start;
reg [7:0] lfsr1_init = 8'hFF;
wire [7:0] lfsr1_o;
wire lfsr1_busy;

lfsr1 lfsr1_obj (
    .clk_i(clk_i),
    .rst_i(rst_i), 
    .start_i(lfsr1_start),
    .init_i(lfsr1_init),
    .busy_o(lfsr1_busy),
    .result_o(lfsr1_o)
);

reg lfsr2_start;
reg [7:0] lfsr2_init = 8'hFF;
wire [7:0] lfsr2_o;
wire lfsr2_busy;

lfsr2 lfsr2_obj (
    .clk_i(clk_i),
    .rst_i(rst_i), 
    .start_i(lfsr2_start),
    .init_i(lfsr2_init),
    .busy_o(lfsr2_busy),
    .result_o(lfsr2_o)
);

reg [15:0] crc8_i;
reg crc8_start;
wire [7:0] crc8_o;
wire crc8_busy;

crc8 crc8_obj (
    .clk_i(clk_i),
    .rst_i(rst_i),
    .data_i(crc8_i),
    .start_i(crc8_start),
    .busy_o(crc8_busy),
    .crc_o(crc8_o)
);

always @(posedge clk_i) begin
    if (rst_i) begin
        y_bo <= 0;
        state <= IDLE;
        tests_counter <= 0;
        counter <= 0;
        a_func_i <= 0;
        b_func_i <= 0;
        start_func_i <= 0;
        lfsr1_start <= 0;
        lfsr1_init <= 8'hFF;
        lfsr2_start <= 0;
        lfsr2_init <= 8'hFF;
        crc8_start <= 0;
        crc8_i <= 0;
        is_test_now <= 0;
        prev_is_test_now <= 0;
        is_starting_now <= 0;
        prev_is_starting_now <= 0;
    end else begin
        prev_is_test_now <= is_test_btn_o;
        if (prev_is_test_now != is_test_btn_o && is_test_btn_o) begin
            is_test_now <= ~is_test_now;
        end

        prev_is_starting_now <= is_start_pressed;
        if (prev_is_starting_now != is_start_pressed && is_start_pressed) begin
            is_starting_now <= ~is_starting_now;
        end

        case (state)
            IDLE:
                begin
                    if (is_starting_now) begin
                        is_starting_now <= 0;
                        if (is_test_now) begin
                            state <= TEST_START;
                        end else begin
                            state <= FUNC;
                        end
                    end
                end 
            LFSR:
                begin
                    lfsr1_start <= 1;
                    lfsr2_start <= 1;
                    state <= LFSR_WAIT;
                end
            LFSR_WAIT:
                begin
                    lfsr1_start <= 0;
                    lfsr2_start <= 0;

                    if (~lfsr1_start && ~lfsr2_start && ~lfsr1_busy && ~lfsr2_busy) begin
                        state <= FUNC;
                    end
                end
            FUNC:
                begin
                    if (is_test_now) begin
                        lfsr1_init <= lfsr1_o;
                        lfsr2_init <= lfsr2_o;
                        a_func_i <= lfsr1_o;
                        b_func_i <= lfsr2_o;
                    end else begin
                        a_func_i <= a_bi;
                        b_func_i <= b_bi;
                    end
                    start_func_i <= 1;
                    state <= FUNC_WAIT;
                end
            FUNC_WAIT:
                begin
                    start_func_i <= 0;
                    if (~busy_func_o && ~start_func_i) begin
                        if (is_test_now) begin
                            crc8_i <= y_func_o;
                            crc8_start <= 1;
                            state <= CRC8_WAIT;
                        end else begin
                            y_bo [2:0] <= y_func_o;
                            y_bo [15:3] <= 0;
                            state <= IDLE;
                        end
                    end
                end
            CRC8_WAIT:
                begin
                    crc8_start <= 0;
                    if (~crc8_start && ~crc8_busy) begin
                        state <= TEST_START;
                    end
                end
            TEST_START:
                begin
                    if (tests_counter == 255) begin
                        y_bo [7:0] <= crc8_o;
                        y_bo [15:8] <= counter + 1;
                        state <= IDLE;
                        counter <= counter + 1;
                        tests_counter <= 0;
                    end else begin
                        tests_counter <= tests_counter + 1;
                        state <= LFSR;
                    end
                end
        endcase
    end
end 

endmodule