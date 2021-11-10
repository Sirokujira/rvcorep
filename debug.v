/**************************************************************************************************/
`include "config.vh"
/**************************************************************************************************/
`define DATA 64
`define STR  `DATA*2+8*2+25*17

`define CTRL 25'b0111111111111111111111111
/**************************************************************************************************/
module UartTx2(CLK, RST_X, w_we, w_data, r_txd, r_ready);
    input  wire             CLK, RST_X;
    input  wire             w_we;
    input  wire [`DATA-1:0] w_data;
    output reg              r_txd, r_ready;

    reg    [`STR:0] r_cmd;
    reg      [9:0]  r_waitnum;
    reg      [31:0] r_cnt;
    reg  [`STR-1:0] r_dataout;
    reg             r_we;

    always @(posedge CLK) begin
        r_dataout <= {8'h0a,  // LF
                    `CTRL,
                    ascii(w_data[3:0]),
                    `CTRL,
                    ascii(w_data[7:4]),
                    `CTRL,
                    ascii(w_data[11:8]),
                    `CTRL,
                    ascii(w_data[15:12]),
                    `CTRL,
                    ascii(w_data[19:16]),
                    `CTRL,
                    ascii(w_data[23:20]),
                    `CTRL,
                    ascii(w_data[27:24]),
                    `CTRL,
                    ascii(w_data[31:28]),
                    `CTRL,
                    8'h20,  // space
                    `CTRL,
                    ascii(w_data[35:32]),
                    `CTRL,
                    ascii(w_data[39:36]),
                    `CTRL,
                    ascii(w_data[43:40]),
                    `CTRL,
                    ascii(w_data[47:44]),
                    `CTRL,
                    ascii(w_data[51:48]),
                    `CTRL,
                    ascii(w_data[55:52]),
                    `CTRL,
                    ascii(w_data[59:56]),
                    `CTRL,
                    ascii(w_data[63:60])};
        r_we     <= w_we;
    end

    always @(posedge CLK) begin
        if(!RST_X) begin
            r_txd       <= 1'b1;
            r_ready     <= 1'b1;
            r_cmd       <= {(`STR+1){1'b1}};
            r_waitnum   <= 0;
            r_cnt       <= 0;
        end else if( r_ready ) begin
            r_txd       <= 1'b1;
            r_waitnum   <= 0;
            if( r_we )begin
                r_ready <= 1'b0;
                r_cmd   <= {r_dataout, 1'b0};
                r_cnt   <= `STR+2;
            end
        end else if( r_waitnum >= `SERIAL_WCNT ) begin
            r_txd       <= r_cmd[0];
            r_ready     <= (r_cnt == 1);
            r_cmd       <= {1'b1, r_cmd[`STR:1]};
            r_waitnum   <= 1;
            r_cnt       <= r_cnt - 1;
        end else begin
            r_waitnum   <= r_waitnum + 1;
        end
    end
    
    function [7:0] ascii;
        input [3:0] in;
        begin
            case(in)
                0: ascii = 8'h30;
                1: ascii = 8'h31;
                2: ascii = 8'h32;
                3: ascii = 8'h33;
                4: ascii = 8'h34;
                5: ascii = 8'h35;
                6: ascii = 8'h36;
                7: ascii = 8'h37;
                8: ascii = 8'h38;
                9: ascii = 8'h39;
                10:ascii = 8'h41;
                11:ascii = 8'h42;
                12:ascii = 8'h43;
                13:ascii = 8'h44;
                14:ascii = 8'h45;
                15:ascii = 8'h46;
                default: ascii = 8'h58;//X
            endcase
        end
    endfunction
endmodule
/**************************************************************************************************/
module debug_data(CLK, RST_X, w_btn, w_txd, debug_we, debug_data, w_mtime, w_rec_done);
    input  wire        CLK, RST_X;
    input  wire        w_btn;
    output wire        w_txd;
    input  wire        debug_we;
    input  wire [31:0] debug_data;
    input  wire [31:0] w_mtime;
    output wire        w_rec_done;
        
    reg  [63:0] buff [0:`DEBUG_SIZE-1];
    reg  [$clog2(`DEBUG_SIZE)-1:0] r_waddr = 0;
    reg  [$clog2(`DEBUG_SIZE)-1:0] r_raddr = 0;
     
    reg  [19:0] r_state     = 0;
    reg         r_uartwe    = 0;
    reg  [63:0] r_uartdata  = 0;

    reg         r_rec_done  = 0;

    always @(posedge CLK) begin
       if (debug_we) begin 
           buff[r_waddr]    <= {w_mtime,debug_data};
           r_waddr          <= r_waddr + 1;
        end
        r_uartdata          <= buff[r_raddr];   
    end
    
    always @(posedge CLK) if (w_btn) r_rec_done <= 1;
    assign w_rec_done = r_rec_done;
    
    always@(posedge CLK) begin
        if (r_rec_done) begin
           if(r_state==0) begin
              r_uartwe <= 1;
              r_raddr  <= r_raddr + 1;
              r_state  <= 1;
           end
           else if(r_state!=0) begin
             r_uartwe  <= 0;
             r_state   <= (r_raddr==r_waddr) ? r_state : r_state + 1;
           end
        end
    end
    
    wire w_tx_ready;
    wire w_busy = !w_tx_ready;
    UartTx2 UartTx20(CLK, RST_X, r_uartwe, r_uartdata, w_txd, w_tx_ready);
endmodule
/**************************************************************************************************/
