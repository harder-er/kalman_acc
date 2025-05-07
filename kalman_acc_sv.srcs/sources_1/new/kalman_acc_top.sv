`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/10 11:35:25
// Design Name: 
// Module Name: KalmanFilterTop  // 卡尔曼滤波器顶层模块
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 实现卡尔曼滤波算法的顶层集成模块，包含状态预测与测量更新两大阶段
// 
// Dependencies: 依赖状态预测、协方差预测、增益计算、状态更新等子模块
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 支持12维状态向量和6维测量向量的实时滤波处理
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module KalmanFilterTop #(
    parameter STATE_DIM  = 12,
    parameter MEASURE_DIM = 6
)(
    input  logic         clk,
    input  logic         rst_n,
    
    // 系统模型参数
    input  logic [31:0]  F [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [31:0]  H [MEASURE_DIM-1:0][STATE_DIM-1:0],
    input  logic [31:0]  Qk[STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [31:0]  Rk[MEASURE_DIM-1:0][MEASURE_DIM-1:0],
    
    // 实时数据接口
    input  logic [31:0]  Zk[MEASURE_DIM-1:0],
    input  logic [31:0]  Xk_prev[STATE_DIM-1:0],
    input  logic [31:0]  Pk_prev[STATE_DIM-1:0][STATE_DIM-1:0],
    
    // 滤波结果输出
    output logic [31:0]  Xk_k[STATE_DIM-1:0],
    output logic [31:0]  Pk_k[STATE_DIM-1:0][STATE_DIM-1:0],
    
    // 状态机控制接口
    input  logic         Init_Valid,
    output logic         SP_Done,
    output logic         CKG_Done,
    output logic         SCU_Done,
    input  logic         MDI_Valid,
    input  logic         SCO_Valid
);

// ================== 控制单元实例化 ==================
KF_ControlUnit u_ControlUnit (
    .clk(clk),
    .rst(rst_n),
    // 状态转换输入
    .Init_Valid(Init_Valid),
    .SP_Valid(1'b0),
    .SP_Done(SP_Done),
    .CKG_Valid(1'b0),
    .CKG_Done(CKG_Done),
    .SCU_Valid(1'b0),
    .SCU_Done(SCU_Done),
    .MDI_Valid(MDI_Valid),
    .SCO_Valid(SCO_Valid),
    // 控制输出
    .SP_Start(SP_Start),
    .CKG_Start(CKG_Start),
    .SCU_Start(SCU_Start)
);

// ================== 预测阶段 ==================
// 状态预测模块
StatePredictor #(.STATE_DIM(STATE_DIM)) u_StatePredictor (
    .clk(clk),
    .rst_n(rst_n),
    .F(F),
    .Xk_prev(Xk_prev),
    .ctrl_flag(SP_Start),    // 受状态机控制
    .Xk_pred(Xk_k_minus1)
);

// 协方差预测模块
//CovariancePredictor #(.STATE_DIM(STATE_DIM)) u_CovPredictor (
//    .clk(clk),
//    .rst_n(rst_n),
//    .F(F),
//    .Pk_prev(Pk_prev),
//    .Qk(Qk),
//    .ctrl_flag(SP_Start),    // 与状态预测同步
//    .Pm_k(Pm_k)
//);

// ================== 更新阶段 ==================
// 矩阵转置模块（H^T）
MatrixTransBridge #(MEASURE_DIM, STATE_DIM) u_HT_Transpose_Bridge (
    .matrix_in(H),
    .matrix_out(HT)
);

// 卡尔曼增益计算单元
KalmanGainCalculator #(
    .DWIDTH(64),
    .CMU_SIZE(3),
    .FIFO_DEPTH(16)
) u_KalmanGainCalc (
    .clk(clk),
    .rst_n(rst_n),
    .P_prev_3x3(Pm_k[11:9][11:9]),  // 取3x3子矩阵
    .cmu_valid_in(CKG_Start),
    .R_matrix(Rk[5:3][5:3]),       // 取3x3子矩阵
    .ceu_valid_in(CKG_Start),
    .K_k(Kk_sub),                  // 3x3增益子矩阵
    .data_valid_out(CKG_Done)
);

// 状态更新模块
StateUpdate #(.STATE_DIM(STATE_DIM)) u_StateUpdate (
    .clk(clk),
    .rst_n(rst_n),
    .Kk(Kk),
    .Zk(Zk),
    .Xk_pred(Xk_k_minus1),
    .H(H),
    .Xk_updated(Xk_k)
);

// 协方差更新模块
CovarianceUpdate #(.STATE_DIM(STATE_DIM)) u_CovUpdate (
    .clk(clk),
    .rst_n(rst_n),
    .Kk(Kk),
    .H(H),
    .Pm_k(Pm_k),
    .Pk_updated(Pk_k)
);

// ================== 时序对齐单元 ==================
DelayUnit #(3, STATE_DIM*32) u_DelayX (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(Xk_k_minus1),
    .data_out(Xk_delayed)
);

DelayUnit #(2, STATE_DIM*STATE_DIM*32) u_DelayP (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(Pm_k),
    .data_out(Pm_delayed)
);

// ================== 接口映射 ==================
assign SP_Done = u_StatePredictor.done && u_CovPredictor.done;
assign SCU_Done = u_CovUpdate.done;

endmodule

