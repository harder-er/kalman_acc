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
    parameter DWIDTH = 64,
    parameter FIFO_DEPTH = 12
)(
    input  logic                     clk,
    input  logic                     rst_n,
    // MIBus输入接口（对应图示紫色模块接口）
    input  logic [DWIDTH-1:0]       Kk [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       H [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       Rk [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [DWIDTH-1:0]       P_prev [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic                     valid_in,
    // OMBus输出接口（对应图示橙色输出路径）
    output logic [DWIDTH-1:0]       Pk_k [STATE_DIM-1:0][STATE_DIM-1:0],
    output logic                     valid_out
);

// ================== 脉动阵列核心单元 ==================
// 矩阵乘法单元配置（对应图示蓝色运算模块）
generate
    // K*R计算单元（对应图示路径①）
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_KR (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(Kk),         // K矩阵行输入
        .b_col(Rk),         // R矩阵列输入
        .load_en(valid_in),
        .enb_1(1'b0),       // 全阵列激活
        .enb_2_6(1'b0),
        .enb_7_12(1'b1),
        .c_out(KR_result)   // 输出到FIFO
    );

    // (K*R)*K^T计算单元（对应图示路径②）
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_KRKt (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(KR_result),  // K*R结果输入
        .b_col(transpose(Kk)), // K转置输入
        .load_en(kr_done),
        .enb_1(1'b0),
        .enb_2_6(1'b0),
        .enb_7_12(1'b1),
        .c_out(KRKt)
    );

    // K*H计算单元（对应图示路径③）
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_KH (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(Kk),
        .b_col(H),
        .load_en(valid_in),
        .enb_1(1'b1),       // 仅激活首行PE
        .enb_2_6(1'b0),
        .enb_7_12(1'b0),
        .c_out(KH)
    );

    // (I-KH)*P_prev计算单元（对应图示路径④）
    SystolicArray #(.DWIDTH(DWIDTH), .MAX_SIZE(STATE_DIM)) u_IKH_P (
        .clk(clk),
        .rst_n(rst_n),
        .a_row(generate_I() - KH), // 硬件生成单位矩阵
        .b_col(P_prev),
        .load_en(ikh_done),
        .enb_1(1'b0),
        .enb_2_6(1'b1),      // 激活中间区域
        .enb_7_12(1'b0),
        .c_out(IKH_P)
    );
endgenerate

// ================== 控制逻辑增强（对应图示状态机） ==================
// 动态重构控制单元（精确匹配图示enb信号）
always_comb begin
    case(current_state)
        IDLE: begin
            u_KR.enb_1 = 1'b0;
            u_KRKt.enb_7_12 = 1'b1;
            u_KH.enb_1 = 1'b1;
            u_IKH_P.enb_2_6 = 1'b1;
        end
        // ...其他状态控制信号映射...
    endcase
end

// ================== 数据流优化（对应图示箭头方向） ==================
// 矩阵转置功能实现（对应图示H^T路径）
function automatic [STATE_DIM-1:0][STATE_DIM-1:0] transpose;
    input [STATE_DIM-1:0][STATE_DIM-1:0] matrix_in;
    begin
        for(int i=0; i<STATE_DIM; i++)
            for(int j=0; j<STATE_DIM; j++)
                transpose[j][i] = matrix_in[i][j];
    end
endfunction

// 单位矩阵生成器（对应图示I-KH计算）
function [STATE_DIM-1:0][STATE_DIM-1:0] generate_I;
    for(int i=0; i<STATE_DIM; i++) begin
        for(int j=0; j<STATE_DIM; j++) begin
            generate_I[i][j] = (i == j) ? {DWIDTH{1'b1}} : '0;
        end
    end
endfunction

// ================== 时序对齐单元（对应图示迭代延迟模块） ==================
DelayUnit #(
    .DEPTH(4),  // 四级流水线延迟
    .DATA_WIDTH(STATE_DIM*STATE_DIM*DWIDTH)
) u_delay (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(temp_sum),
    .data_out(Pk_k)
);

// ================== 异常处理（图示未显示但关键） ==================
// 矩阵奇异值检测
always_ff @(posedge clk) begin
    if(u_KRKt.singular_detect) begin
        $error("Singular matrix detected in KRKt calculation");
        valid_out <= 1'b0;
    end
end

endmodule