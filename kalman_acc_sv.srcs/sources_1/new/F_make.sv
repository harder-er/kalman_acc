`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/12 11:32:40
// Design Name: 
// Module Name: F_make
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


module Fmake (
    input          clk,      // 时钟信号
    input          rst_n,    // 异步复位（低有效）
    input  [63:0]  deltat,   // 时间步长Δt（双精度浮点）
    output reg [63:0] F [0:11][0:11] // 12x12双精度浮点矩阵
);

// 浮点运算IP核声明
wire [63:0] deltat_sq, deltat_cu, deltat_sq_div2, deltat_cu_div6, deltat_sq_div6;

// 实例化浮点乘法器（Xilinx示例命名）
floating_point_mult mult_dt2 (
  .aclk(clk),
  .s_axis_a_tvalid(1'b1),
  .s_axis_a_tdata(deltat),
  .s_axis_b_tvalid(1'b1),
  .s_axis_b_tdata(deltat),
  .m_axis_result_tdata(deltat_sq)
);

floating_point_mult mult_dt3 (
  .aclk(clk),
  .s_axis_a_tvalid(1'b1),
  .s_axis_a_tdata(deltat_sq),
  .s_axis_b_tvalid(1'b1),
  .s_axis_b_tdata(deltat),
  .m_axis_result_tdata(deltat_cu)
);

// 浮点除法IP核（配置为双精度）
floating_point_div div_2 (
  .aclk(clk),
  .s_axis_a_tvalid(1'b1),
  .s_axis_a_tdata(deltat_sq),
  .s_axis_b_tvalid(1'b1),
  .s_axis_b_tdata(64'h4000000000000000), // 浮点数2.0
  .m_axis_result_tdata(deltat_sq_div2)
);

floating_point_div div_6 (
  .aclk(clk),
  .s_axis_a_tvalid(1'b1),
  .s_axis_a_tdata(deltat_cu),
  .s_axis_b_tvalid(1'b1),
  .s_axis_b_tdata(64'h4018000000000000), // 浮点数6.0
  .m_axis_result_tdata(deltat_cu_div6)
);

floating_point_div div_sq6 (
  .aclk(clk),
  .s_axis_a_tvalid(1'b1),
  .s_axis_a_tdata(deltat_sq),
  .s_axis_b_tvalid(1'b1),
  .s_axis_b_tdata(64'h4018000000000000), // 6.0
  .m_axis_result_tdata(deltat_sq_div6)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 初始化主对角线为1.0，其他为0
        for (int i=0; i<12; i++) begin
            for (int j=0; j<12; j++) begin
                F[i][j] <= (i == j) ? 64'h3FF0000000000000 : 64'h0000000000000000;
            end
        end
    end else begin
        // 保持主对角线为1.0
        for (int i=0; i<12; i++) F[i][i] <= 64'h3FF0000000000000;

        // 动态更新非对角元素
        // 一阶项（Δt）
        F[0][3]  <= deltat;
        F[1][4]  <= deltat;
        F[2][5]  <= deltat;
        F[3][6]  <= deltat;
        F[4][7]  <= deltat;
        F[5][8]  <= deltat;

        // 二阶项（1/2Δt²）
        F[0][6]  <= deltat_sq_div2;
        F[1][7]  <= deltat_sq_div2;
        F[2][8]  <= deltat_sq_div2;
        F[3][9]  <= deltat_sq_div2;

        // 三阶项（1/6Δt³）
        F[0][9]  <= deltat_cu_div6;
        F[1][10] <= deltat_cu_div6;
        F[2][11] <= deltat_cu_div6;

        // 特殊项（1/6Δt²）
        F[3][6]  <= deltat_sq_div6;
        F[6][9]  <= deltat_sq_div2;
    end
end

endmodule
