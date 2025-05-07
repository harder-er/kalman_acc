`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/24 15:40:54
// Design Name: 
// Module Name: SystolicArray
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


module SystolicArray #(
    parameter DWIDTH = 64,
    parameter MAX_SIZE = 12
)(
    input  logic             clk,
    input  logic             rst_n,
    
    // 矩阵输入接口
    input  logic [DWIDTH-1:0] a_row [0:MAX_SIZE-1],
    input  logic [DWIDTH-1:0] b_col [0:MAX_SIZE-1],
    input  logic             load_en,
    
    // 重构控制信号
    input  logic             enb_1,
    input  logic             enb_2_6,
    input  logic             enb_7_12,
    
    // 结果输出
    output logic [DWIDTH-1:0] c_out [0:MAX_SIZE-1][0:MAX_SIZE-1]
);

// █████ 输入寄存器组
//-----------------------------------------------------------------
logic [DWIDTH-1:0] a_reg [0:MAX_SIZE-1][0:MAX_SIZE-1];
logic [DWIDTH-1:0] b_reg [0:MAX_SIZE-1][0:MAX_SIZE-1];

always_ff @(posedge clk) begin
    if(load_en) begin
        // 按行加载矩阵A
        for(int i=0; i<MAX_SIZE; i++) begin
            a_reg[i][0] <= a_row[i];  // 左侧寄存器列
        end
        
        // 按列加载矩阵B 
        for(int j=0; j<MAX_SIZE; j++) begin
            b_reg[0][j] <= b_col[j];  // 顶部寄存器行
        end
    end
end

// █████ 可重构解码器
//-----------------------------------------------------------------
logic [MAX_SIZE-1:0] row_enable;

always_comb begin
    row_enable = '0;
    case({enb_7_12, enb_2_6, enb_1})
        3'b001: row_enable[0] = 1'b1;        // 第1行
        3'b010: row_enable[5:1] = '1;        // 第2-6行
        3'b100: row_enable[11:6] = '1;       // 第7-12行
        default: row_enable = '0;
    endcase
end

// █████ 延迟计数器网络
//-----------------------------------------------------------------
logic [3:0] delay_counter [0:MAX_SIZE-1][0:MAX_SIZE-1];

generate
for(genvar i=0; i<MAX_SIZE; i++) begin
    for(genvar j=0; j<MAX_SIZE; j++) begin
        always_ff @(posedge clk) begin
            if(i==0 && j==0) 
                delay_counter[i][j] <= 4'd0;
            else
                delay_counter[i][j] <= delay_counter[i][j] + 1;
        end
    end
end
endgenerate

// █████ PE处理单元阵列
//-----------------------------------------------------------------
logic [DWIDTH-1:0] a_data [0:MAX_SIZE][0:MAX_SIZE];
logic [DWIDTH-1:0] b_data [0:MAX_SIZE][0:MAX_SIZE];
logic [DWIDTH-1:0] c_data [0:MAX_SIZE][0:MAX_SIZE];

generate
for(genvar i=0; i<MAX_SIZE; i++) begin
    for(genvar j=0; j<MAX_SIZE; j++) begin
        ProcessingElement u_pe (
            .clk(clk),
            .rst_n(rst_n),
            .en(row_enable[i]),
            .delay(delay_counter[i][j]),
            
            // 数据通路
            .a_in(a_data[i][j]),
            .b_in(b_data[i][j]),
            .c_in((i==0 && j==0) ? '0 : c_data[i-1][j]),
            
            .a_out(a_data[i][j+1]),
            .b_out(b_data[i+1][j]),
            .c_out(c_data[i][j])
        );
        
        // 边界连接
        if(j == 0) assign a_data[i][j] = a_reg[i][0];
        if(i == 0) assign b_data[i][j] = b_reg[0][j];
        
        // 结果输出
        assign c_out[i][j] = c_data[i][j];
    end
end
endgenerate

endmodule
