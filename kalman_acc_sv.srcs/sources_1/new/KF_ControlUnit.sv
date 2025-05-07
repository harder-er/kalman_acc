`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/24 16:58:05
// Design Name: 
// Module Name: KF_ControlUnit
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


module KF_ControlUnit (
    input  logic         clk,
    input  logic         rst,
    // 状态转换输入信号
    input  logic         Init_Valid,
    input  logic         SP_Valid,
    input  logic         SP_Done,
    input  logic         CKG_Valid,
    input  logic         CKG_Done,
    input  logic         SCU_Valid,
    input  logic         SCU_Done,
    input  logic         MDI_Valid,
    input  logic         SCO_Valid,
    input  logic         End_Valid,
    // 控制输出信号
    output logic         Init_Valid_out,
    output logic         SP_Start,
    output logic         CKG_Start,
    output logic         SCU_Start,
    output logic         MDI_Start,
    output logic         SCO_Start,
    output logic         End_Flag
);

// █████ 状态定义（严格匹配状态图）
typedef enum logic [2:0] {
    INIT,               // 初始化
    STATE_PREDICTION,   // 状态预测
    CAL_KALMAN_GAIN,    // 卡尔曼增益计算
    STATE_COV_UPDATE,   // 协方差更新
    MEASURE_DATA_IN,    // 测量数据输入
    STATE_COV_OUTPUT,   // 状态协方差输出
    END_STATE           // 结束状态
} fsm_state;

fsm_state current_state, next_state;

// █████ 状态寄存器
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        current_state <= INIT;
    end else begin
        current_state <= next_state;
    end
end

// █████ 状态转移逻辑（精确对应转换条件）
always_comb begin
    next_state = current_state;
    case (current_state)
        INIT: begin
            if (Init_Valid) 
                next_state = STATE_PREDICTION;
        end
        
        STATE_PREDICTION: begin
            if (SP_Done) begin
                if (CKG_Valid)
                    next_state = CAL_KALMAN_GAIN;
                else if (SCU_Valid)
                    next_state = STATE_COV_UPDATE;
            end
        end
        
        CAL_KALMAN_GAIN: begin
            if (CKG_Done)
                next_state = STATE_COV_UPDATE;
        end
        
        STATE_COV_UPDATE: begin
            if (SCU_Done) begin
                if (MDI_Valid)
                    next_state = MEASURE_DATA_IN;
                else if (SCO_Valid)
                    next_state = STATE_COV_OUTPUT;
            end
        end
        
        MEASURE_DATA_IN: begin
            if (MDI_Valid)
                next_state = STATE_PREDICTION;
        end
        
        STATE_COV_OUTPUT: begin
            if (End_Valid)
                next_state = END_STATE;
        end
        
        END_STATE: begin
            if (rst)
                next_state = INIT;
        end
    endcase
end

// █████ 输出控制信号生成（同步时序）
always_ff @(posedge clk) begin
    if (rst) begin
        {Init_Valid_out, SP_Start, CKG_Start, SCU_Start, MDI_Start, SCO_Start, End_Flag} <= '0;
    end else begin
        case (current_state)
            INIT: begin
                Init_Valid_out <= 1'b1;
                SP_Start       <= 1'b0;
            end
            
            STATE_PREDICTION: begin
                SP_Start       <= 1'b1;
                CKG_Start      <= 1'b0;
            end
            
            CAL_KALMAN_GAIN: begin
                CKG_Start      <= 1'b1;
                SCU_Start      <= 1'b0;
            end
            
            STATE_COV_UPDATE: begin
                SCU_Start      <= 1'b1;
                MDI_Start      <= 1'b0;
            end
            
            MEASURE_DATA_IN: begin
                MDI_Start      <= 1'b1;
                SCO_Start      <= 1'b0;
            end
            
            STATE_COV_OUTPUT: begin
                SCO_Start      <= 1'b1;
                End_Flag       <= 1'b0;
            end
            
            END_STATE: begin
                End_Flag       <= 1'b1;
            end
            
            default: begin
                {Init_Valid_out, SP_Start, CKG_Start, SCU_Start, MDI_Start, SCO_Start, End_Flag} <= '0;
            end
        endcase
    end
end

// █████ 异步复位同步释放处理
logic rst_sync;
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        rst_sync <= 1'b1;
    end else begin
        rst_sync <= 1'b0;
    end
end

endmodule
