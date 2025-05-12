`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 15:30:53
// Design Name: 
// Module Name: CMU_PHi13
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
// Module Name: CMU_PHi13
// Description: PHi13 通道的 CMU 计算，四级流水计算 a = T3 + X4
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi13 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_1_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_1_10,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_10,
    input  logic [DBL_WIDTH-1:0]   Theta_7_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_1_7,
    // —— 时间参数 —— 
    input  logic [DBL_WIDTH-1:0]   delta_t,       // Δt
    input  logic [DBL_WIDTH-1:0]   half_dt2,      // ½·Δt²
    input  logic [DBL_WIDTH-1:0]   two3_dt3,      // ⅔·Δt³
    input  logic [DBL_WIDTH-1:0]   sixth_dt4,     // ⅙·Δt⁴
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);



    // 中间信号
    logic [DBL_WIDTH-1:0] A1, A2, A3;
    logic [DBL_WIDTH-1:0] X1, X2, X3, X4;
    logic [DBL_WIDTH-1:0] T1, T2, T3;
    logic [3:0]           valid_pipe;

    // ----------------- 子模块实例化 -----------------
    // A1 = Θ1,7 + Q1,7
    fp_adder U_add_A1 (
        .clk    (clk),
        .a      (Theta_1_7),
        .b      (Q_1_7),
        .result (A1)
    );
    // A2 = Θ4,7 + Θ1,10
    fp_adder U_add_A2 (
        .clk    (clk),
        .a      (Theta_4_7),
        .b      (Theta_1_10),
        .result (A2)
    );
    // A3 = Θ7,7 + Θ4,10 + Θ4,10
    // first sum Θ7,7 + Θ4,10
    wire [DBL_WIDTH-1:0] sum7_4;
    fp_adder U_add_tmp (
        .clk    (clk),
        .a      (Theta_7_7),
        .b      (Theta_4_10),
        .result (sum7_4)
    );
    // then sum + Θ4,10
    fp_adder U_add_A3 (
        .clk    (clk),
        .a      (sum7_4),
        .b      (Theta_4_10),
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
    // X3 = ⅔Δt³ * Θ7,10
    fp_multiplier U_mul_X3 (
        .clk    (clk),
        .a      (two3_dt3),
        .b      (Theta_7_10),
        .result (X3)
    );
    // X4 = ⅙Δt⁴ * Θ10,10
    fp_multiplier U_mul_X4 (
        .clk    (clk),
        .a      (sixth_dt4),
        .b      (Theta_10_10),
        .result (X4)
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
    // T3 = T1 + T2
    fp_adder U_add_T3 (
        .clk    (clk),
        .a      (T1),
        .b      (T2),
        .result (T3)
    );
    // final a = T3 + X4
    fp_adder U_add_final (
        .clk    (clk),
        .a      (T3),
        .b      (X4),
        .result (a)
    );

    // ----------------- 流水线寄存与控制 -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A1         <= '0;
            A2         <= '0;
            A3         <= '0;
            X1         <= '0;
            X2         <= '0;
            X3         <= '0;
            X4         <= '0;
            T1         <= '0;
            T2         <= '0;
            T3         <= '0;
            valid_pipe <= 4'b0000;
        end else begin
            // 同步寄存每级输出
            A1         <= A1;
            A2         <= A2;
            A3         <= A3;
            X1         <= X1;
            X2         <= X2;
            X3         <= X3;
            X4         <= X4;
            T1         <= T1;
            T2         <= T2;
            T3         <= T3;
            // valid 管线移位注入
            valid_pipe <= { valid_pipe[2:0], 1'b1 };
        end
    end

    assign valid_out = valid_pipe[3];

endmodule
