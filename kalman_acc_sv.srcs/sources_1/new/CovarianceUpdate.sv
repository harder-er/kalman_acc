//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 19:46:55
// Design Name: 
// Module Name: CovarianceUpdate
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


`timescale 1ns/1ps
module CovarianceUpdate #(
    parameter STATE_DIM = 12,
    parameter DWIDTH = 64,
    parameter FIFO_DEPTH = 12
)(
    input  logic                     clk,
    input  logic                     rst_n,
    // MIBus����ӿڣ���Ӧͼʾ��ɫģ��ӿڣ�
    input  logic [DWIDTH-1:0]       Kk [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       H [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       Rk [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       P_prev [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic                     valid_in,
    // OMBus����ӿڣ���Ӧͼʾ��ɫ���·����
    output logic [DWIDTH-1:0]       Pk_k [STATE_DIM-1:0][STATE_DIM-1:0],
    output logic                     valid_out
);

// ================== �������к��ĵ�Ԫ ==================
// ����˷���Ԫ���ã���Ӧͼʾ��ɫ����ģ�飩
generate
    // K*R���㵥Ԫ����Ӧͼʾ·���٣�
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_KR (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(Kk),         // K����������
        .b_col(Rk),         // R����������
        .load_en(valid_in),
        .enb_1(1'b0),       // ȫ���м���
        .enb_2_6(1'b0),
        .enb_7_12(1'b1),
        .c_out(KR_result)   // �����FIFO
    );

    // (K*R)*K^T���㵥Ԫ����Ӧͼʾ·���ڣ�
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_KRKt (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(KR_result),  // K*R�������
        .b_col(transpose(Kk)), // Kת������
        .load_en(kr_done),
        .enb_1(1'b0),
        .enb_2_6(1'b0),
        .enb_7_12(1'b1),
        .c_out(KRKt)
    );

    // K*H���㵥Ԫ����Ӧͼʾ·���ۣ�
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_KH (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(Kk),
        .b_col(H),
        .load_en(valid_in),
        .enb_1(1'b1),       // ����������PE
        .enb_2_6(1'b0),
        .enb_7_12(1'b0),
        .c_out(KH)
    );

    // (I-KH)*P_prev���㵥Ԫ����Ӧͼʾ·���ܣ�
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_IKH_P (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(generate_I() - KH), // Ӳ�����ɵ�λ����
        .b_col(P_prev),
        .load_en(ikh_done),
        .enb_1(1'b0),
        .enb_2_6(1'b1),      // �����м�����
        .enb_7_12(1'b0),
        .c_out(IKH_P)
    );
endgenerate

// ================== �����߼���ǿ����Ӧͼʾ״̬���� ==================
// ��̬�ع����Ƶ�Ԫ����ȷƥ��ͼʾenb�źţ�
always_comb begin
    case(current_state)
        IDLE: begin
            u_KR.enb_1 = 1'b0;
            u_KRKt.enb_7_12 = 1'b1;
            u_KH.enb_1 = 1'b1;
            u_IKH_P.enb_2_6 = 1'b1;
        end
        // ...����״̬�����ź�ӳ��...
    endcase
end

// ================== �������Ż�����Ӧͼʾ��ͷ���� ==================
// ����ת�ù���ʵ�֣���ӦͼʾH^T·����
function automatic [STATE_DIM-1:0][STATE_DIM-1:0] transpose;
    input [STATE_DIM-1:0][STATE_DIM-1:0] matrix_in;
    begin
        for(int i=0; i<STATE_DIM; i++)
            for(int j=0; j<STATE_DIM; j++)
                transpose[j][i] = matrix_in[i][j];
    end
endfunction

// ��λ��������������ӦͼʾI-KH���㣩
function [STATE_DIM-1:0][STATE_DIM-1:0] generate_I;
    for(int i=0; i<STATE_DIM; i++) begin
        for(int j=0; j<STATE_DIM; j++) begin
            generate_I[i][j] = (i == j) ? {DWIDTH{1'b1}} : '0;
        end
    end
endfunction

// ================== ʱ����뵥Ԫ����Ӧͼʾ�����ӳ�ģ�飩 ==================
DelayUnit #(
    .DEPTH(4),  // �ļ���ˮ���ӳ�
    .DATA_WIDTH(STATE_DIM*STATE_DIM*DWIDTH)
) u_delay (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(temp_sum),
    .data_out(Pk_k)
);

// ================== �쳣����ͼʾδ��ʾ���ؼ��� ==================
// ��������ֵ���
always_ff @(posedge clk) begin
    if(u_KRKt.singular_detect) begin
        $error("Singular matrix detected in KRKt calculation");
        valid_out <= 1'b0;
    end
end

endmodule