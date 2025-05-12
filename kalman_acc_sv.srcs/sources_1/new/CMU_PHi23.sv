`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 15:37:32
// Design Name: 
// Module Name: CMU_PHi23
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
// Module Name: CMU_PHi23
// Description: PHi23 通道的 CMU 计算，三级流水  
//              a = (A1 + X1) + (X2 + X3)
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi23 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_4_7,
    // —— 时间参数 —— 
    input  logic [DBL_WIDTH-1:0]   delta_t,      // Δt
    input  logic [DBL_WIDTH-1:0]   half_dt2,     // ½·Δt²
    input  logic [DBL_WIDTH-1:0]   half_dt3,     // ½·Δt³
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);


    // 中间信号
    logic [DBL_WIDTH-1:0] A1, A2, A3;
    logic [DBL_WIDTH-1:0] X1, X2, X3;
    logic [DBL_WIDTH-1:0] T1, T2;
    logic [2:0]           valid_pipe;

    // ----------------- 子模块实例化 -----------------
    // A1 = Θ4,7 + Q4,7
    fp_adder U_add_A1 (
        .clk    (clk),
        .a      (Theta_4_7),
        .b      (Q_4_7),
        .result (A1)
    );
    // A2 = Θ7,7 + Θ4,10
    fp_adder U_add_A2 (
        .clk    (clk),
        .a      (Theta_7_7),
        .b      (Theta_4_10),
        .result (A2)
    );
    // A3 = Θ10,7 + Θ4,7 + Θ4,7
    wire [DBL_WIDTH-1:0] sum_tmp;
    fp_adder U_add_tmp (
        .clk    (clk),
        .a      (Theta_10_7),
        .b      (Theta_4_7),
        .result (sum_tmp)
    );
    fp_adder U_add_A3 (
        .clk    (clk),
        .a      (sum_tmp),
        .b      (Theta_4_7),
        .result (A3)
    );

    // X1 = Δt * A2
    fp_multiplier U_mul_X1 (
        .clk    (clk),
        .a      (delta_t),
        .b      (A2),
        .result (X1)
    );
    // X2 = ½Δt² * A3
    fp_multiplier U_mul_X2 (
        .clk    (clk),
        .a      (half_dt2),
        .b      (A3),
        .result (X2)
    );
    // X3 = ½Δt³ * Θ10,10
    fp_multiplier U_mul_X3 (
        .clk    (clk),
        .a      (half_dt3),
        .b      (Theta_10_10),
        .result (X3)
    );

    // T1 = A1 + X1
    fp_adder U_add_T1 (
        .clk    (clk),
        .a      (A1),
        .b      (X1),
        .result (T1)
    );
    // T2 = X2 + X3
    fp_adder U_add_T2 (
        .clk    (clk),
        .a      (X2),
        .b      (X3),
        .result (T2)
    );
    // final a = T1 + T2
    fp_adder U_add_final (
        .clk    (clk),
        .a      (T1),
        .b      (T2),
        .result (a)
    );

    // ----------------- 流水线寄存与控制 -----------------
    // 寄存各级结果
    logic [DBL_WIDTH-1:0] stage1_A1;
    logic [DBL_WIDTH-1:0] stage2_X1, stage2_X2, stage2_X3;
    logic [DBL_WIDTH-1:0] stage3_T1, stage3_T2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A1   <= '0;
            stage2_X1   <= '0; stage2_X2 <= '0; stage2_X3 <= '0;
            stage3_T1   <= '0; stage3_T2 <= '0;
            valid_pipe  <= 3'b000;
        end else begin
            stage1_A1   <= A1;
            stage2_X1   <= X1; stage2_X2 <= X2; stage2_X3 <= X3;
            stage3_T1   <= T1; stage3_T2 <= T2;
            valid_pipe  <= {valid_pipe[1:0], 1'b1};
        end
    end

    assign valid_out = valid_pipe[2];

endmodule
