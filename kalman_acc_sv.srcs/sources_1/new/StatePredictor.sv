`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 09:58:38
// Design Name: 
// Module Name: StatePredictor
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

module StatePredictor #(
    parameter VEC_WIDTH = 64,
    parameter MAT_DIM = 12
)(
    input  logic             clk,
    input  logic             rst_n,
    
    // ϵͳ����ӿ�
    input  logic [VEC_WIDTH-1:0] X_k_k_1,     // ��һʱ��״̬����
    input  logic [VEC_WIDTH-1:0] Kk,          // Kalman����
    input  logic [MAT_DIM*VEC_WIDTH-1:0] P_prev, // Э�������
    
    // ���߽ӿ�
    output MIBus_if          predict_bus,    // Ԥ������
    input  FIFO_if           fifo_in,        // �۲���������
    
    // ϵͳ���
    output logic [VEC_WIDTH-1:0] Z_k         // ����Ԥ�����
);

// ==== ���Ĵ���ͨ���ṹ
//-----------------------------------------------------------------
logic [VEC_WIDTH-1:0] channel_reg [3:0];
logic [MAT_DIM*VEC_WIDTH-1:0] matrix_bus;

// ��ʼ��ģ�飨��Ӧͼ��Initģ�飩
InitBlock #(.WIDTH(VEC_WIDTH)) u_init (
    .clk(clk),
    .rst_n(rst_n),
    .initial_data(P_prev),
    .bus_out(matrix_bus[MAT_DIM*VEC_WIDTH-1:0])
);

// ������ͨ������Ӧͼ�к�ɫͨ��ģ�飩
ChannelProcessor #(.WIDTH(VEC_WIDTH)) u_channel (
    .clk(clk),
    .data_in({X_k_k_1, matrix_bus}),
    .neg_en(predict_bus.ctrl_flag),  // ���߿����ź�
    .data_out(channel_reg[0])
);

// �˷����У���Ӧͼ��MUXģ�飩
MatrixMultiplier u_mux (
    .clk(clk),
    .operand_a(channel_reg[0]),
    .operand_b(Kk),
    .result(channel_reg[1])
);

// �ݹ鷴��ͨ������Ӧͼ����ɫͨ����
RecursiveChannel u_feedback (
    .clk(clk),
    .data_in(channel_reg[1]),
    .fifo_data(fifo_in.data),
    .data_out(channel_reg[2])
);

// ��������ϳ�
assign Z_k = channel_reg[3];

// ==== ʱ����ƿ���
//-----------------------------------------------------------------
always_ff @(posedge clk) begin
    if(!rst_n) begin
        channel_reg <= '{default:0};
    end else begin
        // ������ˮ�߼Ĵ�
        channel_reg[3] <= channel_reg[2] + predict_bus.adjust_term;  // ����У����
    end
end

endmodule