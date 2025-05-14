//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 19:32:51
// Design Name: 
// Module Name: KalmanGainCalculator
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


`timescale 1ns/1ps

module KalmanGainCalculator #(
    parameter DWIDTH = 64
)(
    input  logic                  clk                       ,
    input  logic                  rst_n                     ,
    
    input  logic                  SP_Done                   ,   // 状态预测完成信号
    output logic                  CKG_Done                  ,   // 测量更新完成信号
    // 
    input  logic [DWIDTH-1:0]     P_k1k1 [0:12-1][0:12-1]   ,   //p_k-1,k-1
    input  logic [DWIDTH-1:0]     Q_k [0:12-1][0:12-1]      ,  
    // 
    input  logic [DWIDTH-1:0]     R_k [0:5][0:5]            ,  // 测量噪声矩阵
    
    // 输出接口（OMBus）
    output logic [DWIDTH-1:0]     K_k [0:12-1][0:12-1]  // 卡尔曼增益
);

// █████ CMU模块（矩阵计算单元）
//-----------------------------------------------------------------
logic [DWIDTH-1:0] P_predicted [0:12-1][0:12-1];
logic [DWIDTH-1:0] P_predicted_HT [0:12-1][0:12-1];
logic              cmu_complete;

generate
    // Φ1,1块专用CMU
    genvar i;
    for (i = 0;i < 3;i ++) begin
        CMU_PHi11 #(
            .DBL_WIDTH(64)  // 双精度浮点位宽
        ) u_CMU_PHi11 (
            .clk          (clk),          // 系统时钟
            .rst_n        (rst_n),        // 低有效复位
            
            // 协方差矩阵参数输入（对应P矩阵位置）
            .Theta_1_1    (P_k1k1[0+i][0+i]), // Φ₁,₁主对角项
            .Theta_4_1    (P_k1k1[3+i][0+i]), // 速度-位置交叉项
            .Theta_7_1    (P_k1k1[6+i][0+i]), // 角速度-位置交叉项
            .Theta_4_4    (P_k1k1[3+i][3+i]), // 速度协方差
            .Theta_10_1   (P_k1k1[9+i][0+i]),// 加速度-位置交叉项
            .Theta_4_7    (P_k1k1[3+i][6+i]), // 速度-角速度交叉项
            .Theta_7_7    (P_k1k1[6+i][6+i]), // 角速度协方差
            .Theta_4_10   (P_k1k1[3+i][9+i]),// 速度-加速度交叉项
            .Theta_7_10   (P_k1k1[6+i][9+i]),// 角速度-加速度交叉项
            .Theta_10_10  (P_k1k1[9+i][9+i]), // 加速度协方差
            
            // 过程噪声参数
            .Q_1_1        (Q_k[0+i][0+i]), // 位置过程噪声协方差
            
            // 时间参数（需预计算）
            .delta_t       (delta_t),      // 原始时间间隔
            
            // 输出
            .a            (P_predicted[0+i][0+i]), // Φ₁,₁输出到矩阵
            .valid_out    (phi11_valid)    // 有效信号
        ); 
    end
    
    for (i = 0;i < 3;i ++) begin
        CMU_PHi12 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi12_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),
            // —— 动态输入：索引全都减一 —— 
            .Theta_1_4   (P_k1k1[0+i][3+i]),    // was [1][4]
            .Theta_1_1   (P_k1k1[0+i][0+i]),    // was [1][1]
            .Theta_1_7   (P_k1k1[0+i][6+i]),    // was [1][7]
            .Theta_4_7   (P_k1k1[3+i][6+i]),    // was [4][7]
            .Theta_1_10  (P_k1k1[0+i][9+i]),    // was [1][10]
            .Theta_4_10  (P_k1k1[3+i][9+i]),    // was [4][10]
            .Theta_7_7   (P_k1k1[6+i][6+i]),    // was [7][7]
            .Theta_7_10  (P_k1k1[6+i][9+i]),    // was [7][10]
            .Theta_10_10 (P_k1k1[9+i][9+i]),    // was [10][10]
            .Q_1_4       (Q_k   [0+i][3+i]),     // was [1][4]

            // —— 时间参数（常量） —— 
            .delta_t     (delta_t),        
            .half_dt2    (half_dt2),       
            .sixth_dt3   (sixth_dt3),      
            .five12_dt4  (five12_dt4),     
            .twleve_dt5  (twleve_dt5),     

            // —— 输出 —— 
            .a           (P_predicted[0+i][1+i]),
            .valid_out   (phi12_valid_minus1)
        );
    end
   
    // 在上层模块中，使用 generate 块并行例化 CMU_PHi13 三条流水线（i = 0,1,2）
// 假设 P_k1k1 和 Q_k 是预先定义好的矩阵，P_predicted 用于保存输出


    for (i = 0; i < 3; i++) begin : GEN_PHI13
        CMU_PHi13 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi13 (
            .clk        (clk),
            .rst_n      (rst_n),
            // —— 动态输入：按照索引减一逻辑映射到 P_k1k1 —— 
            .Theta_1_7   (P_k1k1[0+i][6+i]),   // Θ[1,7] → P_k1k1[1+i-1][7+i-1]
            .Theta_4_7   (P_k1k1[3+i][6+i]),   // Θ[4,7] → P_k1k1[4+i-1][7+i-1]
            .Theta_1_10  (P_k1k1[0+i][9+i]),   // Θ[1,10]
            .Theta_7_7   (P_k1k1[6+i][6+i]),   // Θ[7,7]
            .Theta_4_10  (P_k1k1[3+i][9+i]),   // Θ[4,10]
            .Theta_7_10  (P_k1k1[6+i][9+i]),   // Θ[7,10]
            .Theta_10_10 (P_k1k1[9+i][9+i]),   // Θ[10,10]
            .Q_1_7       (Q_k   [0+i][6+i]),    // Q[1,7]

            // —— 时间参数（常量） —— 
            .delta_t     (delta_t),       
            .half_dt2    (half_dt2),      
            .two3_dt3    (two3_dt3),      
            .sixth_dt4   (sixth_dt4),     

            // —— 输出 —— 
            .a           (P_predicted[0+i][2+i]),   // 输出 a 存入 P_predicted[1+i][3+i]
            .valid_out   (phi13_valid_minus1)
        );
    end

    // 在上层模块中，使用 generate 并行例化 CMU_PHi14 三条流水线（i = 0,1,2），并将所有下标减一

    for (i = 0; i < 3; i++) begin : GEN_PHI14_MINUS1
        CMU_PHi14 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi14_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),
            // —— 动态输入：索引全都减一 —— 
            .Theta_1_10   (P_k1k1[0+i][9+i]),   // was [1][10]
            .Theta_4_10   (P_k1k1[3+i][9+i]),   // was [4][10]
            .Theta_7_10   (P_k1k1[6+i][9+i]),   // was [7][10]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_1_10       (Q_k   [0+i][9+i]),    // was [1][10]

            // —— 时间参数（常量） —— 
            .delta_t     (delta_t),
            .half_dt2    (half_dt2),
            .two3_dt3    (two3_dt3),

            // —— 输出 —— 
            .a           (P_predicted[0+i][9+i]),  // 存入 [1,10] 减一后的 [0+i][9+i]
            .valid_out   (phi14_valid_minus1)
        );
    end

    // 在上层模块中，使用 generate 并行例化 CMU_PHi21 三条流水线（i = 0,1,2），并将所有下标减一

    for (i = 0; i < 3; i++) begin : GEN_PHI21_MINUS1
        CMU_PHi21 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi21_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),
            // —— 动态输入：索引全都减一 —— 
            .Theta_4_1   (P_k1k1[3+i][0+i]),   // was [4][1]
            .Theta_7_1   (P_k1k1[6+i][0+i]),   // was [7][1]
            .Theta_4_4   (P_k1k1[3+i][3+i]),   // was [4][4]
            .Theta_1_10  (P_k1k1[0+i][9+i]),   // was [1][10]
            .Theta_4_7   (P_k1k1[3+i][6+i]),   // was [4][7]
            .Theta_7_7   (P_k1k1[6+i][6+i]),   // was [7][7]
            .Theta_4_10  (P_k1k1[3+i][9+i]),   // was [4][10]
            .Theta_7_10  (P_k1k1[6+i][9+i]),   // was [7][10]
            .Theta_10_10 (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_4_1       (Q_k   [3+i][0+i]),    // was [4][1]

            // —— 时间参数（常量） —— 
            .delta_t     (delta_t),
            .dt2_half    (dt2_half),
            .dt3_sixth   (dt3_sixth),
            .dt4_twelth  (dt4_twelth),
            .dt5_twelth  (dt5_twelth),
            .dt6_thirtysix(dt6_thirtysix),

            // —— 输出 —— 
            .a           (P_predicted[3+i][0+i]), 
            .valid_out   (phi21_valid_minus1)
        );
    end

    // 在上层模块中，使用 generate 并行例化 CMU_PHi22 三条流水线（i = 0,1,2），并将所有下标减一

    for (i = 0; i < 3; i++) begin : GEN_PHI22_MINUS1
        CMU_PHi22 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi22_minus1 (
            .clk          (clk),
            .rst_n        (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_4_4    (P_k1k1[3+i][3+i]),   // was [4][4]
            .Theta_4_7    (P_k1k1[3+i][6+i]),   // was [4][7]
            .Theta_4_10   (P_k1k1[3+i][9+i]),   // was [4][10]
            .Theta_7_7    (P_k1k1[6+i][6+i]),   // was [7][7]
            .Theta_7_10   (P_k1k1[6+i][9+i]),   // was [7][10]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_4_4        (Q_k   [3+i][3+i]),    // was [4][4]

            // —— 时间参数（常量） —— 
            .two_dt       (two_dt),
            .dt2          (dt2),
            .half_dt3     (half_dt3),
            .quarter_dt4  (quarter_dt4),

            // —— 输出 —— 
            .a            (P_predicted[3+i][3+i]),  // 将结果写回 [4,4] 减一后位置
            .valid_out    (phi22_valid_minus1)
        );
    end

// 在上层模块中，使用 generate 并行例化 CMU_PHi23 三条流水线（i = 0,1,2），并将所有下标减一

    for (i = 0; i < 3; i++) begin : GEN_PHI23_MINUS1
        CMU_PHi23 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi23_minus1 (
            .clk          (clk),
            .rst_n        (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_4_7    (P_k1k1[3+i][6+i]),   // was [4][7]
            .Theta_7_7    (P_k1k1[6+i][6+i]),   // was [7][7]
            .Theta_4_10   (P_k1k1[3+i][9+i]),   // was [4][10]
            .Theta_10_7   (P_k1k1[9+i][6+i]),   // was [10][7]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_4_7        (Q_k   [3+i][6+i]),    // was [4][7]

            // —— 时间参数（常量） —— 
            .delta_t      (delta_t),
            .half_dt2     (half_dt2),
            .half_dt3     (half_dt3),

            // —— 输出 —— 
            .a            (P_predicted[3+i][6+i]),  // 写回 [4,7] 减一后位置
            .valid_out    (phi23_valid_minus1)
        );
    end

    // 在上层模块中，使用 generate 并行例化 CMU_PHi24 三条流水线（i = 0,1,2），并将所有下标减一

    for (i = 0; i < 3; i++) begin : GEN_PHI24_MINUS1
        CMU_PHi24 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi24_minus1 (
            .clk          (clk),
            .rst_n        (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_4_10   (P_k1k1[3+i][9+i]),   // was Θ[4,10]
            .Theta_7_4    (P_k1k1[6+i][3+i]),   // was Θ[7,4]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was Θ[10,10]
            .Q_4_10       (Q_k   [3+i][9+i]),    // was Q[4,10]

            // —— 时间参数（常量） —— 
            .delta_t      (delta_t),
            .half_dt2     (half_dt2),

            // —— 输出 —— 
            .a            (P_predicted[3+i][9+i]),  // 写回 [4,10] 减一后位置
            .valid_out    (phi24_valid_minus1)
        );
    end

// 在上层模块中，使用 generate 并行例化 CMU_PHi31 三条流水线（i = 0,1,2），并将所有下标减一
    for (i = 0; i < 3; i++) begin : GEN_PHI31_MINUS1
        CMU_PHi31 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi31_minus1 (
            .clk        (clk),
            .rst_n      (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_7_1    (P_k1k1[6+i][0+i]),   // was Θ[7,1]
            .Theta_1_10   (P_k1k1[0+i][9+i]),   // was Θ[1,10]
            .Theta_4_7    (P_k1k1[3+i][6+i]),   // was Θ[4,7]
            .Theta_7_7    (P_k1k1[6+i][6+i]),   // was Θ[7,7]
            .Theta_4_10   (P_k1k1[3+i][9+i]),   // was Θ[4,10]
            .Theta_7_10   (P_k1k1[6+i][9+i]),   // was Θ[7,10]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was Θ[10,10]
            .Q_7_1        (Q_k   [6+i][0+i]),    // was Q[7,1]

            // —— 时间参数 —— 
            .delta_t      (delta_t),
            .half_dt2     (half_dt2),
            .two3_dt3     (two3_dt3),
            .sixth_dt4    (sixth_dt4),

            // —— 输出 —— 
            .a            (P_predicted[6+i][0+i]),  // 写回 [7,1] 减一后位置
            .valid_out    (phi31_valid_minus1)
        );
    end

// 在上层模块中，使用 generate 并行例化 CMU_PHi32 三条流水线（i = 0,1,2），并将所有下标减一

    for (i = 0; i < 3; i++) begin : GEN_PHI32_MINUS1
        CMU_PHi32 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi32_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_7_4   (P_k1k1[6+i][3+i]),   // was Θ[7,4]
            .Theta_4_10  (P_k1k1[3+i][9+i]),   // was Θ[4,10] (unused)
            .Theta_7_7   (P_k1k1[6+i][6+i]),   // was Θ[7,7]
            .Theta_7_10  (P_k1k1[6+i][9+i]),   // was Θ[7,10]
            .Theta_10_10 (P_k1k1[9+i][9+i]),   // was Θ[10,10]
            .Q_7_4       (Q_k   [6+i][3+i]),    // was Q[7,4]

            // —— 时间参数 —— 
            .delta_t     (delta_t),
            .three2_dt2  (three2_dt2),
            .half_dt3    (half_dt3),

            // —— 输出 —— 
            .a           (P_predicted[6+i][3+i]),  // 写回 [7,4] 减一后位置
            .valid_out   (phi32_valid_minus1)
        );
    end

// 在上层模块中，使用 generate 并行例化 CMU_PHi33 三条流水线（i = 0,1,2），并将所有下标减一
    for (i = 0; i < 3; i++) begin : GEN_PHI33_MINUS1
        CMU_PHi33 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi33_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_7_7    (P_k1k1[6+i][6+i]),   // was Θ[7,7]
            .Theta_7_10   (P_k1k1[6+i][9+i]),   // was Θ[7,10]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was Θ[10,10]
            .Q_7_7        (Q_k   [6+i][6+i]),    // was Q[7,7]

            // —— 时间参数 —— 
            .two_dt       (two_dt),
            .dt2          (dt2),

            // —— 输出 —— 
            .a            (P_predicted[6+i][6+i]),  // 写回 [7,7] 减一后位置
            .valid_out    (phi33_valid_minus1)
        );
    end


    for (i = 0; i < 3; i++) begin : GEN_PHI34_MINUS1
        CMU_PHi34 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi34_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_7_10   (P_k1k1[6+i][9+i]),   // was Θ[7,10]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was Θ[10,10]
            .Q_7_10       (Q_k   [6+i][9+i]),    // was Q[7,10]

            // —— 时间参数 —— 
            .delta_t      (delta_t),

            // —— 输出 —— 
            .a            (P_predicted[6+i][9+i]),  // 写入 [7,10]，减一后为 [6+i][9+i]
            .valid_out    (phi34_valid_minus1)
        );
    end

    for (i = 0; i < 3; i++) begin : GEN_PHI41_MINUS1
        CMU_PHi41 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi41_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_10_1   (P_k1k1[9+i][0+i]),   // was [10][1]
            .Theta_10_4   (P_k1k1[9+i][3+i]),   // was [10][4]
            .Theta_10_7   (P_k1k1[9+i][6+i]),   // was [10][7]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_10_1       (Q_k   [9+i][0+i]),    // was [10][1]

            // —— 时间参数 —— 
            .delta_t      (delta_t),
            .half_dt2     (half_dt2),
            .sixth_dt3    (sixth_dt3),

            // —— 输出 —— 
            .a            (P_predicted[9+i][0+i]), // 对应 [10][1] 减一后索引
            .valid_out    (phi41_valid_minus1)
        );
    end


    for (i = 0; i < 3; i++) begin : GEN_PHI42_MINUS1
        CMU_PHi42 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi42_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_10_4   (P_k1k1[9+i][3+i]),   // was [10][4]
            .Theta_10_7   (P_k1k1[9+i][6+i]),   // was [10][7]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_10_4       (Q_k   [9+i][3+i]),    // was [10][4]

            // —— 时间参数 —— 
            .delta_t      (delta_t),
            .half_dt2     (half_dt2),

            // —— 输出 —— 
            .a            (P_predicted[9+i][3+i]),  // 对应 [10][4] 减一后索引
            .valid_out    (phi42_valid_minus1)
        );
    end


    for (i = 0; i < 3; i++) begin : GEN_PHI43_MINUS1
        CMU_PHi43 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi43_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_10_7   (P_k1k1[9+i][6+i]),   // was [10][7]
            .Theta_10_10  (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_10_7       (Q_k   [9+i][6+i]),    // was [10][7]

            // —— 时间参数 —— 
            .delta_t      (delta_t),

            // —— 输出 —— 
            .a            (P_predicted[9+i][6+i]),  // 对应 [10][7] 索引减一
            .valid_out    (phi43_valid_minus1)
        );
    end


    for (i = 0; i < 3; i++) begin : GEN_PHI44_MINUS1
        CMU_PHi44 #(
            .DBL_WIDTH(64)
        ) u_CMU_PHi44_minus1 (
            .clk         (clk),
            .rst_n       (rst_n),

            // —— 动态输入：索引全都减一 —— 
            .Theta_10_10 (P_k1k1[9+i][9+i]),   // was [10][10]
            .Q_10_10     (Q_k    [9+i][9+i]),   // was [10][10]

            // —— 输出 —— 
            .a           (P_predicted[9+i][9+i]), // was [10][10]
            .valid_out   (phi44_valid_minus1)
        );
    end
            

endgenerate

// ================== 矩阵构建逻辑 ==================
// // 非对角线清零
// always_comb begin
//     for(int i=0; i<12; i++) begin
//         for(int j=0; j<12; j++) begin
//             if(!((j/3 == i/3) && (j%3 == i%3))) begin
//                 P_predicted[i][j] = 64'h0;
//             end
//         end
//     end
// end


// █████ 数据缓冲FIFO
//-----------------------------------------------------------------
// logic [DWIDTH*3-1:0] fifo_data_in;
// logic [DWIDTH*3-1:0] fifo_data_out;
// logic                fifo_wr_en, fifo_rd_en;
// logic                fifo_full, fifo_empty;

// FIFO_3x64 #(
//     .DEPTH(FIFO_DEPTH),
//     .DWIDTH(DWIDTH*3)
// ) u_fifo (
//     .clk(clk),
//     .rst_n(rst_n),
//     .wr_en(fifo_wr_en),
//     .data_in(fifo_data_in),
//     .rd_en(fifo_rd_en),
//     .data_out(fifo_data_out),
//     .full(fifo_full),
//     .empty(fifo_empty)
// );

// FIFO写入控制（存储P_predicted）
// always_comb begin
//     fifo_wr_en = cmu_complete;
//     for(int i=0; i<3; i++) begin
//         fifo_data_in[i*DWIDTH +: DWIDTH] = P_predicted[i][0];  // 存储第0列
//     end
// end

// █████ CEU模块（元素计算单元）
//-----------------------------------------------------------------
logic [DWIDTH-1:0] inv_matrix [0:5][0:5];
logic              ceu_complete;

MatrixInverseUnit #(
    .DWIDTH(DWIDTH)
) u_MatrixInverseUnit (
    .clk(clk),
    .rst_n(rst_n),
    .P_k1k1(P_k1k1),
    .R_k(R_matrix),
    .Q_k(Q_matrix),
//    .valid_in(ceu_valid_in),
    .inv_matrix(inv_matrix)
//    .ceu_done(ceu_complete)
);



// █████ 脉动阵列接口
//-----------------------------------------------------------------
SystolicArray #(
    .DWIDTH(DWIDTH),
    .ARRAY_SIZE(3)
) u_systolic (
    .clk(clk),
    .rst_n(rst_n),
    .a_row(P_pred),   // 来自FIFO的P_predicted
    .b_col(inv_matrix),      // CEU计算的逆矩阵
    .load_en(ceu_complete), // CEU完成后加载
    .enb_1(ceu_valid_in), // CEU有效信号
    .enb_2_6(cmu_valid_in), // CMU有效信号
    .enb_7_12(ceu_complete), // CEU完成信号
    .c_out(K_k)
);

// // █████ 时序同步控制
// //-----------------------------------------------------------------
// typedef enum {IDLE, CMU_PROCESS, CEU_PROCESS, SYSTOLIC_START} fsm_state;
// fsm_state current_state, next_state;

// always_ff @(posedge clk or negedge rst_n) begin
//     if(!rst_n) current_state <= IDLE;
//     else current_state <= next_state;
// end

// always_comb begin
//     next_state = current_state;
//     case(current_state)
//         IDLE: 
//             if(cmu_valid_in) next_state = CMU_PROCESS;
        
//         CMU_PROCESS:
//             if(cmu_complete) next_state = CEU_PROCESS;
        
//         CEU_PROCESS:
//             if(ceu_complete) next_state = SYSTOLIC_START;
        
//         SYSTOLIC_START:
//             if(data_valid_out) next_state = IDLE;
//     endcase
// end

// assign fifo_rd_en = (current_state == SYSTOLIC_START);

endmodule
