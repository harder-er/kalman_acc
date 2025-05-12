`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/06
// Module Name: CEU_d
// Description: ������ CEU_d ����ģ�飬֧��ͨ�� d/e/f���弶��ˮ
//////////////////////////////////////////////////////////////////////////////////
module CEU_d #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // ��̬���룺�� "def" ͨ����Ӧ�� ��
    input  logic [DBL_WIDTH-1:0]   Theta_10_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_4,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,
    input  logic [DBL_WIDTH-1:0]   Q_4_4,
    input  logic [DBL_WIDTH-1:0]   R_4_4,
    // �̶�ʱ�����
    input  logic [DBL_WIDTH-1:0]   delta_t2,    // 2��t
    input  logic [DBL_WIDTH-1:0]   delta_t_sq,  // ��t?
    input  logic [DBL_WIDTH-1:0]   delta_t_hcu, // ?����t?
    input  logic [DBL_WIDTH-1:0]   delta_t_qr,  // ?����t?
    // ���
    output logic [DBL_WIDTH-1:0]   d,
    output logic                   valid_out
);

    `include "fp_arithmetic.svh"

    // ---------------- ��ˮ�߼Ĵ��� ----------------
    logic [DBL_WIDTH-1:0] stage1_A1, stage1_A2;
    logic [DBL_WIDTH-1:0] stage2_X1, stage2_X2;
    logic [DBL_WIDTH-1:0] stage2_X2, stage2_X4;
    logic [DBL_WIDTH-1:0] stage3_T1, stage3_T2, stage3_T3;
    logic [DBL_WIDTH-1:0] stage4_T4;
    logic [1:0]            pipe_valid;

    // �������
    wire [DBL_WIDTH-1:0] sum_QR;  // Q+R

    // ================= ������ģ��ʵ���� =================
    // Stage1: A1 = ��[10,7]+��[7,4]��   X1 = 2��t * ��[7,4]
    fp_adder      U1_add_A1 (.clk(clk), .a(Theta_10_7), .b(Theta_7_4), .result(stage1_A1));
    fp_multiplier U1_mul_X1 (.clk(clk), .a(delta_t2),   .b(Theta_7_4),   .result(stage1_X1));

    // Stage2: X2 = ��t? * ��[8,5]��     X3 = ?��t? * A1
    fp_multiplier U2_mul_X2 (.clk(clk), .a(delta_t_sq),  .b(Theta_8_5),   .result(stage2_X2));
    fp_multiplier U2_mul_X3 (.clk(clk), .a(delta_t_hcu), .b(stage1_A1),   .result(stage2_X3));

    // Stage3: T1 = ��[10,4] + X1��     T2 = X2 + X3
    fp_adder      U3_add_T1 (.clk(clk), .a(Theta_10_4), .b(stage1_X1),   .result(stage3_T1));
    fp_adder      U3_add_T2 (.clk(clk), .a(stage2_X2), .b(stage2_X3),   .result(stage3_T2));

    // Stage4: T3 = ?��t?*��[9,9] + (Q+R)��  T4 = T1 + T2
    fp_multiplier U4_mul_X4 (.clk(clk), .a(delta_t_qr), .b(Theta_9_9),  .result(stage4_T3));
    fp_adder      U4_add_QR (.clk(clk), .a(Q_9_9),     .b(R_9_9),      .result(sum_QR));
    fp_adder      U4_add_T3 (.clk(clk), .a(stage4_T3), .b(sum_QR),      .result(stage4_T3));
    fp_adder      U4_add_T4 (.clk(clk), .a(stage3_T1), .b(stage3_T2),   .result(stage4_T4));

    // ================= ��ˮ�߼Ĵ������ =================
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
            // ͬ���������
            stage1_A1  <= stage1_A1;
            stage1_X1  <= stage1_X1;
            stage2_X2  <= stage2_X2;
            stage2_X3  <= stage2_X3;
            stage3_T1  <= stage3_T1;
            stage3_T2  <= stage3_T2;
            stage4_T3  <= stage4_T3;
            stage4_T4  <= stage4_T4;
            // valid ����
            pipe_valid <= {pipe_valid[0], 1'b1};
        end
    end

    // �������
    assign def       = stage4_T3 + stage4_T4; // �������� fp_adder ��һ�μӷ�
    assign valid_out = pipe_valid[1];

endmodule
