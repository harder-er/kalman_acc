`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 15:19:38
// Design Name: 
// Module Name: fp_adder
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

module fp_adder(
    input  logic clk,
    input  logic [64-1:0] a, b,
    output logic [64-1:0] result
);

    floating_point_add u_float_point_add(
      .aclk(clk),
      .s_axis_a_tvalid(a_tvalid),
      .s_axis_a_tdata(a_tdata),
      .s_axis_b_tvalid(b_tvalid),
      .s_axis_b_tdata(b_tdata),
      .s_axis_operation_tvalid(operation_tvalid),
      .s_axis_operation_tdata(operation_tdata),
      .m_axis_result_tvalid(result_tvalid),
      .m_axis_result_tdata(result_tdata)
    );
endmodule