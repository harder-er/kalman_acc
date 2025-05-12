`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
//
// Create Date: 2025/03/10 11:35:25
// Module Name: KalmanFilterTop
// Description: 卡尔曼滤波器顶层模块，支持 12 维状态和 6 维测量
//////////////////////////////////////////////////////////////////////////////////

module KalmanFilterTop #(
    parameter STATE_DIM     = 12,
    parameter MEASURE_DIM   = 6 ,
    parameter deltat        = 0.01
)(
    input  logic                         clk        ,
    input  logic                         rst_n      ,
    input  logic                         start      ,


    // 系统模型参数
    input  logic [64:0]                  Q_k    [STATE_DIM-1:0][STATE_DIM-1:0],
    input  logic [64:0]                  R_k    [MEASURE_DIM-1:0][MEASURE_DIM-1:0],

    // 实时数据接口
    input  logic [64:0]                  Z_k    [MEASURE_DIM-1:0],
    input  logic [64:0]                  X_00   [STATE_DIM-1:0],
    input  logic [64:0]                  P_00   [STATE_DIM-1:0][STATE_DIM-1:0],

    // 滤波结果输出
    output logic [31:0]                  X_kkout  [STATE_DIM-1:0],
    output logic [31:0]                  P_kkout  [STATE_DIM-1:0][STATE_DIM-1:0]

);

    // -------------------------------------------------
    //  内部信号声明
    // -------------------------------------------------
    logic [63:0]                         X_k1k [STATE_DIM-1:0]; // x_k+1,k
    logic [63:0]                         X_kk1 [STATE_DIM-1:0]; // x_k,k-1
    logic [63:0]                         X_kk  [STATE_DIM-1:0]; // x_k,k


    logic [63:0]                         P_k1k        [STATE_DIM-1:0][STATE_DIM-1:0]; // P_k+1,k
    logic [63:0]                         P_kk1        [STATE_DIM-1:0][STATE_DIM-1:0]; // P_k,k-1
    logic [63:0]                         P_kk         [STATE_DIM-1:0][STATE_DIM-1:0]; // P_k,k
    logic [63:0]                         P_k1k1       [STATE_DIM-1:0][STATE_DIM-1:0]; // P_k-1,k-1
    
    logic [63:0]                         K_k      [STATE_DIM-1:0][STATE_DIM-1:0];

    logic [63:0]                         F        [STATE_DIM-1:0][STATE_DIM-1:0]; // K_k


    logic                                SP_Start, CKG_Start, SCU_Start;
    // 各子模块完成标志
    logic                               sp_done, cp_done, kgc_done, su_done, cu_done;
    logic                               Init_Valid;
    logic                               SP_Done;
    logic                               CKG_Done;
    logic                               SCU_Done;
    logic                               MDI_Valid;
    logic                               SCO_Valid;
    // -------------------------------------------------
    // 控制单元
    // -------------------------------------------------
    KF_ControlUnit u_ControlUnit (
        .clk        (   clk             ),
        .rst        (   rst_n           ),
        .Init_Valid (   Init_Valid      ),
        .SP_Valid   (   SP_Start        ),
        .SP_Done    (   sp_done         ),
        .CKG_Valid  (   CKG_Start       ),
        .CKG_Done   (   kgc_done        ),
        .SCU_Valid  (   SCU_Start       ),
        .SCU_Done   (   su_done         ),
        .MDI_Valid  (   MDI_Valid       ),
        .SCO_Valid  (   SCO_Valid       ),
        .SP_Start   (   SP_Start        ),
        .CKG_Start  (   CKG_Start       ),
        .SCU_Start  (   SCU_Start       )
    );

    Fmake u_Fmake (
        .clk        ( clk    ),
        .rst_n      ( rst_n  ),
        .deltat     ( deltat ),
        .F          ( F      )
    );
    // -------------------------------------------------
    // 状态预测
    // -------------------------------------------------
    StateUpdate u_StateUpdator (
        .clk            ( clk       ),
        .rst_n          ( rst_n     ),
        .F              ( F         ),
        .X_kk           ( X_kk      ),
        .X_k1k          ( X_k1k     ),
        .fifo_valid     ( sp_done   )
    );


    assign SP_Done = sp_done && cp_done;

    
    KalmanGainCalculator #(
        .DWIDTH    (64)
    ) u_KalmanGainCalc (
        .clk             (clk),
        .rst_n           (rst_n),
        .Q_k             (Q_k),
        .P_k1k1          (P_k1k1),
        .CKG_start       (CKG_Start),
        .R_k              (R_k),
        .K_k              (K_k),
        .data_valid_out  (kgc_done)
    );

    assign CKG_Done = kgc_done;

    // -------------------------------------------------
    // 状态更新
    // -------------------------------------------------
    StatePredictor #(
        .VEC_WIDTH(64),
        .MAT_DIM  (12)
    ) u_StatePredictor (
        .clk           ( clk        ),
        .rst_n         ( rst_n      ),
        .K_k           ( K_k        ),
        .Z_k           ( Z_k        ),
        .X_kk1         ( X_kk1      ),
        .X_kk          ( X_kk       ),
        .done          ( su_done    )
    );

    // -------------------------------------------------
    // 协方差更新
    // -------------------------------------------------
    CovarianceUpdate #(
        .STATE_DIM(STATE_DIM),
        .DWIDTH   (64)
    ) u_CovUpdate (
        .clk           (clk         ),
        .rst_n         (rst_n       ),
        .K_k            (K_k      ),
        .R_k            (R_k          ),
        .P_kk1          (P_kk1  ),
        .P_kk          (P_kk        ),
        .valid_out     (cu_done     )
    );

    assign SCU_Done = cu_done;

    // -------------------------------------------------
    // 时序对齐单元
    // -------------------------------------------------
    DelayUnit #(
        .DELAY_CYCLES(2),
        .ROWS        (12),
        .COLS        (12),
        .DATA_WIDTH  (64)
    ) u_DelayX (
        .clk       ( clk    ),
        .rst_n     ( rst_n),
        .data_in   ( Xk1k),
        .data_out  ( Xkk1)
    );

    DelayUnit #(
        .DELAY_CYCLES(2),
        .ROWS        (12),
        .COLS        (1),
        .DATA_WIDTH  (64)
    ) u_DelayP (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in   (P_kk),
        .data_out  (P_k1k1)
    );



endmodule
