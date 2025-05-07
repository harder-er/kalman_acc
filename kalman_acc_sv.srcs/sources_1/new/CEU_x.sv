`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
// Create Date: 2025/04/25 17:17:06
// Module Name: CEU_x
// Description: 参数化 CEU_x 模块，支持 d/e/f 通道，五级流水，所有浮点核在顶层实例化
// Dependencies: fp_arithmetic.svh (定义 fp_add_core, fp_mult_core 模块)
//////////////////////////////////////////////////////////////////////////////////

module CEU_x #(
    parameter DBL_WIDTH = 64,
    parameter CHANNEL   = "d"
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [DBL_WIDTH-1:0]   Theta_ij,
    input  logic [DBL_WIDTH-1:0]   Theta_ik,
    input  logic [DBL_WIDTH-1:0]   Theta_mj,
    input  logic [DBL_WIDTH-1:0]   Theta_mk,
    input  logic [DBL_WIDTH-1:0]   Theta_mm,
    input  logic [DBL_WIDTH-1:0]   Q_ii,
    input  logic [DBL_WIDTH-1:0]   R_ii,
    input  logic [DBL_WIDTH-1:0]   delta_t,
    input  logic [DBL_WIDTH-1:0]   delta_t2,
    input  logic [DBL_WIDTH-1:0]   delta_t_sq,
    input  logic [DBL_WIDTH-1:0]   delta_t_cu,
    input  logic [DBL_WIDTH-1:0]   delta_t_qr,
    output logic [DBL_WIDTH-1:0]   result,
    output logic                   valid_out
);

    `include "fp_arithmetic.svh"

    // 流水线寄存器
    typedef struct packed { logic [DBL_WIDTH-1:0] A1, X1; } stage1_t;
    typedef struct packed { logic [DBL_WIDTH-1:0] X2, X3, A2; } stage2_t;
    typedef struct packed { logic [DBL_WIDTH-1:0] T1, T2, M1; } stage3_t;
    typedef struct packed { logic [DBL_WIDTH-1:0] X4, T3, T4; } stage4_t;

    stage1_t stage1_q;
    stage2_t stage2_q;
    stage3_t stage3_q;
    stage4_t stage4_q;
    logic [4:0] valid_pipe;

    // 顶层信号
    wire [DBL_WIDTH-1:0] w_A1, w_X1;
    wire [DBL_WIDTH-1:0] w_X2, w_X3, w_A2;
    wire [DBL_WIDTH-1:0] w_T1, w_T2, w_M1;
    wire [DBL_WIDTH-1:0] w_X4, w_T3, w_T4;

    // 组合系数 M1
    wire [DBL_WIDTH-1:0] mul3 = 64'h4008_0000_0000_0000; // 3.0
    wire [DBL_WIDTH-1:0] mul4 = 64'h4010_0000_0000_0000; // 4.0
    wire [DBL_WIDTH-1:0] mul5 = 64'h4014_0000_0000_0000; // 5.0
    wire [DBL_WIDTH-1:0] coeff = (CHANNEL=="e")? mul4 : (CHANNEL=="f")? mul5 : mul3;

    // ====== 顶层子模块实例化 ======
    // Stage1: A1, X1
    fp_adder      U1 (.clk(clk), .a(Theta_mk), .b(Theta_ik), .result(w_A1));
    fp_multiplier U2 (.clk(clk), .a(delta_t2),   .b(Theta_ik), .result(w_X1));

    // Stage2: X2, X3, A2
    fp_multiplier U3 (.clk(clk), .a(delta_t_sq), .b(Theta_mj),  .result(w_X2));
    fp_multiplier U4 (.clk(clk), .a(delta_t_cu), .b(w_A1),     .result(w_X3));
    fp_adder      U5 (.clk(clk), .a(Theta_ij), .b(w_X1),       .result(w_A2));

    // Stage3: T1, T2, M1
    fp_adder      U6 (.clk(clk), .a(w_X2),   .b(w_X3), .result(w_T1));
    fp_adder      U7 (.clk(clk), .a(w_A2),   .b(w_T1), .result(w_T2));
    fp_multiplier U8 (.clk(clk), .a(coeff), .b(Theta_mm), .result(w_M1));

    // Stage4: X4, T3, T4
    fp_multiplier U9  (.clk(clk), .a(delta_t_qr), .b(w_M1),     .result(w_X4));
    fp_adder      U10 (.clk(clk), .a(Q_ii),        .b(R_ii),     .result(w_T3));
    fp_adder      U11 (.clk(clk), .a(w_X4),        .b(w_T3),     .result(w_T4));

    // Stage5: Final result
    fp_adder      U12 (.clk(clk), .a(w_T2),        .b(w_T4),     .result(result));

    // ====== 时序逻辑 ======
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_q <= '0;
            stage2_q <= '0;
            stage3_q <= '0;
            stage4_q <= '0;
            valid_pipe <= '0;
            result <= '0;
        end else begin
            // 同步各级
            stage1_q.A1 <= w_A1;
            stage1_q.X1 <= w_X1;

            stage2_q.X2 <= w_X2;
            stage2_q.X3 <= w_X3;
            stage2_q.A2 <= w_A2;

            stage3_q.T1 <= w_T1;
            stage3_q.T2 <= w_T2;
            stage3_q.M1 <= w_M1;

            stage4_q.X4 <= w_X4;
            stage4_q.T3 <= w_T3;
            stage4_q.T4 <= w_T4;

            // 更新 valid
            valid_pipe <= {valid_pipe[3:0], 1'b1};
        end
    end

    assign valid_out = valid_pipe[4];

endmodule
