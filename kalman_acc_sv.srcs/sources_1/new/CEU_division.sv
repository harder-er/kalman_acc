`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 17:48:01
// Design Name: 
// Module Name: CEU_division
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: CEU_division
// Description:
//   �����ṩһ�������ӿڣ�������ź� {b,e,y} ��Ϊ���ӣ�alpha ��Ϊ��ĸ��
//   ������ǵĸ����� inv_alpha = (b,e,y) / alpha��
// Dependencies:
//   �����ɵ� Xilinx/AMD Floating-Point Divider IP �� (64-bit IEEE-754)
//
//////////////////////////////////////////////////////////////////////////////////

module CEU_division #(
    parameter DBL_WIDTH = 64           // IEEE-754 double precision
)(
    input  logic                   clk,
    input  logic [DBL_WIDTH-1:0]   numerator,    // ���� {b,e,y} ��Ͻ��
    input  logic [DBL_WIDTH-1:0]   denominator,  // ��ĸ alpha������ʽֵ��
    output logic [DBL_WIDTH-1:0]   quotient      // ��� 1/�� ����ӣ���ĸ
);

    // --- ������� IP �� �ź����� ---
    // �����ź����ƶ�Ӧ Core Generator ���ɵ� AXI-Stream �ӿ�
    // ds335.pdf �е�ʾ��ͨ��Ϊ��
    //   s_axis_dividend_tdata, s_axis_dividend_tvalid
    //   s_axis_divisor_tdata,  s_axis_divisor_tvalid
    //   m_axis_dout_tdata,     m_axis_dout_tvalid
    //
    logic                     div_dividend_tvalid = 1'b1;
    logic                     div_divisor_tvalid  = 1'b1;
    logic                     div_dividend_tready;
    logic                     div_divisor_tready;
    logic                     div_dout_tvalid;
    logic                     div_dout_tready  = 1'b1;

    // --- ����ʵ���� Floating-Point Divider IP ---
    floating_point_div u_floating_point_div (
        .aclk                    (clk),
        // ��������
        .s_axis_dividend_tdata   (numerator),
        .s_axis_dividend_tvalid  (div_dividend_tvalid),
        .s_axis_dividend_tready  (div_dividend_tready),
        // ��ĸ����
        .s_axis_divisor_tdata    (denominator),
        .s_axis_divisor_tvalid   (div_divisor_tvalid),
        .s_axis_divisor_tready   (div_divisor_tready),
        // �����
        .m_axis_dout_tdata       (quotient),
        .m_axis_dout_tvalid      (div_dout_tvalid),
        .m_axis_dout_tready      (div_dout_tready)
    );
    // Note: �� IP �˻����ڲ�����ˮ�߼����ӳٺ󣬽� quotient �������
    // m_axis_dout_tvalid ���ߣ�ָʾ������Ч���������һ��С�Ĵ���
    // ���л� handshake �źŽ�һ��ͬ����

endmodule

