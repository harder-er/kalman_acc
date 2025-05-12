`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 16:02:54
// Design Name: 
// Module Name: CMU_PHi44
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
// Module Name: CMU_PHi44
// Description: PHi44 通道的 CMU 计算，单级流水：
//              a = Θ10,10 + Q10,10
// Dependencies: fp_adder
//////////////////////////////////////////////////////////////////////////////////

module CMU_PHi44 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // —— 动态输入 —— 
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_10_10,
    // —— 输出 —— 
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);


    // 中间信号
    logic [DBL_WIDTH-1:0] sum;
    logic                  valid_pipe;

    // 浮点加法
    fp_adder U_add (
        .clk    (clk),
        .a      (Theta_10_10),
        .b      (Q_10_10),
        .result (sum)
    );

    // 一级流水寄存与 valid 管线
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a          <= '0;
            valid_pipe <= 1'b0;
        end else begin
            a          <= sum;
            valid_pipe <= 1'b1;
        end
    end

    assign valid_out = valid_pipe;

endmodule
