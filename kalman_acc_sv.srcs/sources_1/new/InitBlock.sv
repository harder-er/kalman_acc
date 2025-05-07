`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/13 10:13:01
// Design Name: 
// Module Name: InitBlock
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


module InitBlock #(
    parameter WIDTH = 64
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic [12*WIDTH-1:0] initial_data,
    output logic [12*WIDTH-1:0] bus_out
);

logic [3:0] init_phase;

always_ff @(posedge clk) begin
    if(!rst_n) begin
        bus_out <= 0;
        init_phase <= 0;
    end else begin
        case(init_phase)
            0: bus_out <= initial_data;     // º”‘ÿ≥ı ºæÿ’Û
            1: bus_out <= bus_out >> WIDTH; // æÿ’Û¡–—≠ª∑“∆Œª
            default: ; 
        endcase
        init_phase <= init_phase + 1;
    end
end

endmodule