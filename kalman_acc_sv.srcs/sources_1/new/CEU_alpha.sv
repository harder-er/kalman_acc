`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
// Create Date: 2025/04/25 17:46:27
// Module Name: CEU_alpha
// Description: 计算 α = in1*in2 - in3*in3，采用两级流水线，并带 valid 管线信号
// Dependencies: fp_arithmetic.svh (声明 fp_multiplier, fp_suber)
//////////////////////////////////////////////////////////////////////////////////

module CEU_alpha #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [DBL_WIDTH-1:0]   in1,    // 对应 a
    input  logic [DBL_WIDTH-1:0]   in2,    // 对应 d
    input  logic [DBL_WIDTH-1:0]   in3,    // 对应 x
    output logic [DBL_WIDTH-1:0]   out,    // 输出 α
    output logic                   valid_out
);


    // ------------------- 顶层子模块和连线 -------------------
    // Stage1 乘法结果
    wire [DBL_WIDTH-1:0] m1;         // in1 * in2
    wire [DBL_WIDTH-1:0] m2;         // in3 * in3

    fp_multiplier U_mul1 (
        .clk    (clk),
        .a      (in1),
        .b      (in2),
        .result (m1)
    );
    fp_multiplier U_mul2 (
        .clk    (clk),
        .a      (in3),
        .b      (in3),
        .result (m2)
    );

    // Stage2 采用专用浮点减法 IP
    wire [DBL_WIDTH-1:0] diff_m;    // m1 - m2
    fp_suber U_sub (
        .clk    (clk),
        .a      (m1),
        .b      (m2),
        .result (diff_m)
    );

    // ------------------- 流水线寄存器 -------------------
    // Stage1 reg 保存 m1, m2
    logic [DBL_WIDTH-1:0] stage1_m1, stage1_m2;
    // Stage2 reg 保存 diff_m
    logic [DBL_WIDTH-1:0] stage2_diff;
    // 管线有效信号，共两级
    logic [1:0] valid_pipe;

    // ------------------- 时序逻辑 -------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_m1   <= '0;
            stage1_m2   <= '0;
            stage2_diff <= '0;
            valid_pipe  <= 2'b00;
            out         <= '0;
        end else begin
            // 阶段1结果寄存
            stage1_m1 <= m1;
            stage1_m2 <= m2;
            // 阶段2结果寄存并输出
            stage2_diff <= diff_m;
            out         <= diff_m;
            // 有效信号移位注入
            valid_pipe  <= { valid_pipe[0], 1'b1 };
        end
    end

    assign valid_out = valid_pipe[1];

endmodule
