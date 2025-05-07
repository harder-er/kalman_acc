`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/25 19:34:59
// Design Name: 
// Module Name: CMU
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

// █████ CMU子模块（3x3矩阵计算）
module CMU_3x3 #(
    parameter DWIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic [DWIDTH-1:0]     P_prev [0:2][0:2],
    input  logic                   valid_in,
    
    output logic [DWIDTH-1:0]     P_predicted [0:2][0:2],
    output logic [DWIDTH-1:0]     P_predicted_HT [0:2][0:2],
    output logic                   cmu_done
);

// 矩阵运算流水线寄存器
logic [DWIDTH-1:0] stage1 [0:2][0:2];
logic [DWIDTH-1:0] stage2 [0:2][0:2];

always_ff @(posedge clk) begin
    if(valid_in) begin
        // Stage1: 计算P_predicted
        for(int i=0; i<3; i++) begin
            for(int j=0; j<3; j++) begin
                stage1[i][j] <= P_prev[i][j] * 1.5;  // 示例计算过程
            end
        end
        
        // Stage2: 计算转置矩阵HT
        for(int i=0; i<3; i++) begin
            for(int j=0; j<3; j++) {
                stage2[i][j] <= stage1[j][i];  // 矩阵转置
            end
        }
        
        cmu_done <= 1'b1;
    end else begin
        cmu_done <= 1'b0;
    end
end

assign P_predicted = stage1;
assign P_predicted_HT = stage2;

endmodule
