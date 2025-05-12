`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 16:01:57
// Design Name: 
// Module Name: CMU_PHi43
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
// Module Name: CMU_PHi43
// Description: PHi43 通道的 CMU 计算，二级流水计算  
//              a = (Θ10,7 + Q10,7) + (Δt·Θ10,10)
// Dependencies: fp_multiplier, fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi43 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_10_7,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_10_7,
    // —— 时间参数 —— 
    input  logic [DBL_WIDTH-1:0]   delta_t,    // Δt
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);


    // 中间信号
    logic [DBL_WIDTH-1:0] X1, T1;
    // 流水段寄存器
    logic [DBL_WIDTH-1:0] stage1_X1, stage1_T1;
    logic [DBL_WIDTH-1:0] stage2_a;
    logic [1:0]           valid_pipe;

    // ----------------- 子模块实例化 -----------------
    // X1 = Δt * Θ10,10
    fp_multiplier U_mul_X1 (
        .clk    (clk),
        .a      (delta_t),
        .b      (Theta_10_10),
        .result (X1)
    );
    // T1 = Θ10,7 + Q10,7
    fp_adder U_add_T1 (
        .clk    (clk),
        .a      (Theta_10_7),
        .b      (Q_10_7),
        .result (T1)
    );
    // final a = T1 + X1
    fp_adder U_add_final (
        .clk    (clk),
        .a      (stage1_T1),
        .b      (stage1_X1),
        .result (stage2_a)
    );

    // ----------------- 流水线寄存与控制 -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_X1   <= '0;
            stage1_T1   <= '0;
            stage2_a    <= '0;
            valid_pipe  <= 2'b00;
        end else begin
            // Stage1 寄存 X1, T1
            stage1_X1   <= X1;
            stage1_T1   <= T1;
            // Stage2 寄存 输出 a
            stage2_a    <= stage2_a; 
            // valid 管线移位注入
            valid_pipe  <= { valid_pipe[0], 1'b1 };
        end
    end

    assign a         = stage2_a;
    assign valid_out = valid_pipe[1];

endmodule
