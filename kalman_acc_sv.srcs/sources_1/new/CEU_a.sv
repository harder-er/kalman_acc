`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 09:09:14
// Design Name: 
// Module Name: CEU_a
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 分级流水线实现 CEU_a 计算
// 
// Dependencies: fp_adder, fp_multiplier
// 
//////////////////////////////////////////////////////////////////////////////////

module CEU_a #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // 动态输入
    input  logic [DBL_WIDTH-1:0]   Theta_1_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_1,
    input  logic [DBL_WIDTH-1:0]   Theta_7_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_1,
    input  logic [DBL_WIDTH-1:0]   Theta_7_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_4,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_1_1,
    input  logic [DBL_WIDTH-1:0]   R_1_1,
    // 固定参数
    input  logic [DBL_WIDTH-1:0]   delta_t2,
    input  logic [DBL_WIDTH-1:0]   delta_t_sq,
    input  logic [DBL_WIDTH-1:0]   delta_t_cu,
    input  logic [DBL_WIDTH-1:0]   delta_t_qu,
    input  logic [DBL_WIDTH-1:0]   delta_t_qi,
    input  logic [DBL_WIDTH-1:0]   delta_t_sx,
    // 输出
    output logic [DBL_WIDTH-1:0]   a_out,
    output logic                   valid_out
);

    // ----------------- 流水线寄存器定义 -----------------
    logic [DBL_WIDTH-1:0] stage1_A1, stage1_M1;
    logic [DBL_WIDTH-1:0] stage2_X1, stage2_A2, stage2_M3;
    logic [DBL_WIDTH-1:0] stage3_X2, stage3_X3;
    logic [DBL_WIDTH-1:0] stage4_temp, stage4_X4, stage4_X5;
    logic [DBL_WIDTH-1:0] stage5_T1, stage5_T2;
    logic [DBL_WIDTH-1:0] stage6_T3, stage6_X6, stage6_T4;
    logic [DBL_WIDTH-1:0] stage7_T5, stage7_T6;
    logic [3:0]           pipe_valid;

    // 临时连线（组合逻辑到流水线寄存器）
    wire [DBL_WIDTH-1:0] mul_M2;    // 3 * Θ7,7
    wire [DBL_WIDTH-1:0] sum_QR;    // Q_1_1 + R_1_1

    // ----------------- 顶层子模块实例化 -----------------
    // Stage 1
    fp_adder      U_add_A1   (.clk(clk), .a(Theta_7_1), .b(Theta_4_4), .result(stage1_A1));
    fp_multiplier U_mul_M1   (.clk(clk), .a(64'h4008000000000000), .b(Theta_7_4), .result(stage1_M1)); // 3*Θ7,4

    // Stage 2
    fp_multiplier U_mul_X1   (.clk(clk), .a(delta_t2), .b(Theta_4_1), .result(stage2_X1));
    fp_adder      U_add_A2   (.clk(clk), .a(Theta_10_1), .b(stage1_M1), .result(stage2_A2));
    fp_multiplier U_mul_M3   (.clk(clk), .a(64'h4010000000000000), .b(Theta_10_4), .result(stage2_M3)); // 4*Θ10,4

    // Stage 3
    fp_multiplier U_mul_X2   (.clk(clk), .a(delta_t_sq), .b(stage1_A1), .result(stage3_X2));
    fp_multiplier U_mul_X3   (.clk(clk), .a(delta_t_cu), .b(stage2_A2), .result(stage3_X3));

    // Stage 4
    fp_multiplier U_mul_M2   (.clk(clk), .a(64'h4008000000000000), .b(Theta_7_7), .result(mul_M2));  // 3*Θ7,7
    fp_adder      U_add_A3   (.clk(clk), .a(stage2_M3), .b(mul_M2), .result(stage4_temp));
    fp_multiplier U_mul_X4   (.clk(clk), .a(delta_t_qu), .b(stage4_temp), .result(stage4_X4));
    fp_multiplier U_mul_X5   (.clk(clk), .a(delta_t_qi), .b(Theta_10_7), .result(stage4_X5));

    // Stage 5
    fp_adder      U_add_T1   (.clk(clk), .a(Theta_1_1), .b(stage2_X1), .result(stage5_T1));
    fp_adder      U_add_T2   (.clk(clk), .a(stage3_X2), .b(stage3_X3), .result(stage5_T2));

    // Stage 6
    fp_adder      U_add_T3   (.clk(clk), .a(stage4_X4), .b(stage4_X5), .result(stage6_T3));
    fp_multiplier U_mul_X6   (.clk(clk), .a(delta_t_sx), .b(Theta_10_10), .result(stage6_X6));
    fp_adder      U_add_QR   (.clk(clk), .a(Q_1_1), .b(R_1_1), .result(sum_QR));
    fp_adder      U_add_T4   (.clk(clk), .a(stage6_X6), .b(sum_QR), .result(stage6_T4));

    // Stage 7
    fp_adder      U_add_T5   (.clk(clk), .a(stage5_T1), .b(stage5_T2), .result(stage7_T5));
    fp_adder      U_add_T6   (.clk(clk), .a(stage6_T3), .b(stage6_T4), .result(stage7_T6));
    fp_adder      U_final    (.clk(clk), .a(stage7_T5), .b(stage7_T6), .result(a_out));

    // ----------------- 流水线寄存器与控制 -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A1   <= '0;
            stage1_M1   <= '0;
            stage2_X1   <= '0;
            stage2_A2   <= '0;
            stage2_M3   <= '0;
            stage3_X2   <= '0;
            stage3_X3   <= '0;
            stage4_temp <= '0;
            stage4_X4   <= '0;
            stage4_X5   <= '0;
            stage5_T1   <= '0;
            stage5_T2   <= '0;
            stage6_T3   <= '0;
            stage6_X6   <= '0;
            stage6_T4   <= '0;
            stage7_T5   <= '0;
            stage7_T6   <= '0;
            pipe_valid  <= 4'b0000;
        end else begin
            // 各级计算结果已由子模块在同一时钟沿产生，
            // 这里用于同步下一级流水
            stage1_A1   <= stage1_A1;
            stage1_M1   <= stage1_M1;
            stage2_X1   <= stage2_X1;
            stage2_A2   <= stage2_A2;
            stage2_M3   <= stage2_M3;
            stage3_X2   <= stage3_X2;
            stage3_X3   <= stage3_X3;
            stage4_temp <= stage4_temp;
            stage4_X4   <= stage4_X4;
            stage4_X5   <= stage4_X5;
            stage5_T1   <= stage5_T1;
            stage5_T2   <= stage5_T2;
            stage6_T3   <= stage6_T3;
            stage6_X6   <= stage6_X6;
            stage6_T4   <= stage6_T4;
            stage7_T5   <= stage7_T5;
            stage7_T6   <= stage7_T6;

            // 管线有效信号左移并注入新"1"
            pipe_valid <= {pipe_valid[2:0], 1'b1};
        end
    end

    // 输出有效信号：当最高位为 1 时，a_out 为有效数据
    assign valid_out = pipe_valid[3];

endmodule
