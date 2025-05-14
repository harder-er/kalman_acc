`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 09:42:35
// Design Name: 
// Module Name: fp_multiplier       // 浮点乘法器模块（实现立方运算）
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 实现输入数据的立方运算，采用三级流水线架构
// 
// Dependencies: 依赖浮点平方计算单元fp_square
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 流水线阶段包括数据寄存、平方计算、立方合成
// 
//////////////////////////////////////////////////////////////////////////////////

module fp_multiplier (
    input  logic [64-1:0] a, b,
    output logic [64-1:0] result
);
    // 实例化双精度乘法器IP
    floating_point_mul u1_floating_point_mul(                       //乘法器
    .aclk(clk),
    .s_axis_a_tvalid(a_tvalid),
    .s_axis_a_tdata(a),
    .s_axis_b_tvalid(b_tvalid),
    .s_axis_b_tdata(b),
    .m_axis_result_tvalid(mul_result_tvalid),
    .m_axis_result_tdata(mul_result_tdata)
);

endmodule