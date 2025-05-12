`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/08 22:01:37
// Design Name: 
// Module Name: CMU_PHi11
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module CMU_PHi11 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // 输入参数
    input  logic [DBL_WIDTH-1:0]   Theta_1_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_1,
    input  logic [DBL_WIDTH-1:0]   Theta_7_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_10,
    input  logic [DBL_WIDTH-1:0]   Theta_7_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_1_1,
    // 时间参数
    input  logic [DBL_WIDTH-1:0]   delta_t,
    // 输出
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);

    // 中间信号声明
    logic [DBL_WIDTH-1:0] delta_t2, delta_t3, delta_t4, delta_t5, delta_t6;
    logic [DBL_WIDTH-1:0] M1, M2, M3;
    logic [DBL_WIDTH-1:0] A1, A2, A3, A4;
    logic [DBL_WIDTH-1:0] X1, X2, X3, X4, X5, X6;
    logic [DBL_WIDTH-1:0] T1, T2, T3, T4, T5;
    logic [5:0] valid_pipe;

    reg [63:0] stage1_M1, stage1_M2, stage1_M3;
    reg [63:0] stage2_A1, stage2_A2, stage2_A3, stage2_A4;
    reg [63:0] stage3_X1, stage3_X2, stage3_X3, stage3_X4, stage3_X5, stage3_X6;
    reg [63:0] stage4_T1, stage4_T2, stage4_T3, stage4_T4, stage4_T5;

    // 时间参数计算模块
    fp_multiplier delta_t_sq (.clk(clk), .a(delta_t), .b(delta_t), .result(delta_t2));
    fp_multiplier delta_t_cu (.clk(clk), .a(delta_t2), .b(delta_t), .result(delta_t3));
    fp_multiplier delta_t_qu (.clk(clk), .a(delta_t3), .b(delta_t), .result(delta_t4));
    fp_multiplier delta_t_qi (.clk(clk), .a(delta_t4), .b(delta_t), .result(delta_t5));
    fp_multiplier delta_t_sx (.clk(clk), .a(delta_t5), .b(delta_t), .result(delta_t6));

    // 常数乘法模块
    fp_multiplier mult_3_4_7 (.clk(clk), .a(64'h4008000000000000), .b(Theta_4_7), .result(M1));  // 3*Θ4,7
    fp_multiplier mult_3_7_7 (.clk(clk), .a(64'h4008000000000000), .b(Theta_7_7), .result(M2));  // 3*Θ7,7
    fp_multiplier mult_4_10_4 (.clk(clk), .a(64'h4010000000000000), .b(Theta_4_10), .result(M3)); // 4*Θ10,4

    // 加法模块链
    fp_adder add_A1 (.clk(clk), .a(Theta_1_1), .b(Q_1_1), .result(A1));
    fp_adder add_A2 (.clk(clk), .a(Theta_7_1), .b(Theta_4_4), .result(A2));
    fp_adder add_A3 (.clk(clk), .a(Theta_10_1), .b(stage1_M1), .result(A3));
    fp_adder add_A4 (.clk(clk), .a(stage1_M2), .b(stage1_M3), .result(A4));

    // 时间参数乘法模块
    fp_multiplier mult_X1 (.clk(clk), .a(64'h4000000000000000), .b(Theta_4_1), .result(X1)); // 2Δt*Θ4,1
    fp_multiplier mult_X2 (.clk(clk), .a(delta_t2), .b(stage2_A2), .result(X2));
    fp_multiplier mult_X3 (.clk(clk), .a(delta_t3), .b(stage2_A3), .result(X3));
    fp_multiplier mult_X4 (.clk(clk), .a(delta_t4), .b(stage2_A4), .result(X4));
    fp_multiplier mult_X5 (.clk(clk), .a(delta_t5), .b(Theta_7_10), .result(X5));
    fp_multiplier mult_X6 (.clk(clk), .a(delta_t6), .b(Theta_10_10), .result(X6));

    // 系数调整模块
    fp_multiplier scale_X3 (.clk(clk), .a(stage3_X3), .b(64'h3fd5555555555555), .result(X3)); // 1/3
    fp_multiplier scale_X4 (.clk(clk), .a(stage3_X4), .b(64'h3f9c71c71c71c71c), .result(X4)); // 1/12
    fp_multiplier scale_X5 (.clk(clk), .a(stage3_X5), .b(64'h3fc5555555555555), .result(X5)); // 1/6
    fp_multiplier scale_X6 (.clk(clk), .a(stage3_X6), .b(64'h3f9c71c71c71c71c), .result(X6)); // 1/36

    // 累加模块
    fp_adder add_T1 (.clk(clk), .a(stage2_A1), .b(stage3_X1), .result(T1));
    fp_adder add_T2 (.clk(clk), .a(stage3_X2), .b(stage3_X3), .result(T2));
    fp_adder add_T3 (.clk(clk), .a(stage3_X4), .b(stage3_X5), .result(T3));
    fp_adder add_T4 (.clk(clk), .a(T1), .b(stage3_X6), .result(T4));
    fp_adder add_T5 (.clk(clk), .a(T2), .b(T3), .result(T5));
    fp_adder final_add (.clk(clk), .a(T5), .b(T4), .result(a));


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_A1 <= '0; stage2_A2 <= '0; stage2_A3 <= '0; stage2_A4 <= '0;
            A1 <= '0;   A2 <= '0;  A3 <= '0;   A4 <= '0;
            stage1_M1 <= '0; stage1_M2 <= '0; stage1_M3 <= '0;
            A3 <= '0;   M1 <= '0;   M2 <= '0;  M3 <= '0;   
            stage3_X1 <= '0; stage3_X2 <= '0; stage3_X3 <= '0;
            stage3_X4 <= '0; stage3_X5 <= '0; stage3_X6 <= '0;
            X1 <= '0;   X2 <= '0; X3 <= '0;
            X4 <= '0;   X5 <= '0;   X6 <= '0;
            stage4_T1 <= '0; stage4_T2 <= '0; stage4_T3 <= '0;
            stage4_T4 <= '0; stage4_T5 <= '0;
            T1 <= '0;   T2 <= '0;   T3 <= '0; T4 <= '0; T5 <= '0; 
        end else begin
            stage1_M1 <= M1; stage1_M2 <= M2; stage1_M3 <= M3;
            stage2_A1 <= A1; stage2_A2 <= A2; stage2_A3 <= A3; stage2_A4 <= A4;
            stage3_X1 <= X1; stage3_X2 <= X2; stage3_X3 <= X3;
            stage3_X4 <= X4; stage3_X5 <= X5; stage3_X6 <= X6;
            stage4_T1 <= T1; stage4_T2 <= T2; stage4_T3 <= T3;
            stage4_T4 <= T4; stage4_T5 <= T5;
        end
    end

    // 验证信号流水线
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_pipe <= 6'b0;
        else valid_pipe <= {valid_pipe[4:0], 1'b1};
    end

    assign valid_out = valid_pipe[5];

endmodule