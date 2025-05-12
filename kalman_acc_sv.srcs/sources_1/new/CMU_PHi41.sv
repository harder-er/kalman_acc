`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 15:59:09
// Design Name: 
// Module Name: CMU_PHi41
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
// Module Name: CMU_PHi41
// Description: PHi41 通道的 CMU 计算，四级流水  
//              a = X3 + (T1 + (X1 + X2))
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi41 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_10_1,
    input  logic [DBL_WIDTH-1:0]   Theta_10_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_10_1,
    // —— 时间参数 —— 
    input  logic [DBL_WIDTH-1:0]   delta_t,      // Δt
    input  logic [DBL_WIDTH-1:0]   half_dt2,     // ½·Δt²
    input  logic [DBL_WIDTH-1:0]   sixth_dt3,    // ⅙·Δt³
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);


    // 中间信号
    logic [DBL_WIDTH-1:0] X1, X2, X3;
    logic [DBL_WIDTH-1:0] T1, T2, T3;
    logic [3:0]           valid_pipe;

    // ----------------- 子模块实例化 -----------------
    // X1 = Δt * Θ10,4
    fp_multiplier U_mul_X1 (
        .clk    (clk),
        .a      (delta_t),
        .b      (Theta_10_4),
        .result (X1)
    );
    // X2 = ½Δt² * Θ10,7
    fp_multiplier U_mul_X2 (
        .clk    (clk),
        .a      (half_dt2),
        .b      (Theta_10_7),
        .result (X2)
    );
    // X3 = ⅙Δt³ * Θ10,10
    fp_multiplier U_mul_X3 (
        .clk    (clk),
        .a      (sixth_dt3),
        .b      (Theta_10_10),
        .result (X3)
    );
    // T1 = Θ10,1 + Q10,1
    fp_adder U_add_T1 (
        .clk    (clk),
        .a      (Theta_10_1),
        .b      (Q_10_1),
        .result (T1)
    );
    // T2 = X1 + X2
    fp_adder U_add_T2 (
        .clk    (clk),
        .a      (X1),
        .b      (X2),
        .result (T2)
    );
    // T3 = T1 + T2
    fp_adder U_add_T3 (
        .clk    (clk),
        .a      (T1),
        .b      (T2),
        .result (T3)
    );
    // final a = X3 + T3
    fp_adder U_add_final (
        .clk    (clk),
        .a      (X3),
        .b      (T3),
        .result (a)
    );

    // ----------------- 流水线寄存与控制 -----------------
    // 阶段寄存器
    logic [DBL_WIDTH-1:0] stage1_X1, stage1_X2, stage1_X3, stage1_T1;
    logic [DBL_WIDTH-1:0] stage2_T2;
    logic [DBL_WIDTH-1:0] stage3_T3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_X1   <= '0;
            stage1_X2   <= '0;
            stage1_X3   <= '0;
            stage1_T1   <= '0;
            stage2_T2   <= '0;
            stage3_T3   <= '0;
            valid_pipe  <= 4'b0000;
        end else begin
            // Stage1: latch X1, X2, X3, T1
            stage1_X1   <= X1;
            stage1_X2   <= X2;
            stage1_X3   <= X3;
            stage1_T1   <= T1;
            // Stage2: latch T2
            stage2_T2   <= T2;
            // Stage3: latch T3
            stage3_T3   <= T3;
            // valid pipeline: 4-stage delay
            valid_pipe  <= { valid_pipe[2:0], 1'b1 };
        end
    end

    assign valid_out = valid_pipe[3];

endmodule
