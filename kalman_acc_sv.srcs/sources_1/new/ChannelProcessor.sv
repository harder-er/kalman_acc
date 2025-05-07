`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 10:03:30
// Design Name: 
// Module Name: ChannelProcessor
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


module ChannelProcessor #(
    parameter WIDTH = 64
)(
    input  logic             clk,
    input  logic [2*WIDTH-1:0] data_in,
    input  logic             neg_en,     // ��ʹ�ܿ���
    output logic [WIDTH-1:0] data_out
);

logic [WIDTH-1:0] processed_data;

// ������������Ԫ
always_comb begin
    processed_data = neg_en ? -data_in[WIDTH-1:0] : data_in[WIDTH-1:0];
end

// ����˷�������
fp_mac_unit u_mac (
    .clk(clk),
    .a(processed_data),
    .b(data_in[2*WIDTH-1:WIDTH]),  // ������������
    .result(data_out)
);

endmodule