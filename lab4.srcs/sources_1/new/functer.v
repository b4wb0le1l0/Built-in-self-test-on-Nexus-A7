`timescale 1ns / 1ps

module mult (
    input clk,
    input rst,

    input [7:0] a_bi,
    input [7:0] b_bi,
    input start_i,

    output busy_o,
    output reg [15:0] y_bo
);
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;

    reg [2:0] ctr;
    wire end_step;
    wire [7:0] part_sum;
    wire [15:0] shifted_part_sum;
    reg [7:0] a, b;
    reg [15:0] part_res;
    reg state;

    assign part_sum = a & {8{b[ctr]}};
    assign shifted_part_sum = part_sum << ctr;
    assign end_step = (ctr == 3'h7);
    assign busy_o = (state == WORK);

    always @(posedge clk) begin
        if (rst) begin
            ctr <= 0;
            part_res <= 0;
            y_bo <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        state <= WORK;
                        a <= a_bi;
                        b <= b_bi;
                        ctr <= 0;
                        part_res <= 0;
                    end
                end
                WORK: begin
                    part_res <= part_res + shifted_part_sum;
                    ctr <= ctr + 1;
                    if (end_step) begin
                        y_bo <= part_res;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule

module functer (
    input clk,
    input rst,
    input start_i,
    input [7:0] a_bi,
    input [7:0] b_bi,
    
    output reg [2:0] y_bo,
    output busy_o
);

    reg [4:0] x;
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [15:0] sum;
    reg start_mult1;
    wire busy_mult1;
    reg [7:0] mult1_reg1, mult1_reg2;
    wire [15:0] mult1_res;
    reg [3:0] state;
    
    localparam IDLE = 4'b0000;
    localparam SQUARE_X_B = 4'b0001;
    localparam WAIT_SQUARE_B = 4'b0010;
    localparam COMPARE_XY_B = 4'b0011;
    localparam SQUARE_X  = 4'b0100;
    localparam CUBE_X  = 4'b0101;
    localparam COMPARE_XY = 4'b0110;
    localparam SUM  = 4'b0111;

    localparam WAIT_SQUARE = 4'b1000;
    localparam WAIT_CUBE = 4'b1001;

    mult multiplier1 (
        .clk(clk),
        .rst(rst),
        .start_i(start_mult1),
        .a_bi(mult1_reg1),
        .b_bi(mult1_reg2),
        .y_bo(mult1_res),
        .busy_o(busy_mult1)
    );

    assign busy_o = (state != IDLE) || busy_mult1;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            y_bo <= 4'b0;
            sum <= 16'b0;
            start_mult1 <= 1'b0;
            x <= 5'b00001;
            a_reg <= 8'b0;
            b_reg <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_i) begin
                        a_reg <= a_bi;
                        b_reg <= b_bi;
                        state <= SQUARE_X_B;
                        x <= 5'b00001;
                    end
                end
                SQUARE_X_B: begin
                    mult1_reg1 <= x;
                    mult1_reg2 <= x;
                    start_mult1 <= 1'b1;
                    state <= WAIT_SQUARE_B;
                end
                WAIT_SQUARE_B: begin
                    start_mult1 <= 1'b0;
                    state <= COMPARE_XY_B;
                end           
                COMPARE_XY_B: begin
                    if (!busy_mult1) begin
                        if (mult1_res < b_reg) begin
                            x <= x + 1;
                            state <= SQUARE_X_B;
                        end else begin
                            b_reg <= (mult1_res == b_reg) ? x : x - 1;
                            x <= 5'b00001; 
                            state <= SUM;
                        end
                    end
                end
                 SUM: begin
                    sum <= a_reg + b_reg;
                    state <= SQUARE_X;
                end           
                SQUARE_X: begin
                    mult1_reg1 <= x;
                    mult1_reg2 <= x;
                    start_mult1 <= 1'b1;
                    state <= WAIT_SQUARE;
                end
                WAIT_SQUARE: begin
                    start_mult1 <= 1'b0;
                    state <= CUBE_X; 
                end                 
                CUBE_X: begin
                    if (!busy_mult1) begin
                        mult1_reg1 <= x;
                        mult1_reg2 <= mult1_res;
                        start_mult1 <= 1'b1;
                        state <= WAIT_CUBE;
                    end
                end
                WAIT_CUBE: begin
                    start_mult1 <= 1'b0;
                    state <= COMPARE_XY;
                end
                COMPARE_XY: begin
                    if (!busy_mult1) begin
                        if (mult1_res < sum) begin
                            x <= x + 1;
                            state <= SQUARE_X;
                        end else begin
                            y_bo <= (mult1_res == sum) ? x : x - 1;
                            state <= IDLE; 
                        end
                    end
                end                 
            endcase
        end
    end
endmodule