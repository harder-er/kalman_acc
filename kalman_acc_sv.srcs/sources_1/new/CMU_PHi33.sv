`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 15:56:50
// Design Name: 
// Module Name: CMU_PHi33
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
// Company:
// Engineer:
//
// Create Date: 2025/05/09
// Module Name: CMU_PHi33
// Description: PHi33 通道的 CMU 计算，二级流水计算  
//              a = (Θ7,7 + Q7,7) + (2Δt·Θ7,10 + Δt²·Θ10,10)
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi33 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_7_7,
    // —— 时间参数 —— 
    input  logic [DBL_WIDTH-1:0]   two_dt,    // 2·Δt
    input  logic [DBL_WIDTH-1:0]   dt2,       // Δt²
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);


    // 中间信号
    logic [DBL_WIDTH-1:0] X1, X2, T1, T2;
    // 流水段寄存器
    logic [DBL_WIDTH-1:0] stage1_T1, stage1_X1, stage1_X2;
    logic [DBL_WIDTH-1:0] stage2_T2;
    logic [1:0]           valid_pipe;

    // ----------------- 子模块实例化 -----------------
    // X1 = 2Δt * Θ7,10
    fp_multiplier U_mul_X1 (
        .clk    (clk),
        .a      (two_dt),
        .b      (Theta_7_10),
        .result (X1)
    );
    // X2 = Δt² * Θ10,10
    fp_multiplier U_mul_X2 (
        .clk    (clk),
        .a      (dt2),
        .b      (Theta_10_10),
        .result (X2)
    );
    // T1 = Θ7,7 + Q7,7
    fp_adder U_add_T1 (
        .clk    (clk),
        .a      (Theta_7_7),
        .b      (Q_7_7),
        .result (T1)
    );
    // T2 = X1 + X2
    fp_adder U_add_T2 (
        .clk    (clk),
        .a      (stage1_X1),
        .b      (stage1_X2),
        .result (T2)
    );
    // final a = T1 + T2
    fp_adder U_add_final (
        .clk    (clk),
        .a      (stage1_T1),
        .b      (stage2_T2),
        .result (a)
    );

    // ----------------- 流水线寄存与控制 -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_T1   <= '0;
            stage1_X1   <= '0;
            stage1_X2   <= '0;
            stage2_T2   <= '0;
            valid_pipe  <= 2'b00;
        end else begin
            // Stage1 寄存 T1, X1, X2
            stage1_T1   <= T1;
            stage1_X1   <= X1;
            stage1_X2   <= X2;
            // Stage2 寄存 T2
            stage2_T2   <= T2;
            // valid 管线移位注入
            valid_pipe  <= { valid_pipe[0], 1'b1 };
        end
    end

    assign valid_out = valid_pipe[1];

endmodule
