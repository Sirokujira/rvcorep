/********************************************************************************************/
/* RVCore (RISC-V Core Processor) v2019-10-31a        since  2018-08-07  ArchLab. TokyoTech */
/********************************************************************************************/
`include "config.vh"
/********************************************************************************************/
`default_nettype none
/********************************************************************************************/
`ifndef ARTYA7
module main(CLK, w_btnu, w_btnd, r_led, r_sg, r_an, w_rxd, r_txd);
`else
module main(CLK, w_rxd, r_txd);
`endif
    input  wire        CLK;
`ifndef ARTYA7
    input  wire        w_btnu, w_btnd;
    output reg  [15:0] r_led = 0;
    output reg   [6:0] r_sg = 0;
    output reg   [7:0] r_an = 0;
`endif
    input  wire        w_rxd;
    output reg         r_txd = 1;

`ifdef NO_IP
    wire w_locked = 1;
    wire w_clk = CLK;
`else
    wire w_clk, w_locked;
    clk_wiz_0 clk_wiz (w_clk, 0, w_locked, CLK);
`endif

    reg r_rst = 1; // reset signal
    always @(posedge w_clk) r_rst <= (!w_locked);

    reg core_rst = 1;
`ifdef NO_SERIAL
    always @(posedge w_clk) core_rst <= r_rst;
`else
    always @(posedge w_clk) core_rst <= (r_rst | !initdone);
`endif

    /****************************************************************************************/
    reg r_rxd_t1=1,  r_rxd_t2=1;
    always@(posedge w_clk) r_rxd_t1 <= w_rxd;
    always@(posedge w_clk) r_rxd_t2 <= r_rxd_t1;
    
    /****************************************************************************************/

`ifndef NO_SERIAL
    wire [31:0] w_initdata;
    wire [31:0] w_initaddr;
    wire        w_initwe;
    wire        w_initdone;
    PLOADER ploader(w_clk, !r_rst, r_rxd_t2, w_initaddr, w_initdata, w_initwe, w_initdone);

    reg  [31:0] initdata = 0;
    reg  [31:0] initaddr = 0;
    reg  [3:0]  initwe   = 0;
    reg         initdone = 0;
    always@(posedge w_clk) begin
        initdata <= (r_rst) ? 0 : (w_initwe) ? w_initdata   : 0;
        initaddr <= (r_rst) ? 0 : (initwe)   ? initaddr + 4 : initaddr;
        initwe   <= (r_rst) ? 0 : {4{w_initwe}};
        initdone <= (r_rst) ? 0 : w_initdone;
    end
`else
    wire [31:0] initdata = 0;
    wire [31:0] initaddr = 0;
    wire [3:0]  initwe   = 0;
    wire        initdone = 0;
`endif

    /****************************************************************************************/

`ifndef ARTYA7
`ifdef DEBUG
    wire debug_txd;

    reg  debug_we = 0;
    always@(posedge w_clk) debug_we <= (!core_rst & !poweroff & (r_cnt >= `DEBUG_START) & (r_cnt <= `DEBUG_STOP)) ? 1 : 0;

    wire w_rec_done;
    debug_data debug_rout(w_clk, !core_rst, w_btnd, debug_txd, debug_we, r_rout, r_cnt, w_rec_done);
`endif
`endif

    /****************************************************************************************/
    wire        w_halt;
    wire [31:0] w_rout, I_DATA, I_ADDR, D_DATA, WD_DATA, D_ADDR;
    wire [3:0]  D_WE;

`ifndef VEXRV
    RVCore p(w_clk, !core_rst, w_rout, w_halt, I_ADDR, D_ADDR, I_DATA, D_DATA, WD_DATA, D_WE);
`else
    VexRV v(w_clk, !core_rst, w_rout, w_halt, I_ADDR, D_ADDR, I_DATA, D_DATA, WD_DATA, D_WE);
