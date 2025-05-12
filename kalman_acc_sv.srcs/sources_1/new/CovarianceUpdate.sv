//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 19:46:55
// Design Name: 
// Module Name: CovarianceUpdate
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

module CovarianceUpdate #(
    parameter STATE_DIM = 12,
    parameter DWIDTH = 64
)(
    input  logic                     clk,
    input  logic                     rst_n,
    // MIBus输入接口（对应图示紫色模块接口）
    input  logic [DWIDTH-1:0]       K_k [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       R_k [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       P_kk1 [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic                     valid_in,
    // OMBus输出接口（对应图示橙色输出路径）
    output logic [DWIDTH-1:0]       P_kk [STATE_DIM-1:0][STATE_DIM-1:0],
    output logic                     valid_out
);

// ================== 脉动阵列核心单元 ==================
// 矩阵乘法单元配置（对应图示蓝色运算模块）
logic [DWIDTH-1:0] Kkmatrix [STATE_DIM-1:0][6-1:0]; // Kk结果
logic [DWIDTH-1:0] KkTmatrix [6-1:0][STATE_DIM-1:0]; // Kk转置结果
// ================= 矩阵转置桥实例 =================
MatrixTransBridge #(
    .ROWS(12),        // 行数（网页6方案扩展）
    .COLS(6),        // 列数
    .DATA_WIDTH(DWIDTH) // 数据位宽（网页3双精度要求）
) u_MatrixBridge (
    .clk(clk),             // 连接系统时钟
    .rst_n(rst_n),         // 连接复位信号
    // 输入矩阵（来自传感器预处理）
    .mat_in(K_k),  // 网页5所示的传感器数据阵列
    
    // 输出矩阵
    .mat_org(Kkmatrix),  // 原始矩阵（用于网页7的QR分解）
    .mat_trans(KkTmatrix), // 转置矩阵（用于网页8的Systolic阵列）
    
    // 状态信号
    .valid_out(process_done) // 网页9时序图标注的完成信号
);

logic [DWIDTH-1:0] KkH  [STATE_DIM-1:0][STATE_DIM-1:0]; 
logic [DWIDTH-1:0] IKkH [STATE_DIM-1:0][STATE_DIM-1:0];

generate
    // Kk转置计算单元（对应图示路径②）
    for (genvar i = 0; i < STATE_DIM; i++) begin : gen_KkT
        for (genvar j = 6; j < STATE_DIM; j++) begin : gen_KkT_col
            assign KkH[i][j] = 64'h0; // 转置操作
        end
    end

    for (genvar i = 0; i < STATE_DIM; i++) begin : gen_KkT_row
        for (genvar j = 0; j < 6; j++) begin : gen_KkT_col
            assign KkH[i][j] = Kkmatrix[i][j]; // 转置操作
        end
    end

    
endgenerate

generate
    for (genvar i = 0; i < STATE_DIM; i++) begin : gen_IKkH
        for (genvar j = 0; j < STATE_DIM; j++) begin : gen_IKkH_col
            begin
                if (i == j) begin
                    fp_suber u_fp_suber(
                        .clk(clk),
                        .a(64'h3FF0000000000000), // 单位矩阵对角线元素
                        .b(KkH[i][j]), // KkH[i][j]元素
                        .result(IKkH[i][j]) // 计算结果
                    );
                end else begin
                        fp_suber u_fp_suber(
                            .clk(clk),
                            .a(64'h000000000000000), // 非对角线元素
                            .b(KkH[i][j]), // KkH[i][j]元素
                            .result(IKkH[i][j]) // 计算结果
                        );
                end
            end
        end
    end
endgenerate

generate
    // K*R计算单元（对应图示路径①）
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_systolic (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(K_k),         // K矩阵行输入
        .b_col(R_k),         // R矩阵列输入
        .load_en(valid_in),
        .enb_1(1'b0),       // 全阵列激活
        .enb_2_6(1'b0),
        .enb_7_12(1'b1),
        .c_out(KR_result)   // 输出到FIFO
    );

    // (K*R)*K^T计算单元（对应图示路径②）
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_systolic_1 (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(KR_result),  // K*R结果输入
        .b_col(KkTmatrix), // K转置输入
        .load_en(kr_done),
        .enb_1(1'b0),
        .enb_2_6(1'b0),
        .enb_7_12(1'b1),
        .c_out(KRKt)
    );

    logic [DWIDTH-1:0] IKHmatrix [STATE_DIM-1:0][STATE_DIM-1:0];
    logic [DWIDTH-1:0] IKHT [STATE_DIM-1:0][STATE_DIM-1:0];
    logic [DWIDTH-1:0] IKHP [STATE_DIM-1:0][STATE_DIM-1:0];

    MatrixTransBridge #(
        .ROWS(12),        // 行数（网页6方案扩展）
        .COLS(12),        // 列数
        .DATA_WIDTH(DWIDTH) // 数据位宽（网页3双精度要求）
    ) u_MatrixBridge_2 (
        .clk(clk),             // 连接系统时钟
        .rst_n(rst_n),         // 连接复位信号
        // 输入矩阵（来自传感器预处理）
        .mat_in(IKH),  // 网页5所示的传感器数据阵列
        
        // 输出矩阵
        .mat_org(IKHmatrix),  // 原始矩阵（用于网页7的QR分解）
        .mat_trans(IHKT), // 转置矩阵（用于网页8的Systolic阵列）
        
        // 状态信号
        .valid_out(process_done) // 网页9时序图标注的完成信号
    );
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_systolic_2 (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(IKHmatrix), // 硬件生成单位矩阵
        .b_col(P_kk1),
        .load_en(ikh_done),
        .enb_1(1'b0),
        .enb_2_6_('b1),      // 激活中间区域
        .enb_7_12(1'b0),
        .c_out(IKH_P)
    );

    // 
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_systolic_3 (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(IKHP), // 硬件生成单位矩阵
        .b_col(IKHT),
        .load_en(ikh_done),
        .enb_1(1'b0),
        .enb_2_6(1'b1),      // 激活中间区域
        .enb_7_12(1'b0),
        .c_out(P_kk)
    );
endgenerate


// 该模块需要优化，只能用一个sys


endmodule