`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 09:58:38
// Design Name: 
// Module Name: StatePredictor
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

module StatePredictor #(
    parameter VEC_WIDTH = 64,
    parameter MAT_DIM = 12
)(
    input  logic             clk,
    input  logic             rst_n,
    
    // 系统输入接口
    input  logic [VEC_WIDTH-1:0] X_k_k_1,     // 上一时刻状态估计
    input  logic [VEC_WIDTH-1:0] Kk,          // Kalman增益
    input  logic [MAT_DIM*VEC_WIDTH-1:0] P_prev, // 协方差矩阵
    
    // 总线接口
    output MIBus_if          predict_bus,    // 预测总线
    input  FIFO_if           fifo_in,        // 观测数据输入
    
    // 系统输出
    output logic [VEC_WIDTH-1:0] Z_k         // 最终预测输出
);

// ==== 核心处理通道结构
//-----------------------------------------------------------------
logic [VEC_WIDTH-1:0] channel_reg [3:0];
logic [MAT_DIM*VEC_WIDTH-1:0] matrix_bus;

// 初始化模块（对应图中Init模块）
InitBlock #(.WIDTH(VEC_WIDTH)) u_init (
    .clk(clk),
    .rst_n(rst_n),
    .initial_data(P_prev),
    .bus_out(matrix_bus[MAT_DIM*VEC_WIDTH-1:0])
);

// 主处理通道（对应图中黑色通道模块）
ChannelProcessor #(.WIDTH(VEC_WIDTH)) u_channel (
    .clk(clk),
    .data_in({X_k_k_1, matrix_bus}),
    .neg_en(predict_bus.ctrl_flag),  // 总线控制信号
    .data_out(channel_reg[0])
);

// 乘法队列（对应图中MUX模块）
MatrixMultiplier u_mux (
    .clk(clk),
    .operand_a(channel_reg[0]),
    .operand_b(Kk),
    .result(channel_reg[1])
);

// 递归反馈通道（对应图中绿色通道）
RecursiveChannel u_feedback (
    .clk(clk),
    .data_in(channel_reg[1]),
    .fifo_data(fifo_in.data),
    .data_out(channel_reg[2])
);

// 最终输出合成
assign Z_k = channel_reg[3];

// ==== 时序控制控制
//-----------------------------------------------------------------
always_ff @(posedge clk) begin
    if(!rst_n) begin
        channel_reg <= '{default:0};
    end else begin
        // 三级流水线寄存
        channel_reg[3] <= channel_reg[2] + predict_bus.adjust_term;  // 总线校正项
    end
end

endmodule