`endif
    wire [31:0] tmpdata;
    m_IMEM#(32,`MEM_SIZE/4) imem(w_clk, initwe[0], initaddr[$clog2(`MEM_SIZE)-1:2], I_ADDR[$clog2(`MEM_SIZE)-1:2], initdata, I_DATA);
    m_DMEM#(32,`MEM_SIZE/4) dmem(w_clk, core_rst, initwe, initaddr[$clog2(`MEM_SIZE)-1:2], initdata, tmpdata, w_clk, !core_rst, D_WE, D_ADDR[$clog2(`MEM_SIZE)-1:2], WD_DATA, D_DATA);

    reg        r_halt = 0;
    reg [31:0] r_rout = 0;
    always @(posedge w_clk) begin
        r_halt <= w_halt;
        r_rout <= w_rout;
    end
    /****************************************************************************************/
`ifndef ARTYA7
    reg [15:0] r_led_t1=0,r_led_t2=0;
    reg [6:0]  r_sg_t1 =0,r_sg_t2 =0;
    reg [7:0]  r_an_t1 =0,r_an_t2 =0;

    reg r_btnu=0, r_btnu_t1=0;
    reg r_btnd=0, r_btnd_t1=0;
    always @(posedge w_clk) begin
        {r_btnu_t1, r_btnd_t1} <= {w_btnu, w_btnd};
        {r_btnu, r_btnd} <= {r_btnu_t1, r_btnd_t1};
    end
`endif
    
    reg [31:0] r_cnt = 0;
    always @(posedge w_clk) r_cnt <= (core_rst) ? 0 : (~r_halt & ~poweroff) ? r_cnt+1 : r_cnt;

