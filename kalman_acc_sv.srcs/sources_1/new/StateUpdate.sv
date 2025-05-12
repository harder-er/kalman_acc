`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/10 15:30:48
// Design Name: 
// Module Name: StateUpdate
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

module StateUpdate (
    input  logic         clk,
    input  logic         rst_n,
    
    // 状态转移矩阵输入
    input  logic [63:0]  F [11:0][11:0], // 
    input  logic [63:0]  X_kk [11:0], // 
    // FIFO输出接口
    output logic [63:0]  X_k1k [11:0],   // X_{k+1,k}输出
    output logic         fifo_valid      // 数据有效标志
);
logic [64-1:0] matrix_out [0:12-1][0:12-1];
generate//填充为12x12矩阵
    for (genvar i = 0; i < 12; i++) begin : row_gen
        for (genvar j = 0; j < 12; j++) begin : col_gen
            always_ff @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    matrix_out[i][j] <= 64'h0; // 复位时清零
                end else  begin
                    matrix_out[i][j] <= (j == 0) ? X_kk[i] : 64'h0;
                end
            end
        end
    end
endgenerate

logic [64-1:0] Xk1kmatrix [11:0][11:0];
SystolicArray #(
    .DWIDTH(64),
    .ARRAY_SIZE(3)
) u_systolic (
    .clk(clk),
    .rst_n(rst_n),
    .a_row(F),   // 来自FIFO的P_predicted
    .b_col(matrix_out),      // CEU计算的逆矩阵
    .load_en(ceu_complete), // CEU完成后加载
    .enb_1(ceu_valid_in), // CEU有效信号
    .enb_2_6(cmu_valid_in), // CMU有效信号
    .enb_7_12(ceu_complete), // CEU完成信号
    .c_out(Xk1kmatrix)
);
generate
    for (genvar i = 0; i < 12; i++) begin : gen_Xk1k
        assign X_k1k[i] = Xk1kmatrix[i][0];
    end
endgenerate

endmodule