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
    parameter DBL_WIDTH = 64,
    parameter CHANNEL   = "d"   // "d"/"e"/"f"
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // ��̬����
    input  logic [DBL_WIDTH-1:0]   Theta_ij,    // ��[i,j]
    input  logic [DBL_WIDTH-1:0]   Theta_ik,    // ��[i,k]
    input  logic [DBL_WIDTH-1:0]   Theta_mj,    // ��[m,j]
    input  logic [DBL_WIDTH-1:0]   Theta_mk,    // ��[m,k]
    input  logic [DBL_WIDTH-1:0]   Theta_mm,    // ��[m,m]
    input  logic [DBL_WIDTH-1:0]   Q_ii,        // Q[i,i]
    input  logic [DBL_WIDTH-1:0]   R_ii,        // R[i,i]
    // �̶�����
    input  logic [DBL_WIDTH-1:0]   delta_t2,    // 2��t
    input  logic [DBL_WIDTH-1:0]   delta_t_sq,  // ��t?
    input  logic [DBL_WIDTH-1:0]   delta_t_hcu, // ?����t?
    input  logic [DBL_WIDTH-1:0]   delta_t_qr,  // ?����t?
    // ���
    output logic [DBL_WIDTH-1:0]   result,      // ��� d/e/f
    output logic                   valid_out
);

    // ----------------- ��ˮ�߼Ĵ��� -----------------
    logic [DBL_WIDTH-1:0] stage1_A1, stage1_X1;
    logic [DBL_WIDTH-1:0] stage2_X2, stage2_X3;
    logic [DBL_WIDTH-1:0] stage3_T1, stage3_T2;
    logic [DBL_WIDTH-1:0] stage4_X4, stage4_T3, stage4_T4;
    logic [4:0]           pipe_valid;

    // ----------------- ��ʱ���� -----------------
    wire  [DBL_WIDTH-1:0] sum_QR;  // Q_ii + R_ii

    // ----------------- ������ģ��ʵ���� -----------------
    // Stage 1: A1 = ��[m,k] + ��[i,k]��  X1 = 2��t * ��[i,k]
    fp_adder      U_add_A1 (.clk(clk), .a(Theta_mk), .b(Theta_ik), .result(stage1_A1));
    fp_multiplier U_mul_X1 (.clk(clk), .a(delta_t2),   .b(Theta_ik), .result(stage1_X1));

    // Stage 2: X2 = ��t? * ��[m,j]��  X3 = ?��t? * A1
    fp_multiplier U_mul_X2 (.clk(clk), .a(delta_t_sq), .b(Theta_mj),  .result(stage2_X2));
    fp_multiplier U_mul_X3 (.clk(clk), .a(delta_t_hcu),.b(stage1_A1), .result(stage2_X3));

    // Stage 3: T1 = ��[i,j] + X1��  T2 = X2 + X3
    fp_adder      U_add_T1 (.clk(clk), .a(Theta_ij), .b(stage1_X1), .result(stage3_T1));
    fp_adder      U_add_T2 (.clk(clk), .a(stage2_X2),.b(stage2_X3), .result(stage3_T2));

    // Stage 4:
    //   X4 = ?��t? * ��[m,m]
    //   sum_QR = Q_ii + R_ii
    //   T3 = X4 + sum_QR
    //   T4 = T1 + T2
    fp_multiplier U_mul_X4 (.clk(clk), .a(delta_t_qr), .b(Theta_mm), .result(stage4_X4));
    fp_adder      U_add_QR (.clk(clk), .a(Q_ii),       .b(R_ii),     .result(sum_QR));
    fp_adder      U_add_T3 (.clk(clk), .a(stage4_X4),  .b(sum_QR),   .result(stage4_T3));
    fp_adder      U_add_T4 (.clk(clk), .a(stage3_T1),  .b(stage3_T2),.result(stage4_T4));

    // Stage 5: final result = T4 + T3
    fp_adder      U_final  (.clk(clk), .a(stage4_T4),  .b(stage4_T3),.result(result));

    // ----------------- �����ź���ˮ -----------------
    // �弶��ˮ��Stage1��Stage5��������λ�Ĵ������� valid �ź�
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A1  <= '0;
            stage1_X1  <= '0;
            stage2_X2  <= '0;
            stage2_X3  <= '0;
            stage3_T1  <= '0;
            stage3_T2  <= '0;
            stage4_X4  <= '0;
            stage4_T3  <= '0;
            stage4_T4  <= '0;
            pipe_valid <= 5'b00000;
        end else begin
            // ͬ�����μ���������һ���Ĵ���
            stage1_A1  <= stage1_A1;
            stage1_X1  <= stage1_X1;
            stage2_X2  <= stage2_X2;
            stage2_X3  <= stage2_X3;
            stage3_T1  <= stage3_T1;
            stage3_T2  <= stage3_T2;
            stage4_X4  <= stage4_X4;
            stage4_T3  <= stage4_T3;
            stage4_T4  <= stage4_T4;

            // ������Ч�ź����Ʋ�ע����"1"
            // ע��LSB ��Ӧ��һ�����룬MSB��pipe_valid[4]����Ӧ�������
            pipe_valid <= { pipe_valid[3:0], 1'b1 };
        end
    end

    // �����弶��Stage5���������ʱ��valid_out ����
    assign valid_out = pipe_valid[4];

endmodule