`ifndef ARTYA7
    wire [31:0] w_data = (r_btnu) ? r_cnt : r_rout;
    always @(posedge w_clk) r_led_t1 <= (r_btnd) ? w_data[31:16] : w_data[15:0];

    wire [6:0] w_sg;
    wire [7:0] w_an;
    m_7segcon m_7segcon(w_clk, w_data, w_sg, w_an);
    always @(posedge w_clk) r_sg_t1 <= w_sg;
    always @(posedge w_clk) r_an_t1 <= w_an;
    

    always @(posedge w_clk) {r_led_t2, r_sg_t2, r_an_t2} <= {r_led_t1, r_sg_t1, r_an_t1};
    always @(posedge w_clk) {r_led, r_sg, r_an} <= {r_led_t2, r_sg_t2, r_an_t2};
`endif
    
    /****************************************************************************************/

    reg        r_D_ADDR  = 0; // Note!!
    reg        r_D_WE    = 0; // Note!!
    reg [31:0] r_WD_DATA = 0;
    always@(posedge w_clk) begin
        r_D_ADDR  <= D_ADDR[15] & D_ADDR[30];
        r_D_WE    <= D_WE[0];
        r_WD_DATA <= WD_DATA;
    end

    reg [7:0]  tohost_char=0;
    reg        tohost_we=0;
    reg [31:0] tohost_data=0;
    reg [1:0]  tohost_cmd=0;
    always@(posedge w_clk) begin
        tohost_we   <= (r_D_ADDR && (r_D_WE));
        tohost_data <= r_WD_DATA;
        tohost_char <= (tohost_we) ? tohost_data[7:0] : 0;
        tohost_cmd  <= (tohost_we) ? tohost_data[17:16] : 0;
    end

    reg poweroff = 0;
    always@(posedge w_clk) poweroff <= (tohost_cmd==2) ? 1 : poweroff;
    wire sim_poweroff = poweroff | (tohost_cmd==2) | (tohost_we & (tohost_cmd==2));

    /****************************************************************************************/

    reg [7:0]  squeue[0:`QUEUE_SIZE-1];
    integer i;
    initial begin for(i=0; i<`QUEUE_SIZE; i=i+1) squeue[i]=8'h0; end

    reg  [$clog2(`QUEUE_SIZE)-1:0] queue_head = 0;
    reg  [$clog2(`QUEUE_SIZE)-1:0] queue_num  = 0;
    wire [$clog2(`QUEUE_SIZE)-1:0] queue_addr = queue_head+queue_num;
    wire printchar = (tohost_cmd==1);
    always@(posedge w_clk) begin
        if(printchar) squeue[queue_addr] <= tohost_char;
        queue_head <= (!printchar & tx_ready & (queue_num > 0) & !uartwe) ? queue_head + 1 : queue_head;
        queue_num <= (printchar) ? queue_num + 1 : (tx_ready & (queue_num > 0) & !uartwe) ? queue_num - 1 : queue_num;
    end

    reg [7:0] uartdata = 0;
    reg       uartwe   = 0;
    always@(posedge w_clk) begin
        uartdata <= (!printchar & tx_ready & (queue_num > 0) & !uartwe) ? squeue[queue_head] : 0;
        uartwe   <= (!printchar & tx_ready & (queue_num > 0) & !uartwe) ? 1                  : 0;
    end
    
`ifdef DEBUG
    always@(posedge w_clk) r_txd <= (w_rec_done) ? debug_txd : w_txd;
`else
    always@(posedge w_clk) r_txd <= w_txd;
`endif

    wire w_txd;
    wire tx_ready;
    UartTx UartTx0(w_clk, !core_rst, uartdata, uartwe, w_txd, tx_ready);

endmodule

/********************************************************************************************/
module m_7segled (w_in, r_led);
    input  wire [3:0] w_in;
    output reg  [6:0] r_led;
    always @(*) begin
        case (w_in)
        4'h0  : r_led = 7'b1111110;
        4'h1  : r_led = 7'b0110000;
        4'h2  : r_led = 7'b1101101;
        4'h3  : r_led = 7'b1111001;
        4'h4  : r_led = 7'b0110011;
        4'h5  : r_led = 7'b1011011;
        4'h6  : r_led = 7'b1011111;
        4'h7  : r_led = 7'b1110000;
        4'h8  : r_led = 7'b1111111;
        4'h9  : r_led = 7'b1111011;
        4'ha  : r_led = 7'b1110111;
        4'hb  : r_led = 7'b0011111;
        4'hc  : r_led = 7'b1001110;
        4'hd  : r_led = 7'b0111101;
        4'he  : r_led = 7'b1001111;
        4'hf  : r_led = 7'b1000111;
        default:r_led = 7'b0000000;
        endcase
    end
endmodule

/********************************************************************************************/
module m_7segcon (w_clk, w_din, r_sg, r_an);
    input  wire w_clk;
    input  wire [31:0] w_din;
    output reg [6:0] r_sg;  // cathode segments
    output reg [7:0] r_an;  // common anode

    reg [31:0] r_val   = 0;
    reg [31:0] r_cnt   = 0;
    reg  [3:0] r_in    = 0;
    reg  [2:0] r_digit = 0;
    always@(posedge w_clk) r_val <= w_din;

    always@(posedge w_clk) begin
        r_cnt <= (r_cnt>=(`DELAY7SEG-1)) ? 0 : r_cnt + 1;
        if(r_cnt==0) begin
            r_digit <= r_digit+ 1;
            if      (r_digit==0) begin r_an <= 8'b11111110; r_in <= r_val[3:0];   end
            else if (r_digit==1) begin r_an <= 8'b11111101; r_in <= r_val[7:4];   end
            else if (r_digit==2) begin r_an <= 8'b11111011; r_in <= r_val[11:8];  end
            else if (r_digit==3) begin r_an <= 8'b11110111; r_in <= r_val[15:12]; end
            else if (r_digit==4) begin r_an <= 8'b11101111; r_in <= r_val[19:16]; end
            else if (r_digit==5) begin r_an <= 8'b11011111; r_in <= r_val[23:20]; end
            else if (r_digit==6) begin r_an <= 8'b10111111; r_in <= r_val[27:24]; end
            else                 begin r_an <= 8'b01111111; r_in <= r_val[31:28]; end
        end
    end
    wire [6:0] w_segments;
    m_7segled m_7segled (r_in, w_segments);
    always@(posedge w_clk) r_sg <= ~w_segments;
endmodule
/********************************************************************************************/
`default_nettype wire
/********************************************************************************************/
