`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/24 15:55:52
// Design Name: 
// Module Name: ProcessingElement
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


module ProcessingElement #(
    parameter DWIDTH = 64,
    parameter ADD_PIPE_STAGES = 2
)(
    input  logic             clk,
    input  logic             rst,
    input  logic             en,
    input  logic [DWIDTH-1:0] a_in,
    input  logic [DWIDTH-1:0] b_in,
    input  logic [DWIDTH-1:0] sum_down,
    
    output logic [DWIDTH-1:0] a_out,
    output logic [DWIDTH-1:0] b_out,
    output logic [DWIDTH-1:0] sum_right,
    output logic             data_ready
);

// ���������� ״̬�����壨����״̬ת��ͼ��
typedef enum logic [2:0] {
    IDLE, INIT, MUL, ADD, SEND_DATA, DATA_THROUGH, END
} fsm_state;

fsm_state current_state, next_state;

// ���������� IP��ʵ������Xilinx DSP48E2ʾ����
multiplier_ip #(.DWIDTH(DWIDTH)) u_mult (
    .clk(clk),
    .ce(1'b1),
    .a(a_reg),
    .b(b_reg),
    .p(partial_sum)
);

adder_ip #(
    .DWIDTH(DWIDTH),
    .PIPE_STAGES(ADD_PIPE_STAGES)
) u_add (
    .clk(clk),
    .ce(1'b1),
    .a(partial_sum_reg),
    .b(sum_down),
    .s(sum_temp)
);

// ���������� ���ݼĴ���
logic [DWIDTH-1:0] a_reg, b_reg;
logic [DWIDTH-1:0] partial_sum;
logic [DWIDTH-1:0] partial_sum_reg;
logic [DWIDTH-1:0] sum_temp;

// ���������� �����ź�
logic mul_start, add_start;
logic mul_finish, add_finish;
logic data_through_finish;

// �������� ״̬ת���߼�����Ӧ״̬ͼ��
always_ff @(posedge clk) begin
    if(rst) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

always_comb begin
    next_state = current_state;
    case(current_state)
        IDLE: 
            if(en) next_state = INIT;
            else if(!en) next_state = DATA_THROUGH;
        
        INIT: 
            next_state = MUL;
        
        MUL: 
            if(mul_finish) next_state = ADD;
        
        ADD: 
            if(add_finish) next_state = SEND_DATA;
        
        SEND_DATA: 
            if(data_ready) next_state = END;
        
        DATA_THROUGH: 
            if(data_through_finish) next_state = END;
        
        END: 
            if(en) next_state = INIT;
            else next_state = IDLE;
    endcase
end

// ���������� ����ͨ�����ƣ���Ӧ�ܹ�ͼ��
always_ff @(posedge clk) begin
    if(rst) begin
        a_reg <= '0;
        b_reg <= '0;
        partial_sum_reg <= '0;
        sum_right <= '0;
        data_ready <= '0;
    end else begin
        case(current_state)
            INIT: begin
                a_reg <= a_in;
                b_reg <= b_in;
            end
            
            MUL: begin
                if(mul_finish)
                    partial_sum_reg <= partial_sum;
            end
            
            ADD: begin
                if(add_finish)
                    sum_right <= sum_temp;
            end
            
            SEND_DATA: begin
                data_ready <= 1'b1;
                a_out <= a_reg;
                b_out <= b_reg;
            end
            
            DATA_THROUGH: begin
                a_out <= a_in;
                b_out <= b_in;
                sum_right <= sum_down;
            end
            
            default: data_ready <= 1'b0;
        endcase
    end
end

// ���������� �����ź����ɣ���ȷʱ����ƣ�
assign mul_start = (current_state == MUL);
assign add_start = (current_state == ADD);

// �˷���ɼ�⣨����3�����ӳ٣�
logic [1:0] mul_counter;
always_ff @(posedge clk) begin
    if(current_state == MUL) begin
        mul_counter <= mul_counter + 1;
        mul_finish <= (mul_counter == 2'd2);
    end else begin
        mul_counter <= '0;
        mul_finish <= 1'b0;
    end
end

// �ӷ���ɼ�⣨��ˮ�߽׶�ƥ�䣩
logic [ADD_PIPE_STAGES-1:0] add_pipe;
always_ff @(posedge clk) begin
    add_pipe <= {add_pipe[ADD_PIPE_STAGES-2:0], add_start};
    add_finish <= add_pipe[ADD_PIPE_STAGES-1];
end

endmodule

// ���������� IP�˰�װģ�飨ʾ����
module multiplier_ip #(
    parameter DWIDTH = 64
)(
    input  logic             clk,
    input  logic             ce,
    input  logic [DWIDTH-1:0] a,
    input  logic [DWIDTH-1:0] b,
    output logic [DWIDTH-1:0] p
);

// Xilinx DSP48E2ʵ����ģ��
DSP48E2 #(
    .AMULTSEL("A"),
    .BMULTSEL("B"),
    .USE_MULT("MULTIPLY")
) u_dsp (
    .CLK(clk),
    .CE(ce),
    .A(a),
    .B(b),
    .P(p)
);

endmodule

module adder_ip #(
    parameter DWIDTH = 64,
    parameter PIPE_STAGES = 2
)(
    input  logic             clk,
    input  logic             ce,
    input  logic [DWIDTH-1:0] a,
    input  logic [DWIDTH-1:0] b,
    output logic [DWIDTH-1:0] s
);

// ��ˮ�߼ӷ���ʵ��
logic [DWIDTH-1:0] pipe_reg [PIPE_STAGES-1:0];

always_ff @(posedge clk) begin
    if(ce) begin
        pipe_reg[0] <= a + b;
        for(int i=1; i<PIPE_STAGES; i++)
            pipe_reg[i] <= pipe_reg[i-1];
    end
end

assign s = pipe_reg[PIPE_STAGES-1];

endmodule
