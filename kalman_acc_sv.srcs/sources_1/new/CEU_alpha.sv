`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
// Create Date: 2025/04/25 17:46:27
// Module Name: CEU_alpha
// Description: ���� �� = in1*in2 - in3*in3������������ˮ�ߣ����� valid �����ź�
// Dependencies: fp_arithmetic.svh (���� fp_multiplier, fp_suber)
//////////////////////////////////////////////////////////////////////////////////

module CEU_alpha #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [DBL_WIDTH-1:0]   in1,    // ��Ӧ a
    input  logic [DBL_WIDTH-1:0]   in2,    // ��Ӧ d
    input  logic [DBL_WIDTH-1:0]   in3,    // ��Ӧ x
    output logic [DBL_WIDTH-1:0]   out,    // ��� ��
    output logic                   valid_out
);

    `include "fp_arithmetic.svh"

    // ------------------- ������ģ������� -------------------
    // Stage1 �˷����
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

    // Stage2 ����ר�ø������ IP
    wire [DBL_WIDTH-1:0] diff_m;    // m1 - m2
    fp_suber U_sub (
        .clk    (clk),
        .a      (m1),
        .b      (m2),
        .result (diff_m)
    );

    // ------------------- ��ˮ�߼Ĵ��� -------------------
    // Stage1 reg ���� m1, m2
    logic [DBL_WIDTH-1:0] stage1_m1, stage1_m2;
    // Stage2 reg ���� diff_m
    logic [DBL_WIDTH-1:0] stage2_diff;
    // ������Ч�źţ�������
    logic [1:0] valid_pipe;

    // ------------------- ʱ���߼� -------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_m1   <= '0;
            stage1_m2   <= '0;
            stage2_diff <= '0;
            valid_pipe  <= 2'b00;
            out         <= '0;
        end else begin
            // �׶�1����Ĵ�
            stage1_m1 <= m1;
            stage1_m2 <= m2;
            // �׶�2����Ĵ沢���
            stage2_diff <= diff_m;
            out         <= diff_m;
            // ��Ч�ź���λע��
            valid_pipe  <= { valid_pipe[0], 1'b1 };
        end
    end

    assign valid_out = valid_pipe[1];

endmodule
