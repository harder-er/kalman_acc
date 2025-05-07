`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 10:05:39
// Design Name: 
// Module Name: RecursiveChannel
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


module RecursiveChannel #(
    parameter DEPTH = 84
)(
    input  logic             clk,
    input  logic [63:0]      data_in,
    input  logic [63:0]      fifo_data,
    output logic [63:0]      data_out
);

logic [63:0] accum_reg;

// 深度84的滑动窗口累加器
always_ff @(posedge clk) begin
    accum_reg <= accum_reg * 0.95 + data_in * 0.05 + fifo_data;
end

assign data_out = accum_reg;

endmodule