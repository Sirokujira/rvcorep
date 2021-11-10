/********************************************************************************************/
/* VexRV (RISC-V Core Processor) v2019-10-29c         since  2018-08-07  ArchLab. TokyoTech */
/********************************************************************************************/
`include "config.vh"
/********************************************************************************************/
module VexRV(CLK, RST_X, r_rout, r_halt, I_ADDR, D_ADDR, I_IN, D_IN, D_OUT, D_WE);
    input  wire        CLK, RST_X;
    output reg  [31:0] r_rout;
    output reg         r_halt;
    output wire [31:0] I_ADDR, D_ADDR;
    input  wire [31:0] I_IN, D_IN;
    output wire [31:0] D_OUT;
    output wire  [3:0] D_WE;

    wire        D_WEv;
    wire [1:0]  D_SIZE; // 00: 1byte, 01: 2byte, 10: 4byte, 11: ??

    wire w_iBus_cmd_valid;
    reg  r_iBus_cmd_valid = 0;
    always@(posedge CLK) r_iBus_cmd_valid <= w_iBus_cmd_valid;
    wire w_dBus_cmd_valid;
    reg  r_dBus_cmd_valid = 0;
    always@(posedge CLK) r_dBus_cmd_valid <= w_dBus_cmd_valid;

    wire [3:0] dmem_mask = 
               (D_SIZE == 2'b00) ? (4'b0001 << D_ADDR[1:0]) : 
               (D_SIZE == 2'b01) ? (4'b0011 << D_ADDR[1:0]) :
               (D_SIZE == 2'b10) ? 4'b1111 : 4'b0000;
    assign D_WE = {4{D_WEv}} & dmem_mask & {4{w_dBus_cmd_valid}};

    VexRiscv
      p(// module VexRiscv (
        w_iBus_cmd_valid,//       output  iBus_cmd_valid,
        1'b1,//       input   iBus_cmd_ready,
        I_ADDR,//       output [31:0] iBus_cmd_payload_pc,
        r_iBus_cmd_valid,//       input   iBus_rsp_valid,
        1'b0,//       input   iBus_rsp_payload_error,
        I_IN,//       input  [31:0] iBus_rsp_payload_inst,
        w_dBus_cmd_valid,//       output  dBus_cmd_valid,
        1'b1,//       input   dBus_cmd_ready,
        D_WEv,//       output  dBus_cmd_payload_wr,
        D_ADDR,//       output [31:0] dBus_cmd_payload_address,
        D_OUT,//       output [31:0] dBus_cmd_payload_data,
        D_SIZE,//       output [1:0] dBus_cmd_payload_size,
        r_dBus_cmd_valid,//       input   dBus_rsp_ready,
        1'b0,//       input   dBus_rsp_error,
        D_IN,//       input  [31:0] dBus_rsp_data,
        CLK,//       input   clk,
        !RST_X);//       input   reset);

    initial r_halt = 0;
    initial r_rout = 0;
    always @(posedge CLK) r_rout <= (w_iBus_cmd_valid) ? I_ADDR : r_rout;

//    When using iverilog, the branch prediction table must be explicitly initialized.
//    integer i;
//    initial begin for (i=0; i<512; i=i+1) p.IBusSimplePlugin_predictor_history[i]=55'b0; end

endmodule

/********************************************************************************************/
