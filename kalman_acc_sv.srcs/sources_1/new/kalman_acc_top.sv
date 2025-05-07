`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/10 11:35:25
// Design Name: 
// Module Name: KalmanFilterTop  // �������˲�������ģ��
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: ʵ�ֿ������˲��㷨�Ķ��㼯��ģ�飬����״̬Ԥ���������������׶�
// 
// Dependencies: ����״̬Ԥ�⡢Э����Ԥ�⡢������㡢״̬���µ���ģ��
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: ֧��12ά״̬������6ά����������ʵʱ�˲�����
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module KalmanFilterTop #(
    parameter STATE_DIM  = 12,
    parameter MEASURE_DIM = 6
)(
    input  logic         clk,
    input  logic         rst_n,
    
    // ϵͳģ�Ͳ���
    input  logic [31:0]  F [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [31:0]  H [MEASURE_DIM-1:0][STATE_DIM-1:0],
    input  logic [31:0]  Qk[STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [31:0]  Rk[MEASURE_DIM-1:0][MEASURE_DIM-1:0],
    
    // ʵʱ���ݽӿ�
    input  logic [31:0]  Zk[MEASURE_DIM-1:0],
    input  logic [31:0]  Xk_prev[STATE_DIM-1:0],
    input  logic [31:0]  Pk_prev[STATE_DIM-1:0][STATE_DIM-1:0],
    
    // �˲�������
    output logic [31:0]  Xk_k[STATE_DIM-1:0],
    output logic [31:0]  Pk_k[STATE_DIM-1:0][STATE_DIM-1:0],
    
    // ״̬�����ƽӿ�
    input  logic         Init_Valid,
    output logic         SP_Done,
    output logic         CKG_Done,
    output logic         SCU_Done,
    input  logic         MDI_Valid,
    input  logic         SCO_Valid
);

// ================== ���Ƶ�Ԫʵ���� ==================
KF_ControlUnit u_ControlUnit (
    .clk(clk),
    .rst(rst_n),
    // ״̬ת������
    .Init_Valid(Init_Valid),
    .SP_Valid(1'b0),
    .SP_Done(SP_Done),
    .CKG_Valid(1'b0),
    .CKG_Done(CKG_Done),
    .SCU_Valid(1'b0),
    .SCU_Done(SCU_Done),
    .MDI_Valid(MDI_Valid),
    .SCO_Valid(SCO_Valid),
    // �������
    .SP_Start(SP_Start),
    .CKG_Start(CKG_Start),
    .SCU_Start(SCU_Start)
);

// ================== Ԥ��׶� ==================
// ״̬Ԥ��ģ��
StatePredictor #(.STATE_DIM(STATE_DIM)) u_StatePredictor (
    .clk(clk),
    .rst_n(rst_n),
    .F(F),
    .Xk_prev(Xk_prev),
    .ctrl_flag(SP_Start),    // ��״̬������
    .Xk_pred(Xk_k_minus1)
);

// Э����Ԥ��ģ��
//CovariancePredictor #(.STATE_DIM(STATE_DIM)) u_CovPredictor (
//    .clk(clk),
//    .rst_n(rst_n),
//    .F(F),
//    .Pk_prev(Pk_prev),
//    .Qk(Qk),
//    .ctrl_flag(SP_Start),    // ��״̬Ԥ��ͬ��
//    .Pm_k(Pm_k)
//);

// ================== ���½׶� ==================
// ����ת��ģ�飨H^T��
MatrixTransBridge #(MEASURE_DIM, STATE_DIM) u_HT_Transpose_Bridge (
    .matrix_in(H),
    .matrix_out(HT)
);

// ������������㵥Ԫ
KalmanGainCalculator #(
    .DWIDTH(64),
    .CMU_SIZE(3),
    .FIFO_DEPTH(16)
) u_KalmanGainCalc (
    .clk(clk),
    .rst_n(rst_n),
    .P_prev_3x3(Pm_k[11:9][11:9]),  // ȡ3x3�Ӿ���
    .cmu_valid_in(CKG_Start),
    .R_matrix(Rk[5:3][5:3]),       // ȡ3x3�Ӿ���
    .ceu_valid_in(CKG_Start),
    .K_k(Kk_sub),                  // 3x3�����Ӿ���
    .data_valid_out(CKG_Done)
);

// ״̬����ģ��
StateUpdate #(.STATE_DIM(STATE_DIM)) u_StateUpdate (
    .clk(clk),
    .rst_n(rst_n),
    .Kk(Kk),
    .Zk(Zk),
    .Xk_pred(Xk_k_minus1),
    .H(H),
    .Xk_updated(Xk_k)
);

// Э�������ģ��
CovarianceUpdate #(.STATE_DIM(STATE_DIM)) u_CovUpdate (
    .clk(clk),
    .rst_n(rst_n),
    .Kk(Kk),
    .H(H),
    .Pm_k(Pm_k),
    .Pk_updated(Pk_k)
);

// ================== ʱ����뵥Ԫ ==================
DelayUnit #(3, STATE_DIM*32) u_DelayX (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(Xk_k_minus1),
    .data_out(Xk_delayed)
);

DelayUnit #(2, STATE_DIM*STATE_DIM*32) u_DelayP (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(Pm_k),
    .data_out(Pm_delayed)
);

// ================== �ӿ�ӳ�� ==================
assign SP_Done = u_StatePredictor.done && u_CovPredictor.done;
assign SCU_Done = u_CovUpdate.done;

endmodule

