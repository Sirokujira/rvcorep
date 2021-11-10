/*****************************************************************************/
/**** MikuRV-SP (Mini Kuroda/RISC-V) since 2018-08-07  ArchLab. TokyoTech ****/
/**** config file v0.01                                                   ****/
/*****************************************************************************/
//`define ARTYA7

/*****************************************************************************/
// use verilator as verilog simulator
//`define VERILATOR
// default net type
//`default_nettype none
// run vexriscv core
//`define VEXRV
// run processor not using clock IP
//`define NO_IP
// run processor not initializing by serial data (using readmemh)
//`define NO_SERIAL
// display the progress of program execution
//`define PROGRESS
// display the pipeline chart
//`define PIPELINE
/*****************************************************************************/
//`define D_SIMPLE_ALU   /* use simple ALU using case structure */
//`define D_SIMPLE_DMOUT /* use simple align and mask unit for DMEM */
//`define D_SIMPLE_BTB   /* use single cycle BTB instead of two cycle version */
/*****************************************************************************/
// init file
`ifndef MEMFILE
    `define MEMFILE "test/test.mem"
    //`define MEMFILE "dhrystone.mem"
`endif
/*****************************************************************************/
// MEMORY (Byte)
`ifndef MEM_SIZE
    `define MEM_SIZE 1024*4   // 4KB
    //`define MEM_SIZE 1024*8   // 8KB
    //`define MEM_SIZE 1024*16  // 16KB
    //`define MEM_SIZE 1024*32  // 32KB
`endif
/*****************************************************************************/
// TOHOST_ADDR
`define TOHOST_ADDR 32'h40008000
// command for application mode using tohost
`define CMD_PRINT_CHAR 1
`define CMD_POWER_OFF  2
/*****************************************************************************/
// About nop instruction
`define NOP_IR  32'h00000013
`define NOP_OP  7'b0010011
`define NOP_PC  32'hffffffff
/*****************************************************************************/
// start PC
`define START_PC 32'h00000000
/*****************************************************************************/
// time out
//`define TIMEOUT    1000000000
// 7seg led
`define DELAY7SEG  200000 // 200000 for 100MHz, 100000 for 50MHz
/*****************************************************************************/
//`define TR_BEGIN 0
//`define TR_END   1000000
//`define TR_FIN   1000100
/*****************************************************************************/
// uart queue size
`define QUEUE_SIZE 512
/*****************************************************************************/
/* Debug Definition                                                          */
/*****************************************************************************/
// DEBUG_SIZE >= DEBUG_STOP - DEBUG_START + 1
//`define DEBUG
`define DEBUG_SIZE  1024
`define DEBUG_START 1
`define DEBUG_STOP  1024
//`define VERIFY
/*****************************************************************************/
/* Clock Interval Definition                                                 */
/*****************************************************************************/
// b = baud rate (in Mbps)
// f = frequency of the clk for the MIPS core (in MHz)
// SERIAL_WCNT = f/b
// e.g. b = y, f = 5*x -> SERIAL_WCNT = 5*x/y = 5*x/y = 20, y = x/4
// 1M baud UART wait count
`ifndef SERIAL_WCNT
    `define SERIAL_WCNT  20
`endif
/*****************************************************************************/
