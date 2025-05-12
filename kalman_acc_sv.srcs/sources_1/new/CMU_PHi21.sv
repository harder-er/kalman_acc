`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 15:34:40
// Design Name: 
// Module Name: CMU_PHi21
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
// Module Name: CMU_PHi21
// Description: PHi21 通道的 CMU 计算，五级流水计算  
//              a = T4 + T1
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi21 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_4_1,
    input  logic [DBL_WIDTH-1:0]   Theta_7_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,
    input  logic [DBL_WIDTH-1:0]   Theta_1_10,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_10,
    input  logic [DBL_WIDTH-1:0]   Theta_7_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_4_1,
    // —— 时间参数 —— 
    input  logic [DBL_WIDTH-1:0]   delta_t,       // Δt
    input  logic [DBL_WIDTH-1:0]   dt2_half,      // ½·Δt²
    input  logic [DBL_WIDTH-1:0]   dt3_sixth,     // ⅙·Δt³
    input  logic [DBL_WIDTH-1:0]   dt4_twelth,    // ⅟₁₂·Δt⁴
    input  logic [DBL_WIDTH-1:0]   dt5_twelth,    // ⅟₁₂·Δt⁵
    input  logic [DBL_WIDTH-1:0]   dt6_thirtysix, // ⅟₃₆·Δt⁶ (unused)
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);


    // 中间信号
    logic [DBL_WIDTH-1:0] M1, M2, M3, M4, M5;
    logic [DBL_WIDTH-1:0] A1, A2, A3, A4, A5;
    logic [DBL_WIDTH-1:0] X1, X2, X3, X4, X5;
    logic [DBL_WIDTH-1:0] T1, T2, T3, T4;
    logic [4:0]           valid_pipe;

    // ----------------- 常量乘法 -----------------
    // M1 = 3 * Θ4,7
    fp_multiplier mult_M1(
        .clk    (clk),
        .a      (64'h4008_0000_0000_0000), // 3.0
        .b      (Theta_4_7),
        .result (M1)
    );
    // M2 = 3 * Θ7,7
    fp_multiplier mult_M2(
        .clk    (clk),
        .a      (64'h4008_0000_0000_0000), // 3.0
        .b      (Theta_7_7),
        .result (M2)
    );
    // M3 = 4 * Θ4,10
    fp_multiplier mult_M3(
        .clk    (clk),
        .a      (64'h4010_0000_0000_0000), // 4.0
        .b      (Theta_4_10),
        .result (M3)
    );
    // M4 = 3 * Θ7,10
    fp_multiplier mult_M4(
        .clk    (clk),
        .a      (64'h4008_0000_0000_0000), // 3.0
        .b      (Theta_7_10),
        .result (M4)
    );
    // M5 = 2 * Θ4,7
    fp_multiplier mult_M5(
        .clk    (clk),
        .a      (64'h4000_0000_0000_0000), // 2.0
        .b      (Theta_4_7),
        .result (M5)
    );

    // ----------------- 加法 -----------------
    // A1 = Θ4,1 + Q4,1
    fp_adder add_A1(
        .clk    (clk),
        .a      (Theta_4_1),
        .b      (Q_4_1),
        .result (A1)
    );
    // A2 = Θ7,1 + Θ4,4
    fp_adder add_A2(
        .clk    (clk),
        .a      (Theta_7_1),
        .b      (Theta_4_4),
        .result (A2)
    );
    // A3 = Θ1,10 + M1
    fp_adder add_A3(
        .clk    (clk),
        .a      (Theta_1_10),
        .b      (M1),
        .result (A3)
    );
    // A4 = M2 + M3
    fp_adder add_A4(
        .clk    (clk),
        .a      (M2),
        .b      (M3),
        .result (A4)
    );
    // A5 = M4 + M5
    fp_adder add_A5(
        .clk    (clk),
        .a      (M4),
        .b      (M5),
        .result (A5)
    );

    // ----------------- 时间乘法 -----------------
    // X1 = Δt * A2
    fp_multiplier mult_X1(
        .clk    (clk),
        .a      (delta_t),
        .b      (A2),
        .result (X1)
    );
    // X2 = ½Δt² * A3
    fp_multiplier mult_X2(
        .clk    (clk),
        .a      (dt2_half),
        .b      (A3),
        .result (X2)
    );
    // X3 = ⅙Δt³ * A4
    fp_multiplier mult_X3(
        .clk    (clk),
        .a      (dt3_sixth),
        .b      (A4),
        .result (X3)
    );
    // X4 = ⅟₁₂Δt⁴ * A5
    fp_multiplier mult_X4(
        .clk    (clk),
        .a      (dt4_twelth),
        .b      (A5),
        .result (X4)
    );
    // X5 = ⅟₁₂Δt⁵ * Θ1,10
    fp_multiplier mult_X5(
        .clk    (clk),
        .a      (dt5_twelth),
        .b      (Theta_1_10),
        .result (X5)
    );

    // ----------------- 累加 -----------------
    // T1 = A1 + X1
    fp_adder add_T1(
        .clk    (clk),
        .a      (A1),
        .b      (X1),
        .result (T1)
    );
    // T2 = X2 + X3
    fp_adder add_T2(
        .clk    (clk),
        .a      (X2),
        .b      (X3),
        .result (T2)
    );
    // T3 = X4 + X5
    fp_adder add_T3(
        .clk    (clk),
        .a      (X4),
        .b      (X5),
        .result (T3)
    );
    // T4 = T2 + T3
    fp_adder add_T4(
        .clk    (clk),
        .a      (T2),
        .b      (T3),
        .result (T4)
    );
    // final a = T4 + T1
    fp_adder add_final(
        .clk    (clk),
        .a      (T4),
        .b      (T1),
        .result (a)
    );

    // ----------------- 流水线寄存与控制 -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= 5'b0;
        end else begin
            valid_pipe <= {valid_pipe[3:0], 1'b1};
        end
    end

    assign valid_out = valid_pipe[4];

endmodule

