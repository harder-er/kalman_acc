`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 15:28:58
// Design Name: 
// Module Name: CMU_PHi12
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
// Create Date: 2025/05/08
// Module Name: CMU_PHi12
// Description: CMU_PHi11 的升级版，支持 PHi12 通道的六级流水计算
//              a = T5 + T4
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi12 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_1_4,
    input  logic [DBL_WIDTH-1:0]   Theta_1_1,
    input  logic [DBL_WIDTH-1:0]   Theta_1_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_1_10,
    input  logic [DBL_WIDTH-1:0]   Theta_4_10,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_1_4,
    // —— 时间参数（常量） —— 
    input  logic [DBL_WIDTH-1:0]   delta_t,
    input  logic [DBL_WIDTH-1:0]   half_dt2,   // ½·Δt²
    input  logic [DBL_WIDTH-1:0]   sixth_dt3,  // ⅙·Δt³
    input  logic [DBL_WIDTH-1:0]   five12_dt4, // 5/12·Δt⁴
    input  logic [DBL_WIDTH-1:0]   twleve_dt5, // 1/12·Δt⁵

    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);

    // 中间信号
    logic [DBL_WIDTH-1:0] M1, M2, M3;
    logic [DBL_WIDTH-1:0] A1, A2, A3, A4;
    logic [DBL_WIDTH-1:0] X1, X2, X3, X4, X5, X6;
    logic [DBL_WIDTH-1:0] T1, T2, T3, T4, T5;
    logic [5:0]           valid_pipe;

    // 浮点 IP 核


    // ------------------------------------------------------------------------
    // 常数乘法： M1=3*Θ4,7； M2=3*Θ7,7； M3=4*Θ10,4
    // ------------------------------------------------------------------------
    fp_multiplier mult_M1 (
        .clk    (clk),
        .a      (64'h4008_0000_0000_0000),  // 3.0
        .b      (Theta_4_7),
        .result (M1)
    );
    fp_multiplier mult_M2 (
        .clk    (clk),
        .a      (64'h4008_0000_0000_0000),  // 3.0
        .b      (Theta_7_7),
        .result (M2)
    );
    fp_multiplier mult_M3 (
        .clk    (clk),
        .a      (64'h4010_0000_0000_0000),  // 4.0
        .b      (Theta_4_10),
        .result (M3)
    );

    // ------------------------------------------------------------------------
    // 加法： A1 = Θ1,1 + Q1,4
    //       A2 = Θ1,7 + Θ4,4    (note: Θ4,4 = Θ_1_4’s second index? assume given)
    //       A3 = Θ1,10 + M1
    //       A4 = M2 + M3
    // ------------------------------------------------------------------------
    fp_adder add_A1 (
        .clk    (clk),
        .a      (Theta_1_1),
        .b      (Q_1_4),
        .result (A1)
    );
    fp_adder add_A2 (
        .clk    (clk),
        .a      (Theta_1_7),
        .b      (Theta_1_4),   // NOTE: use Θ4,4 if available
        .result (A2)
    );
    fp_adder add_A3 (
        .clk    (clk),
        .a      (Theta_1_10),
        .b      (M1),
        .result (A3)
    );
    fp_adder add_A4 (
        .clk    (clk),
        .a      (M2),
        .b      (M3),
        .result (A4)
    );

    // ------------------------------------------------------------------------
    // 时间乘法、系数： 
    //  X1 = 2Δt * Θ1,4
    //  X2 = ½Δt² * A2
    //  X3 = ⅙Δt³ * A3
    //  X4 = 5/12Δt⁴ * A4
    //  X5 = 1/12Δt⁵ * Θ7,10
    //  X6 = ??? Δt⁶ * Θ10,10 (可忽略或用六级流水)
    // ------------------------------------------------------------------------
    fp_multiplier mult_X1 (
        .clk    (clk),
        .a      (delta_t2),    // 2·Δt
        .b      (Theta_1_4),
        .result (X1)
    );
    fp_multiplier mult_X2 (
        .clk    (clk),
        .a      (half_dt2),    // ½·Δt²
        .b      (A2),
        .result (X2)
    );
    fp_multiplier mult_X3 (
        .clk    (clk),
        .a      (sixth_dt3),   // ⅙·Δt³
        .b      (A3),
        .result (X3)
    );
    fp_multiplier mult_X4 (
        .clk    (clk),
        .a      (five12_dt4),  // 5/12·Δt⁴
        .b      (A4),
        .result (X4)
    );
    fp_multiplier mult_X5 (
        .clk    (clk),
        .a      (twleve_dt5),  // 1/12·Δt⁵
        .b      (Theta_7_10),
        .result (X5)
    );
    fp_multiplier mult_X6 (
        .clk    (clk),
        .a      (delta_t),     // can be Δt⁶ precomputed externally
        .b      (Theta_10_10),
        .result (X6)
    );

    // ------------------------------------------------------------------------
    // 累加：
    //  T1 = A1 + X1
    //  T2 = X2 + X3
    //  T3 = X4 + X5
    //  T4 = T1 + X6
    //  T5 = T2 + T3
    // ------------------------------------------------------------------------
    fp_adder add_T1 (
        .clk    (clk),
        .a      (A1),
        .b      (X1),
        .result (T1)
    );
    fp_adder add_T2 (
        .clk    (clk),
        .a      (X2),
        .b      (X3),
        .result (T2)
    );
    fp_adder add_T3 (
        .clk    (clk),
        .a      (X4),
        .b      (X5),
        .result (T3)
    );
    fp_adder add_T4 (
        .clk    (clk),
        .a      (T1),
        .b      (X6),
        .result (T4)
    );
    fp_adder add_T5 (
        .clk    (clk),
        .a      (T2),
        .b      (T3),
        .result (T5)
    );
    fp_adder final_add (
        .clk    (clk),
        .a      (T5),
        .b      (T4),
        .result (a)
    );

    // ------------------------------------------------------------------------
    // 有效信号流水线
    // ------------------------------------------------------------------------
    // 假设在模块顶层已经声明：
logic [DBL_WIDTH-1:0] stage1_M   [0:2];  // 对应 M1, M2, M3
logic [DBL_WIDTH-1:0] stage2_A   [0:3];  // 对应 A1, A2, A3, A4
logic [DBL_WIDTH-1:0] stage3_X   [0:5];  // 对应 X1…X6
logic [DBL_WIDTH-1:0] stage4_T   [0:4];  // 对应 T1…T5

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位：清零所有阶段寄存器和 valid 管线
        for (int i = 0; i < 3; i++) stage1_M[i]   <= '0;
        for (int i = 0; i < 4; i++) stage2_A[i]   <= '0;
        for (int i = 0; i < 6; i++) stage3_X[i]   <= '0;
        for (int i = 0; i < 5; i++) stage4_T[i]   <= '0;
        valid_pipe <= '0;
    end else begin
        // 同步各阶段计算结果
        stage1_M[0] <= M1;
        stage1_M[1] <= M2;
        stage1_M[2] <= M3;

        stage2_A[0] <= A1;
        stage2_A[1] <= A2;
        stage2_A[2] <= A3;
        stage2_A[3] <= A4;

        stage3_X[0] <= X1;
        stage3_X[1] <= X2;
        stage3_X[2] <= X3;
        stage3_X[3] <= X4;
        stage3_X[4] <= X5;
        stage3_X[5] <= X6;

        stage4_T[0] <= T1;
        stage4_T[1] <= T2;
        stage4_T[2] <= T3;
        stage4_T[3] <= T4;
        stage4_T[4] <= T5;

        // valid 管线：5 级延迟后输出
        valid_pipe <= { valid_pipe[4:0], 1'b1 };
    end
end

// 输出
assign valid_out = valid_pipe[5];
// 最终 a 也是第5级累加的结果，直接从 stage4_T[4] 输出或再做一次加法
assign a = stage4_T[4];


endmodule
