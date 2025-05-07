`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/24 15:40:54
// Design Name: 
// Module Name: SystolicArray
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


module SystolicArray #(
    parameter DWIDTH = 64,
    parameter MAX_SIZE = 12
)(
    input  logic             clk,
    input  logic             rst_n,
    
    // ��������ӿ�
    input  logic [DWIDTH-1:0] a_row [0:MAX_SIZE-1],
    input  logic [DWIDTH-1:0] b_col [0:MAX_SIZE-1],
    input  logic             load_en,
    
    // �ع������ź�
    input  logic             enb_1,
    input  logic             enb_2_6,
    input  logic             enb_7_12,
    
    // ������
    output logic [DWIDTH-1:0] c_out [0:MAX_SIZE-1][0:MAX_SIZE-1]
);

// ���������� ����Ĵ�����
//-----------------------------------------------------------------
logic [DWIDTH-1:0] a_reg [0:MAX_SIZE-1][0:MAX_SIZE-1];
logic [DWIDTH-1:0] b_reg [0:MAX_SIZE-1][0:MAX_SIZE-1];

always_ff @(posedge clk) begin
    if(load_en) begin
        // ���м��ؾ���A
        for(int i=0; i<MAX_SIZE; i++) begin
            a_reg[i][0] <= a_row[i];  // ���Ĵ�����
        end
        
        // ���м��ؾ���B 
        for(int j=0; j<MAX_SIZE; j++) begin
            b_reg[0][j] <= b_col[j];  // �����Ĵ�����
        end
    end
end

// ���������� ���ع�������
//-----------------------------------------------------------------
logic [MAX_SIZE-1:0] row_enable;

always_comb begin
    row_enable = '0;
    case({enb_7_12, enb_2_6, enb_1})
        3'b001: row_enable[0] = 1'b1;        // ��1��
        3'b010: row_enable[5:1] = '1;        // ��2-6��
        3'b100: row_enable[11:6] = '1;       // ��7-12��
        default: row_enable = '0;
    endcase
end

// ���������� �ӳټ���������
//-----------------------------------------------------------------
logic [3:0] delay_counter [0:MAX_SIZE-1][0:MAX_SIZE-1];

generate
for(genvar i=0; i<MAX_SIZE; i++) begin
    for(genvar j=0; j<MAX_SIZE; j++) begin
        always_ff @(posedge clk) begin
            if(i==0 && j==0) 
                delay_counter[i][j] <= 4'd0;
            else
                delay_counter[i][j] <= delay_counter[i][j] + 1;
        end
    end
end
endgenerate

// ���������� PE����Ԫ����
//-----------------------------------------------------------------
logic [DWIDTH-1:0] a_data [0:MAX_SIZE][0:MAX_SIZE];
logic [DWIDTH-1:0] b_data [0:MAX_SIZE][0:MAX_SIZE];
logic [DWIDTH-1:0] c_data [0:MAX_SIZE][0:MAX_SIZE];

generate
for(genvar i=0; i<MAX_SIZE; i++) begin
    for(genvar j=0; j<MAX_SIZE; j++) begin
        ProcessingElement u_pe (
            .clk(clk),
            .rst_n(rst_n),
            .en(row_enable[i]),
            .delay(delay_counter[i][j]),
            
            // ����ͨ·
            .a_in(a_data[i][j]),
            .b_in(b_data[i][j]),
            .c_in((i==0 && j==0) ? '0 : c_data[i-1][j]),
            
            .a_out(a_data[i][j+1]),
            .b_out(b_data[i+1][j]),
            .c_out(c_data[i][j])
        );
        
        // �߽�����
        if(j == 0) assign a_data[i][j] = a_reg[i][0];
        if(i == 0) assign b_data[i][j] = b_reg[0][j];
        
        // ������
        assign c_out[i][j] = c_data[i][j];
    end
end
endgenerate

endmodule
