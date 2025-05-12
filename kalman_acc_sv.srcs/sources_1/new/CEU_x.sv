`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/05/08
// Module Name: CEU_x
// Description: "x" 通道的 CEU 计算：两级流水 def = T4 + T3
//              其他通道 y/z 可复用本模块，替换对应输入信号即可
// Dependencies: fp_adder, fp_multiplier
//////////////////////////////////////////////////////////////////////////////////

module CEU_x #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,


    input  logic [DBL_WIDTH-1:0]   Theta_1_7,  
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,   

    input  logic [DBL_WIDTH-1:0]   Theta_7_4,   
    input  logic [DBL_WIDTH-1:0]   Theta_10_4,  
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,  
    
    input  logic [DBL_WIDTH-1:0]   Theta_10_1,  

    input  logic [DBL_WIDTH-1:0]   Theta_10_7,  
    input  logic [DBL_WIDTH-1:0]   Theta_1_4,   

    // Q/R 噪声项
    input  logic [DBL_WIDTH-1:0]   Q_1_4,      
    input  logic [DBL_WIDTH-1:0]   R_1_4,       

    // 固定时间参数（示例，按图中绿色盒子配置）
    input  logic [DBL_WIDTH-1:0]   delta_t,     // Δt
    input  logic [DBL_WIDTH-1:0]   delta_t2,    // 2Δt
    input  logic [DBL_WIDTH-1:0]   delta_t_sq,  // ?Δt?
    input  logic [DBL_WIDTH-1:0]   delta_t_cu,  // 1/6Δt?
    input  logic [DBL_WIDTH-1:0]   delta_t_qu,  // 5/12Δt?
    input  logic [DBL_WIDTH-1:0]   delta_t_qi,  // 1/12Δt?

    // 输出
    output logic [DBL_WIDTH-1:0]   x,
    output logic                   valid_out
);



    // ---------------- 流水线寄存器 ----------------
    logic [DBL_WIDTH-1:0] stage1_A1, stage1_M1;
    logic [DBL_WIDTH-1:0] stage2_A2, stage2_M2, stage2_M3;
    logic [DBL_WIDTH-1:0] stage3_X1, stage3_X2, stage3_X3;
    logic [DBL_WIDTH-1:0] stage4_T1, stage4_T2;
    logic [1:0]            pipe_valid;

    // 噪声项组合
    wire [DBL_WIDTH-1:0] sum_QR1, sum_QR2, sum_QR3;
    wire [DBL_WIDTH-1:0] sum_QR = fp_add(sum_QR1, sum_QR2 /* + sum_QR3 if needed */);

    // ================= 顶层子模块实例化 =================
    // Stage1: A1 = Θ[1,7] + Θ[2,8]；  M1 = 3 * Θ[3,9]
    fp_adder      U1_add_A1 (.clk(clk), .a(Theta_1_7), .b(Theta_2_8), .result(stage1_A1));
    fp_multiplier U1_mul_M1 (.clk(clk), .a(64'h4008000000000000), // 3.0
                                      .b(Theta_3_9), .result(stage1_M1));

    // Stage2: A2 = Θ[4,4] + stage1_M1； M2 = 4 * Θ[5,5]； M3 = 5 * Θ[6,6]
    fp_adder      U2_add_A2 (.clk(clk), .a(Theta_4_4), .b(stage1_M1), .result(stage2_A2));
    fp_multiplier U2_mul_M2 (.clk(clk), .a(64'h4010000000000000), // 4.0
                                      .b(Theta_5_5), .result(stage2_M2));
    fp_multiplier U2_mul_M3 (.clk(clk), .a(64'h4014000000000000), // 5.0
                                      .b(Theta_6_6), .result(stage2_M3));

    // Stage3: X1 = delta_t2 * stage1_A1； X2 = delta_t_sq * stage2_A2； X3 = delta_t_cu * stage2_M2
    fp_multiplier U3_mul_X1 (.clk(clk), .a(delta_t2),   .b(stage1_A1), .result(stage3_X1));
    fp_multiplier U3_mul_X2 (.clk(clk), .a(delta_t_sq),  .b(stage2_A2), .result(stage3_X2));
    fp_multiplier U3_mul_X3 (.clk(clk), .a(delta_t_cu),  .b(stage2_M2), .result(stage3_X3));

    // Stage4: T1 = X1 + X2；  T2 = X3 + (Q+R)
    fp_adder      U4_add_T1 (.clk(clk), .a(stage3_X1), .b(stage3_X2), .result(stage4_T1));

    // Q+R 三路求和
    fp_adder      U4_add_QR1(.clk(clk), .a(Q_1_7), .b(R_1_7), .result(sum_QR1));
    fp_adder      U4_add_QR2(.clk(clk), .a(Q_2_8), .b(R_2_8), .result(sum_QR2));
    // 如果第三路也需要，再加一个 .a(Q_3_9),.b(R_3_9)...

    fp_adder      U4_add_T2 (.clk(clk), .a(stage3_X3), .b(sum_QR), .result(stage4_T2));

    // ================= 流水线寄存与控制 =================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A1 <= '0;   stage1_M1 <= '0;
            stage2_A2 <= '0;   stage2_M2 <= '0;   stage2_M3 <= '0;
            stage3_X1 <= '0;   stage3_X2 <= '0;   stage3_X3 <= '0;
            stage4_T1 <= '0;   stage4_T2 <= '0;
            pipe_valid<= 2'b00;
        end else begin
            // 同步寄存
            stage1_A1 <= stage1_A1;   stage1_M1 <= stage1_M1;
            stage2_A2 <= stage2_A2;   stage2_M2 <= stage2_M2;   stage2_M3 <= stage2_M3;
            stage3_X1 <= stage3_X1;   stage3_X2 <= stage3_X2;   stage3_X3 <= stage3_X3;
            stage4_T1 <= stage4_T1;   stage4_T2 <= stage4_T2;
            // valid 管线
            pipe_valid <= {pipe_valid[0], 1'b1};
        end
    end

    // 最终输出
    assign x         = fp_add(stage4_T1, stage4_T2);
    assign valid_out = pipe_valid[1];

endmodule
