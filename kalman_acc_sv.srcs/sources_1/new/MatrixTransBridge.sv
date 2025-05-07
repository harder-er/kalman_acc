`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 21:14:58
// Design Name: 
// Module Name: MatrixTransBridge
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

module MatrixTransBridge #(
    parameter ROWS = 8,        // ��������
    parameter COLS = 8,        // ��������
    parameter DATA_WIDTH = 64  // ����λ����ҳ6��8x8������չ��
)(
    input  logic                     clk,       // ϵͳʱ�ӣ���ҳ8ʱ����ƣ�
    input  logic                     rst_n,     // �첽��λ
    input  logic [DATA_WIDTH-1:0]    mat_in [0:ROWS-1][0:COLS-1], // �������
    output logic [DATA_WIDTH-1:0]    mat_org [0:ROWS-1][0:COLS-1],// ԭ�������
    output logic [DATA_WIDTH-1:0]    mat_trans [0:COLS-1][0:ROWS-1],// ת�þ���
    output logic                     valid_out  // �����Ч��־
);

// �������� ����Ĵ����飨��ҳ7��λ�Ĵ��������Ľ���
logic [DATA_WIDTH-1:0] input_buffer [0:ROWS-1][0:COLS-1];

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        foreach(input_buffer[i,j]) 
            input_buffer[i][j] <= '0;
    end else begin
        input_buffer <= mat_in;  // ͬ���������루��ҳ8�����߼���
    end
end

// �������� ת�������߼�����ҳ6ѭ�������Ż���
generate
    for(genvar i=0; i<ROWS; i++) begin : row_gen
        for(genvar j=0; j<COLS; j++) begin : col_gen
            // ԭ����ֱͨ�������ҳ1�������ԭ��
            assign mat_org[i][j] = input_buffer[i][j];
            
            // ת�þ������ɣ���ҳ6ת���߼����ģ�
            assign mat_trans[j][i] = input_buffer[i][j]; 
        end
    end
endgenerate

// �������� ʱ����Ƶ�Ԫ����ҳ8״̬���Ľ���
typedef enum {IDLE, PROCESS} state_t;
state_t curr_state;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        curr_state <= IDLE;
        valid_out <= 1'b0;
    end else begin
        case(curr_state)
            IDLE: begin
                valid_out <= 1'b0;
                if(&mat_in[ROWS-1][COLS-1]) // ���������ɣ���ҳ8���üĴ���˼�룩
                    curr_state <= PROCESS;
            end
            PROCESS: begin
                valid_out <= 1'b1;          // �����Ч�ź�
                curr_state <= IDLE;
            end
        endcase
    end
end

endmodule
