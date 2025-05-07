//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 19:32:51
// Design Name: 
// Module Name: KalmanGainCalculator
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

module KalmanGainCalculator #(
    parameter DWIDTH = 64,
    parameter CMU_SIZE = 3,
    parameter FIFO_DEPTH = 16
)(
    input  logic                   clk,
    input  logic                   rst_n,
    
    // CMU����ӿڣ�4ͨ��MIBus��
    input  logic [DWIDTH-1:0]     P_prev_3x3 [0:CMU_SIZE-1][0:CMU_SIZE-1],  // 3x3����
    input  logic                   cmu_valid_in,
    
    // CEU����ӿڣ�3ͨ��MIBus�� 
    input  logic [DWIDTH-1:0]     R_matrix [0:2][0:2],  // ������������
    input  logic                   ceu_valid_in,
    
    // ����ӿڣ�OMBus��
    output logic [DWIDTH-1:0]     K_k [0:CMU_SIZE-1][0:CMU_SIZE-1],  // ����������
    output logic                   data_valid_out
);

// ���������� CMUģ�飨������㵥Ԫ��
//-----------------------------------------------------------------
logic [DWIDTH-1:0] P_predicted [0:CMU_SIZE-1][0:CMU_SIZE-1];
logic [DWIDTH-1:0] P_predicted_HT [0:CMU_SIZE-1][0:CMU_SIZE-1];
logic              cmu_complete;

CMU_3x3 #(
    .DWIDTH(DWIDTH)
) u_cmu (
    .clk(clk),
    .rst_n(rst_n),
    .P_prev(P_prev_3x3),
    .valid_in(cmu_valid_in),
    
    .P_predicted(P_predicted),
    .P_predicted_HT(P_predicted_HT),
    .cmu_done(cmu_complete)
);

// ���������� ���ݻ���FIFO
//-----------------------------------------------------------------
logic [DWIDTH*3-1:0] fifo_data_in;
logic [DWIDTH*3-1:0] fifo_data_out;
logic                fifo_wr_en, fifo_rd_en;
logic                fifo_full, fifo_empty;

FIFO_3x64 #(
    .DEPTH(FIFO_DEPTH),
    .DWIDTH(DWIDTH*3)
) u_fifo (
    .clk(clk),
    .rst_n(rst_n),
    .wr_en(fifo_wr_en),
    .data_in(fifo_data_in),
    .rd_en(fifo_rd_en),
    .data_out(fifo_data_out),
    .full(fifo_full),
    .empty(fifo_empty)
);

// FIFOд����ƣ��洢P_predicted��
always_comb begin
    fifo_wr_en = cmu_complete;
    for(int i=0; i<3; i++) begin
        fifo_data_in[i*DWIDTH +: DWIDTH] = P_predicted[i][0];  // �洢��0��
    end
end

// ���������� CEUģ�飨Ԫ�ؼ��㵥Ԫ��
//-----------------------------------------------------------------
logic [DWIDTH-1:0] inv_matrix [0:2][0:2];
logic              ceu_complete;

MatrixInverseUnit #(
    .DWIDTH(DWIDTH)
) u_MatrixInverseUnit (
    .clk(clk),
    .rst_n(rst_n),
    .H_P_HT(P_predicted_HT),
    .R_matrix(R_matrix),
    .valid_in(ceu_valid_in),
    
    .inv_matrix(inv_matrix),
    .ceu_done(ceu_complete)
);

// ���������� �������нӿ�
//-----------------------------------------------------------------
SystolicArray #(
    .DWIDTH(DWIDTH),
    .ARRAY_SIZE(3)
) u_systolic (
    .clk(clk),
    .rst_n(rst_n),
    .matrix_a(fifo_data_out),   // ����FIFO��P_predicted
    .matrix_b(inv_matrix),      // CEU����������
    .start(cmu_complete & ceu_complete),
    
    .result_matrix(K_k),
    .calc_done(data_valid_out)
);

// ���������� ʱ��ͬ������
//-----------------------------------------------------------------
typedef enum {IDLE, CMU_PROCESS, CEU_PROCESS, SYSTOLIC_START} fsm_state;
fsm_state current_state, next_state;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always_comb begin
    next_state = current_state;
    case(current_state)
        IDLE: 
            if(cmu_valid_in) next_state = CMU_PROCESS;
        
        CMU_PROCESS:
            if(cmu_complete) next_state = CEU_PROCESS;
        
        CEU_PROCESS:
            if(ceu_complete) next_state = SYSTOLIC_START;
        
        SYSTOLIC_START:
            if(data_valid_out) next_state = IDLE;
    endcase
end

assign fifo_rd_en = (current_state == SYSTOLIC_START);

endmodule


endmodule