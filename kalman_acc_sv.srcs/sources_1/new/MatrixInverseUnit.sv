`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/10 17:01:06
// Design Name: 
// Module Name: MatrixInverseUnit  // 矩阵求逆单元模块
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 实现3x3矩阵求逆运算，支持浮点数据格式的流水线处理
// 
// Dependencies: 依赖CEU系列浮点运算单元（CEU_a, CEU_d, CEU_division等）
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 采用三级流水线架构，支持矩阵元素的并行计算
// 
//////////////////////////////////////////////////////////////////////////////////


module MatrixInverseUnit #(
    parameter DWIDTH = 64  // 数据宽度（浮点精度位宽）
)(
    input  logic             clk,           // 时钟信号
    input  logic             rst_n,         // 复位信号（低有效）
    
    // MIBus接口（主控制总线）
    input  logic [127:0]     mibus_cmd,     // 控制指令总线（含操作码和使能信号）
    output logic [63:0]      mibus_status,  // 状态反馈总线（含运算完成标志）
    
    // MTBus接口（矩阵传输总线）
    input  logic [DWIDTH-1:0] mtbus_ch [8:0],  // 9通道输入（对应3x3矩阵元素）
    output logic [DWIDTH-1:0] result_ch [8:0]  // 9通道输出（对应逆矩阵元素）
);

// ==== 输入寄存器组（对应图中Input reg模块）
//-----------------------------------------------------------------
logic [DWIDTH-1:0] input_reg [8:0];  // 输入矩阵元素缓存寄存器

// 数据加载控制（当操作码为0x1时加载输入矩阵）
always_ff @(posedge clk) begin
    if(mibus_cmd[15:12] == 4'h1)  // 加载指令（操作码4'h1）
        input_reg <= mtbus_ch;     // 从MTBus接收原始矩阵数据
end

// ==== 中间结果寄存器（对应图中Intermediate Result Reg）
//-----------------------------------------------------------------
logic [DWIDTH-1:0] a, b, c, d, e, f, x, y, z;  // 矩阵运算中间变量

// ==== CEU模块实例化（按流程图处理顺序）
//-----------------------------------------------------------------
// ================== 第一计算阶段：基础乘法运算 ==================
// 计算a = H[0][0] * P[0][0]（假设H为系数矩阵，P为输入矩阵）
CEU_a u_CEU_a (
    .clk        (clk),
    .in1        (input_reg[0]),  // 矩阵元素H[0][0]（第一行第一列）
    .in2        (input_reg[4]),  // 矩阵元素P[0][0]（假设为协方差矩阵元素）
    .out        (a)              // 输出中间乘积结果a
);

// 计算x = H[0][1] * P[1][0]（示例：第二列第一行元素乘积）
CEU_d u_CEU_d (
    .clk        (clk),
    .in1        (input_reg[1]),  // 矩阵元素H[0][1]
    .in2        (input_reg[3]),  // 矩阵元素P[1][0]
    .out        (x)              // 输出中间乘积结果x
);
CEU_x u_CEU_x (
    .clk        (clk),
    .in1        (input_reg[1]),  // 矩阵元素H[0][1]
    .in2        (input_reg[3]),  // 矩阵元素P[1][0]
    .out        (x)              // 输出中间乘积结果x
);
// ... 其他CEU模块实例化（b/c/d/e/f等中间变量计算，按矩阵展开式补充）

// ================== 第二计算阶段：行列式计算 ==================
// 计算α = a*d - x?（行列式核心项）
CEU_alpha u_CEU_alpha (
    .clk        (clk),
    .in1        (a),             // 第一行第一列乘积项
    .in2        (d),             // 第二行第二列乘积项
    .in3        (x),             // 交叉项平方
    .out        (alpha)          // 输出行列式值α
);

// ================== 第三计算阶段：逆矩阵元素计算 ==================
// 计算1/α（行列式倒数）
CEU_division u_CEU_div (
    .clk        (clk),
    .numerator  ({b, e, y}),     // 分子项（组合中间结果）
    .denominator(alpha),         // 分母项（行列式值）
    .quotient   (inv_alpha)      // 输出倒数结果1/α
);

// ================== 输出阶段：逆矩阵元素合成 ==================
// 计算逆矩阵第一行第一列元素：(d*e - y?)/α
always_ff @(posedge clk) begin
    result_reg[0] <= inv_alpha * (d*e - y*y);  // 对应图中最终矩阵元素计算
    result_reg[1] <= inv_alpha * (x*y - b*d);   // 交叉项修正（按矩阵求逆公式）
    // ... 其他矩阵元素计算（按3x3矩阵逆运算公式补充）
end

// ==== 输出寄存器组（对应图中Output Reg模块）
//-----------------------------------------------------------------
logic [DWIDTH-1:0] result_reg [8:0];  // 输出结果缓存寄存器
assign result_ch = result_reg;         // 驱动输出总线

endmodule