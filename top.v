/********************************************************************************************/
/* RVCore (RISC-V Core Processor) vXXXX-XX-XXx        since  2018-08-07  ArchLab. TokyoTech */
/********************************************************************************************/
`include "config.vh"
/********************************************************************************************/
`ifndef VERILATOR
module top();
    reg CLK = 0;
    initial forever #50 CLK = ~CLK;
    reg w_rst = 1;
    initial         #250 w_rst = 0;
`else
module top(CLK, w_rst);
    input reg CLK, w_rst;
`endif

`ifndef VERIFY
    `ifndef PIPELINE
        `ifndef NO_SERIAL
    initial begin
        $write("Run %s\n", `MEMFILE);
        $write("Initializing : ");
    end
    always@(posedge CLK) begin
        if(memaddr % (`MEM_SIZE/4/10) == 0 && initwe && (bytecnt==0)) begin
            $write(".");
            `ifndef VERILATOR
            $fflush();
            `endif
        end
        if(initdone & initwe) $write("\n--------------------------------------------------\n");
    end
        `else
    initial begin
        $write("Run %s\n", `MEMFILE);
        $write("Initialized.");
        $write("\n--------------------------------------------------\n");
    end
        `endif
        `ifndef VERILATOR
            `ifdef PROGRESS
    always @(posedge CLK) if((r_ICNT%10000)==1) begin $write("."); $fflush(); end
            `endif
        `endif
    `endif
`endif

    wire        w_btnu;
    wire        w_btnd;
    wire [15:0] w_led;
    wire [6:0]  w_sg;
    wire [7:0]  w_an;
    wire        w_rxd;
    wire        w_txd;
`ifndef ARTYA7
    main m(CLK, w_btnu, w_btnd, w_led, w_sg, w_an, w_rxd, w_txd);
`else
    main m(CLK, w_rxd, w_txd);
`endif

    /****************************************************************************************/

    reg [31:0] mem[0:`MEM_SIZE/4-1];
    initial $readmemh(`MEMFILE, mem);

    reg  [1:0]  bytecnt  = 0;
    reg  [31:0] initdata = 0;
    reg  [31:0] memaddr  = 0;
    reg         initwe   = 0;
    always@(posedge CLK) begin
        bytecnt  <= (w_rst) ? 0 : (tx_ready & !initwe & !initdone) ? bytecnt+1 : bytecnt;
        initdata <= (w_rst) ? 0 : (tx_ready & !initwe & !initdone) ? ((bytecnt==0) ? mem[memaddr] : {8'h0,initdata[31:8]}) : initdata;
        memaddr  <= (w_rst) ? 0 : (tx_ready & !initwe & !initdone & bytecnt==0) ? memaddr+1 : memaddr;
        initwe   <= (w_rst) ? 0 : (tx_ready & !initwe & !initdone) ? 1 : 0;
    end
    wire initdone = (memaddr >= `MEM_SIZE/4) & (bytecnt==0);

    wire init_txd, tx_ready;
    UartTx UartTx_init(CLK, !w_rst, initdata[7:0], initwe, init_txd, tx_ready);

    assign w_rxd = init_txd;

    /****************************************************************************************/
    
    reg [63: 0] r_TCNT = 0; // elapsed clock cycles
    reg [63: 0] r_ICNT = 0; // the number of executed valid instructions
    reg [63: 0] r_cnt_bphit = 0;
    reg [63: 0] r_cnt_bpmis = 0;
    reg [63: 0] r_SCNT  = 0; // the number of 2-cycle load-use stalls
    reg [63: 0] r_SCNT2 = 0; // the number of 1-cycle load-use stalls
`ifdef VEXRV
    reg [63: 0] r_SHCNT  = 0; // the number of stalls by shift inst
    reg [63: 0] r_SHCNT2 = 0; // the number of shift inst
    wire writeBack_branchinst
      = (m.v.p.writeBack_INSTRUCTION[6:2]==5'b11011) | 
        (m.v.p.writeBack_INSTRUCTION[6:2]==5'b11001) |
        (m.v.p.writeBack_INSTRUCTION[6:2]==5'b11000);
    wire memory_loadinst = (m.v.p.memory_INSTRUCTION[6:2]==5'b00000);
    wire writeBack_loadinst = (m.v.p.writeBack_INSTRUCTION[6:2]==5'b00000);
    wire memory_shiftinst
      = (m.v.p.memory_INSTRUCTION[6:2]==5'b01100 & m.v.p.memory_INSTRUCTION[14:12]==3'b001) | 
        (m.v.p.memory_INSTRUCTION[6:2]==5'b01100 & m.v.p.memory_INSTRUCTION[14:12]==3'b101) |
        (m.v.p.memory_INSTRUCTION[6:2]==5'b00100 & m.v.p.memory_INSTRUCTION[14:12]==3'b001) |
        (m.v.p.memory_INSTRUCTION[6:2]==5'b00100 & m.v.p.memory_INSTRUCTION[14:12]==3'b101);
`endif
    
    always@(posedge CLK) begin
        r_TCNT <= (m.core_rst) ? 0 : (~m.poweroff)                   ? r_TCNT+1 : r_TCNT;
`ifndef VEXRV
        r_ICNT <= (m.core_rst) ? 0 : (m.p.ExMa_v & ~m.sim_poweroff)  ? r_ICNT+1 : r_ICNT;
        r_SCNT <= (m.core_rst) ? 0 : (m.p.w_stall & ~m.sim_poweroff) ? r_SCNT+1 : r_SCNT;
        if(~m.core_rst & m.p.ExMa_v & m.p.ExMa_b & ~m.p.w_bmis & ~m.sim_poweroff) r_cnt_bphit <= r_cnt_bphit + 1;
        if(~m.core_rst & m.p.ExMa_v & m.p.ExMa_b &  m.p.w_bmis & ~m.sim_poweroff) r_cnt_bpmis <= r_cnt_bpmis + 1;
`else
        r_ICNT <= (m.core_rst) ? 0 : (m.v.p.memory_arbitration_isValid & ~m.sim_poweroff)  ? r_ICNT+1 : r_ICNT;
        r_SCNT  <= (m.core_rst) ? 0 : (m.v.p.memory_arbitration_isValid & ~m.v.p.execute_arbitration_isValid & m.v.p.IBusSimplePlugin_injector_decodeInput_valid & memory_loadinst & ~m.sim_poweroff) ? r_SCNT+1 : r_SCNT;
        r_SCNT2 <= (m.core_rst) ? 0 : (m.v.p.writeBack_arbitration_isValid & m.v.p.memory_arbitration_isValid & ~m.v.p.execute_arbitration_isValid & m.v.p.IBusSimplePlugin_injector_decodeInput_valid & writeBack_loadinst & ~m.sim_poweroff) ? r_SCNT2+1 : r_SCNT2;
        if(~m.core_rst & m.v.p.writeBack_arbitration_isValid & m.v.p.memory_arbitration_isValid & writeBack_branchinst & ~m.sim_poweroff) r_cnt_bphit <= r_cnt_bphit + 1;
        if(~m.core_rst & m.v.p.writeBack_arbitration_isValid & ~m.v.p.memory_arbitration_isValid & ~m.v.p.execute_arbitration_isValid & ~m.v.p.IBusSimplePlugin_injector_decodeInput_valid & writeBack_branchinst & ~m.sim_poweroff) r_cnt_bpmis <= r_cnt_bpmis + 1;
        r_SHCNT  <= (m.core_rst) ? 0 : (m.v.p.memory_arbitration_isValid & ~m.v.p.execute_arbitration_isValid & m.v.p.IBusSimplePlugin_injector_decodeInput_valid & memory_shiftinst & ~m.sim_poweroff) ? r_SHCNT+1 : r_SHCNT;
        r_SHCNT2 <= (m.core_rst) ? 0 : (m.v.p.memory_arbitration_isValid & memory_shiftinst & ~m.sim_poweroff) ? r_SHCNT2+1 : r_SHCNT2;
`endif
    end

    always@(posedge CLK) begin
        if (m.r_halt) begin $write("HALT detect!\n"); $finish(); end
    end

`ifndef VERIFY
    always@(negedge CLK) begin
      if(m.sim_poweroff & (m.queue_num==0) & m.tx_ready & !m.uartwe) begin
    `ifndef PIPELINE
          $write("\n");
          $write("== elapsed clock cycles              : %16d\n", r_TCNT);
          $write("== valid instructions executed       : %16d\n", r_ICNT);
          $write("== IPC                               :            0.%3d\n", r_ICNT * 1000 / r_TCNT);
          $write("== branch prediction hit             : %16d\n", r_cnt_bphit);
          $write("== branch prediction miss            : %16d\n", r_cnt_bpmis);
          $write("== branch prediction total           : %16d\n", r_cnt_bphit + r_cnt_bpmis);
          $write("== branch prediction hit rate        :            0.%3d\n", r_cnt_bphit * 1000 / (r_cnt_bphit + r_cnt_bpmis));
        `ifdef VEXRV
          $write("== the num of 2-cycle load-use stall : %16d\n", r_SCNT);
          $write("== the num of 1-cycle load-use stall : %16d\n", r_SCNT2);
          $write("== the num of stalls by shift        : %16d\n", r_SHCNT);
          $write("== the num of shift inst             : %16d\n", r_SHCNT2);
          $write("== estimated clock cycles            : %16d\n", r_ICNT + r_SCNT * 2 + r_SCNT2 * 1 + r_cnt_bpmis * 3 + r_SHCNT * 1);
        `else
          $write("== the num of load-use stall         : %16d\n", r_SCNT);
          $write("== estimated clock cycles            : %16d\n", r_ICNT + r_SCNT * 1 + r_cnt_bpmis * 3);
        `endif
          $write("== r_cnt                             :         %08x\n", m.r_cnt);
          $write("== r_rout                            :         %08x\n", m.r_rout);
    `endif
          $finish();
      end
    end
`endif

    reg [31:0] r_tc = 1;
`ifndef VEXRV
    always @(posedge CLK) if(m.p.RST_X && m.p.MaWb_v) r_tc <= r_tc + 1;
`else
    always @(posedge CLK) if(!m.v.p.reset && m.v.p.writeBack_arbitration_isValid) r_tc <= r_tc + 1;
`endif

`ifndef VERIFY
    `ifndef PIPELINE
        `ifndef DEBUG
    always@(posedge CLK) begin
//      if(m.uartwe) $write("%c", m.uartdata);
        if(uartwe) $write("%c", uartdata);
        if(m.queue_num == `QUEUE_SIZE-1) begin
            $write("\nqueue num error\n");
            $finish();
        end
    end
    
    wire [7:0] uartdata;
    wire       uartwe;
    serialc serc (CLK, !w_rst, w_txd, uartdata, uartwe);
        `else
    always@(posedge CLK) begin
        if(m.debug_we) $write("%08x %08x\n", m.r_cnt, m.r_rout);
    end
        `endif

        `ifndef VERILATOR
            `ifdef TIMEOUT
    initial begin
        #`TIMEOUT   $write("Simulation Time out...\n");
                    $finish();
    end
            `endif
        `endif
    `else
        `ifndef VEXRV
    wire [31:0] w_r_pc    = m.p.r_pc;
    wire [31:0] w_IfId_pc = m.p.IfId_pc;
    wire [31:0] w_IdEx_pc = m.p.IdEx_pc;
    wire [31:0] w_ExMa_pc = m.p.ExMa_pc;
    wire [31:0] w_MaWb_pc = m.p.MaWb_pc;
    always @(negedge CLK) begin
        if(m.p.RST_X & !m.sim_poweroff) begin
            $write("%x: %10d: ", m.p.RST_X, r_tc);
            $write("%08x ", w_r_pc);
            if(m.p.IfId_v) $write("%08x ", w_IfId_pc); else $write("-------- ");
            if(m.p.IdEx_v) $write("%08x ", w_IdEx_pc); else $write("-------- ");
            if(m.p.ExMa_v) $write("%08x ", w_ExMa_pc); else $write("-------- ");
            if(m.p.MaWb_v) $write("%08x ", w_MaWb_pc); else $write("-------- ");
            $write("\n");
        end
    end
        `else
    always @(negedge CLK) begin
        if(!m.v.p.reset & !m.sim_poweroff) begin
            $write("%x: %10d: ", !m.v.p.reset, r_tc);
            $write("%08x ", m.v.p.IBusSimplePlugin_fetchPc_pcReg);
            if(m.v.p.IBusSimplePlugin_injector_decodeInput_valid) $write("%08x ", m.v.p.IBusSimplePlugin_injector_decodeInput_payload_pc);
            else $write("-------- ");
            if(m.v.p.execute_arbitration_isValid)                 $write("%08x ", m.v.p.decode_to_execute_PC);
            else $write("-------- ");
            if(m.v.p.memory_arbitration_isValid)                  $write("%08x ", m.v.p.execute_to_memory_PC);
            else $write("-------- ");
            if(m.v.p.writeBack_arbitration_isValid)               $write("%08x ", m.v.p.memory_to_writeBack_PC);
            else $write("-------- ");
            $write("\n");
        end
    end
        `endif
    `endif
`else
    integer fd;
    initial begin
        fd = $fopen("verify.txt", "w");
    end

    wire [31:0] w_MaWb_pc = m.p.MaWb_pc;
    integer i, j;
    always @(posedge CLK) begin
        if(`TR_BEGIN <= r_tc && r_tc <= `TR_END) begin
            if(m.p.RST_X && m.p.MaWb_v) begin
                $fwrite(fd, "%08d %08x %08x\n", r_tc, w_MaWb_pc, m.p.MaWb_ir);
                for (i = 0; i < 4; i = i + 1) begin
                    for (j = 0; j < 8; j = j + 1) begin
                        $fwrite(fd, "%08x", ((i*8+j == m.p.MaWb_rd) && (i*8+j != 0)) ? 
                               m.p.MaWb_rslt : m.p.regs0.mem[i * 8 + j]);
                        $fwrite(fd, "%s", (j != 7 ? " " : "\n"));
                    end
                end
            end
        end
        if(`TR_FIN <= r_tc) begin
            $write("finish by FIN\n");
            $fclose(fd);
            $finish();
        end
    end
    always@(negedge CLK) begin
        if(m.sim_poweroff & (m.queue_num==0) & m.tx_ready & !m.uartwe) begin
            $write("finish by POWEROFF\n");
            $fclose(fd);
            $finish();
        end
    end
`endif

endmodule
/********************************************************************************************/
