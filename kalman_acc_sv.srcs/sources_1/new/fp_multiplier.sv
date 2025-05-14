`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 09:42:35
// Design Name: 
// Module Name: fp_multiplier       // ����˷���ģ�飨ʵ���������㣩
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: ʵ���������ݵ��������㣬����������ˮ�߼ܹ�
// 
// Dependencies: ��������ƽ�����㵥Ԫfp_square
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: ��ˮ�߽׶ΰ������ݼĴ桢ƽ�����㡢�����ϳ�
// 
//////////////////////////////////////////////////////////////////////////////////

module fp_multiplier (
    input  logic [64-1:0] a, b,
    output logic [64-1:0] result
);
    // ʵ����˫���ȳ˷���IP
    floating_point_mul u1_floating_point_mul(                       //�˷���
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tdata(a),
    .s_axis_b_tvalid(b_tvalid),
    .s_axis_b_tdata(b),
    .m_axis_result_tvalid(mul_result_tvalid),
    .m_axis_result_tdata(mul_result_tdata)
);

endmodule