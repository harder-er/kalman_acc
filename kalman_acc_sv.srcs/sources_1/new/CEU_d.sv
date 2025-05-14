`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/06
// Module Name: CEU_d
// Description: 定义 CEU_d 模块，支持通过 d/e/f 相关计算逻辑
//////////////////////////////////////////////////////////////////////////////////
module CEU_d #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // 静态输入：对应 "def" 的相关输入
    input  logic [DBL_WIDTH-1:0]   Theta_10_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_4,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,
    input  logic [DBL_WIDTH-1:0]   Q_4_4,
    input  logic [DBL_WIDTH-1:0]   R_4_4,
    // 动态输入参数
    input  logic [DBL_WIDTH-1:0]   delta_t2,    // 2 倍的 t
    input  logic [DBL_WIDTH-1:0]   delta_t_sq,  // t 的平方
    input  logic [DBL_WIDTH-1:0]   delta_t_hcu, // 特定的 t 相关值
    input  logic [DBL_WIDTH-1:0]   delta_t_qr,  // 特定的 t 相关值
    // 输出
    output logic [DBL_WIDTH-1:0]   d,
    output logic                   valid_out
);

    // ---------------- 中间变量声明 ----------------
    logic [DBL_WIDTH-1:0] stage1_A1, stage1_X1;
    logic [DBL_WIDTH-1:0] stage2_X2, stage2_X3;
    logic [DBL_WIDTH-1:0] stage2_X4;
    logic [DBL_WIDTH-1:0] stage3_T1, stage3_T2;
    logic [DBL_WIDTH-1:0] stage4_T4, stage4_T3;
    logic [1:0]            pipe_valid;

    // 输出计算所需
    wire [DBL_WIDTH-1:0] sum_QR;  // Q+R

    // ================= 模块功能实现 =================
    // Stage1: A1 = Theta_10_7 + Theta_7_4;   X1 = 2 * t * Theta_7_4
    fp_adder      U1_add_A1 (.clk(clk), .a(Theta_10_7), .b(Theta_7_4), .result(stage1_A1));
    fp_multiplier U1_mul_X1 (.clk(clk), .a(delta_t2),   .b(Theta_7_4),   .result(stage1_X1));

    // Stage2: X2 = t 的平方 * 某个值（这里变量可能是乱码 Theta_8_5）;     X3 = 特定的 t 值 * A1
    fp_multiplier U2_mul_X2 (.clk(clk), .a(delta_t_sq),  .b(Theta_8_5),   .result(stage2_X2));
    fp_multiplier U2_mul_X3 (.clk(clk), .a(delta_t_hcu), .b(stage1_A1),   .result(stage2_X3));

    // Stage3: T1 = Theta_10_4 + X1;     T2 = X2 + X3
    fp_adder      U3_add_T1 (.clk(clk), .a(Theta_10_4), .b(stage1_X1),   .result(stage3_T1));
    fp_adder      U3_add_T2 (.clk(clk), .a(stage2_X2), .b(stage2_X3),   .result(stage3_T2));

    // Stage4: T3 = 特定的 t 值 * 某个值（这里变量可能是乱码 Theta_9_9） + (Q+R);  T4 = T1 + T2
    fp_multiplier U4_mul_X4 (.clk(clk), .a(delta_t_qr), .b(Theta_9_9),  .result(stage4_T3));
    fp_adder      U4_add_QR (.clk(clk), .a(Q_9_9),     .b(R_9_9),      .result(sum_QR));
    fp_adder      U4_add_T3 (.clk(clk), .a(stage4_T3), .b(sum_QR),      .result(stage4_T3));
    fp_adder      U4_add_T4 (.clk(clk), .a(stage3_T1), .b(stage3_T2),   .result(stage4_T4));

    // ================= 中间变量赋值逻辑 =================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A1  <= '0;
            stage1_X1  <= '0;
            stage2_X2  <= '0;
            stage2_X3  <= '0;
            stage3_T1  <= '0;
            stage3_T2  <= '0;
            stage4_T3  <= '0;
            stage4_T4  <= '0;
            pipe_valid <= 2'b00;
        end else begin
            // 同步更新中间变量
            stage1_A1  <= stage1_A1;
            stage1_X1  <= stage1_X1;
            stage2_X2  <= stage2_X2;
            stage2_X3  <= stage2_X3;
            stage3_T1  <= stage3_T1;
            stage3_T2  <= stage3_T2;
            stage4_T3  <= stage4_T3;
            stage4_T4  <= stage4_T4;
            // valid 信号更新
            pipe_valid <= {pipe_valid[0], 1'b1};
        end
    end

    // 最终输出赋值
    assign d       = stage4_T3 + stage4_T4; // 这里可能需要一个 fp_adder 来精确加法
    assign valid_out = pipe_valid[1];

endmodule