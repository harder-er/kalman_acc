`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/08 22:01:37
// Design Name: 
// Module Name: CMU_PHi11
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



module CMU_PHi11 #(
    parameter DBL_WIDTH = 64
)(
    input  logic                   clk,
    input  logic                   rst_n,
    // 输入参数
    input  logic [DBL_WIDTH-1:0]   Theta_1_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_1,
    input  logic [DBL_WIDTH-1:0]   Theta_7_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_4,
    input  logic [DBL_WIDTH-1:0]   Theta_10_1,
    input  logic [DBL_WIDTH-1:0]   Theta_4_7,
    input  logic [DBL_WIDTH-1:0]   Theta_7_7,
    input  logic [DBL_WIDTH-1:0]   Theta_4_10,
    input  logic [DBL_WIDTH-1:0]   Theta_7_10,
    input  logic [DBL_WIDTH-1:0]   Theta_10_10,
    input  logic [DBL_WIDTH-1:0]   Q_1_1,
    // 时间参数
    input  logic [DBL_WIDTH-1:0]   delta_t,
    // 输出
    output logic [DBL_WIDTH-1:0]   a,
    output logic                   valid_out
);

    
    logic [5:0] valid_pipe;

    reg [63:0] stage1_M1, stage1_M2, stage1_M3;
    reg [63:0] stage2_A1, stage2_A2, stage2_A3, stage2_A4;
    reg [63:0] stage3_X1, stage3_X2, stage3_X3, stage3_X4, stage3_X5, stage3_X6;
    reg [63:0] stage4_T1, stage4_T2, stage4_T3, stage4_T4, stage4_T5;

    logic deltat_valid, sq_finish, cu_finish, qu_finish, qi_finish, sx_finish;
    assign deltat_valid = 1'b1;

    logic multN_valid, finish_347, finish_377, finish_410;
    assign multN_valid = sq_finish & cu_finish & qu_finish & qi_finish & sx_finish;

    logic addA_valid, addA1_finish, addA2_finish, addA3_finish, addA4_finish;
    assign addA_valid = finish_347 & finish_377 & finish_410;

    logic multX_valid, multX1_finish, multX2_finish, multX3_finish, multX4_finish, multX5_finish, multX6_finish;
    assign multX_valid = multX1_finish & multX2_finish & multX3_finish & multX4_finish & multX5_finish & multX6_finish;

    logic scale_valid, scale3_finish, scale4_finish, scale5_finish, scale6_finish;
    assign scale_valid = multX1_finish & multX2_finish & multX3_finish & multX4_finish & multX5_finish & multX6_finish;

    logic addT_valid, addT1_finish, addT2_finish, addT3_finish, addT4_finish, addT5_finish;
    assign addT_valid = scale3_finish & scale4_finish & scale5_finish & scale6_finish;
    
    logic finaladd_valid, final_add_finish;
    assign finaladd_valid = addT1_finish & addT2_finish & addT3_finish & addT4_finish & addT5_finish;    
    // 时间参数计算模块
    fp_multiplier delta_t_sq (.clk(clk), .valid(deltat_valid), .finish(sq_finish),.a(delta_t), .b(delta_t), .result(delta_t2));
    fp_multiplier delta_t_cu (.clk(clk), .valid(deltat_valid), .finish(cu_finish),.a(delta_t2), .b(delta_t), .result(delta_t3));
    fp_multiplier delta_t_qu (.clk(clk), .valid(deltat_valid), .finish(qu_finish),.a(delta_t3), .b(delta_t), .result(delta_t4));
    fp_multiplier delta_t_qi (.clk(clk), .valid(deltat_valid), .finish(qi_finish),.a(delta_t4), .b(delta_t), .result(delta_t5));
    fp_multiplier delta_t_sx (.clk(clk), .valid(deltat_valid), .finish(sx_finish),.a(delta_t5), .b(delta_t), .result(delta_t6));

    // 常数乘法模块
    fp_multiplier mult_3_4_7 (.clk(clk), .valid(multN_valid),.finish(finish_347), .a(64'h4008000000000000), .b(Theta_4_7), .result(stage1_M1));  // 3*Θ4,7
    fp_multiplier mult_3_7_7 (.clk(clk), .valid (multN_valid),.finish(finish_377), .a(64'h4008000000000000), .b(Theta_7_7), .result(stage1_M2));  // 3*Θ7,7
    fp_multiplier mult_4_10_4 (.clk(clk),.valid(multN_valid), .finish(finish_410), .a(64'h4010000000000000), .b(Theta_10_4_10), .result(stage1_M3)); // 4*Θ10,4

    // 加法模块链
    fp_adder add_A1 (.clk(clk), .valid(addA_valid),.finish(addA1_finish), .a(Theta_1_1), .b(Q_1_1), .result(stage2_A1));
    fp_adder add_A2 (.clk(clk), .valid(addA_valid),.finish(addA2_finish), .a(Theta_7_1), .b(Theta_4_4), .result(stage2_A2));
    fp_adder add_A3 (.clk(clk), .valid(addA_valid),.finish(addA3_finish), .a(Theta_10_1), .b(stage1_M1), .result(stage2_A3));
    fp_adder add_A4 (.clk(clk), .valid(addA_valid),.finish(addA4_finish), .a(stage1_M2), .b(stage1_M3), .result(stage2_A4));

    // 时间参数乘法模块
    fp_multiplier mult_X1 (.clk(clk), .valid (multX_valid), .finish (multX1_finish),.a(64'h4000000000000000), .b(Theta_4_1), .result(stage3_X1)); // 2Δt*Θ4,1
    fp_multiplier mult_X2 (.clk(clk), .valid (multX_valid), .finish (multX2_finish),.a(delta_t2), .b(stage2_A2), .result(stage3_X2));
    fp_multiplier mult_X3 (.clk(clk), .valid (multX_valid), .finish (multX3_finish),.a(delta_t3), .b(stage2_A3), .result(stage3_X3));
    fp_multiplier mult_X4 (.clk(clk), .valid (multX_valid), .finish (multX4_finish),.a(delta_t4), .b(stage2_A4), .result(stage3_X4));
    fp_multiplier mult_X5 (.clk(clk), .valid (multX_valid), .finish (multX5_finish),.a(delta_t5), .b(Theta_7_10), .result(stage3_X5));
    fp_multiplier mult_X6 (.clk(clk), .valid (multX_valid), .finish (multX6_finish),.a(delta_t6), .b(Theta_10_10), .result(stage3_X6));

    // 系数调整模块
    fp_multiplier scale_X3 (.clk(clk), .valid(scale_valid),.finish(scale3_finish),.a(stage3_X3), .b(64'h3fd5555555555555), .result(stage3_X3)); // 1/3
    fp_multiplier scale_X4 (.clk(clk), .valid(scale_valid),.finish(scale4_finish),.a(stage3_X4), .b(64'h3f9c71c71c71c71c), .result(stage3_X4)); // 1/12
    fp_multiplier scale_X5 (.clk(clk), .valid(scale_valid),.finish(scale5_finish),.a(stage3_X5), .b(64'h3fc5555555555555), .result(stage3_X5)); // 1/6
    fp_multiplier scale_X6 (.clk(clk), .valid(scale_valid),.finish(scale6_finish),.a(stage3_X6), .b(64'h3f9c71c71c71c71c), .result(stage3_X6)); // 1/36

    // 累加模块
    fp_adder add_T1 (.clk(clk), .valid(addT_valid),.finish(addT1_finish),.a(stage2_A1), .b(stage3_X1), .result(stage4_T1));
    fp_adder add_T2 (.clk(clk), .valid(addT_valid),.finish(addT2_finish),.a(stage3_X2), .b(stage3_X3), .result(stage4_T2));
    fp_adder add_T3 (.clk(clk), .valid(addT_valid),.finish(addT3_finish),.a(stage3_X4), .b(stage3_X5), .result(stage4_T3));
    fp_adder add_T4 (.clk(clk), .valid(addT_valid),.finish(addT4_finish),.a(T1), .b(stage3_X6), .result(stage4_T3));
    fp_adder add_T5 (.clk(clk), .valid(addT_valid),.finish(addT5_finish),.a(T2), .b(T3), .result(stage4_T5));


    fp_adder final_add (.clk(clk), .valid(finaladd_valid),.finish(final_add_finish), .a(stage4_T5), .b(stage4_T4), .result(a));


    // 验证信号流水线
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) valid_pipe <= 6'b0;
        else valid_pipe <= {valid_pipe[4:0], 1'b1};
    end

    assign valid_out = valid_pipe[5]&final_add_finish;

endmodule