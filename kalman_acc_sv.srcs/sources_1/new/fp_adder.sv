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
    input  logic clk                ,
    input  logic [64-1:0] a, b      ,
    input  logic          valid     ,
    output logic          finish    ,
    output logic [64-1:0] result
);
    logic s_axis_a_tready;
    logic s_axis_b_tready;
    logic m_axis_result_tvalid;
    floating_point_add u_floating_point_add (
		.aclk                   ( clk           		),             // 时钟
		// A 通道   
		.s_axis_a_tvalid        ( valid         		),        // 输入 A 有效
		.s_axis_a_tready        ( s_axis_a_tready      	),        // 输入 A 就绪
		.s_axis_a_tdata         ( a             		),         // 输入 A 数据
		// B 通道   
		.s_axis_b_tvalid        ( valid         		),        // 输入 B 有效
		.s_axis_b_tready        ( s_axis_b_tready      	),        // 输入 B 就绪
		.s_axis_b_tdata         ( b             		),         // 输入 B 数据
		// 输出结果通道
		.m_axis_result_tvalid   ( m_axis_result_tvalid  ),   // 结果有效
		.m_axis_result_tready   ( 1'b1          		),   // 结果就绪
		.m_axis_result_tdata    ( result         		)     // 结果数据
	);

    assign finish = m_axis_result_tvalid & s_axis_a_tready & s_axis_b_tready;

endmodule