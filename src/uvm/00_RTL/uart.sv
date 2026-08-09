`timescale 1ns / 1ps

module uart(

    input           clk,
    input           rst,

    input           [31:00] i_paddr,
    input           [31:00] i_pdata,
    input                   i_penable,
    input                   i_pwrite,
    input                   i_psel,

    input                   i_rx,

    output                  o_tx,

    output  logic   [31:00] o_prdata,
    output  logic           o_pready

    );


    localparam [11:00]  cntl_addr  = 12'h000;
    localparam [11:00]  baud_addr  = 12'h004;
    localparam [11:00]  sr_addr  = 12'h008;
    localparam [11:00]  tx_addr  = 12'h00C;
    localparam [11:00]  rx_addr  = 12'h010;

    logic   [31:00] cntl_reg;
    logic   [31:00] baud_reg;
    logic   [31:00] tx_reg;

    logic   [07:00] rx_data;

    logic   tx_busy;
    logic   rx_done;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            cntl_reg <= 32'd0;
        end
        else if(i_penable && i_psel && i_pwrite && (i_paddr[11:00] == cntl_addr)) begin
            cntl_reg <= i_pdata;
        end
        else begin
            cntl_reg <= 32'd0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            baud_reg <= 32'd0;
        end
        else if(i_penable && i_psel && i_pwrite && (i_paddr[11:00] == baud_addr)) begin
            baud_reg <= i_pdata;
        end
        else begin
            baud_reg <= baud_reg;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tx_reg <= 32'd0;
        end
        else if(i_penable && i_psel && i_pwrite && (i_paddr[11:00] == tx_addr)) begin
            tx_reg <= i_pdata;
        end
        else begin
            tx_reg <= tx_reg;
        end
    end

    logic rx_ready;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            rx_ready <= 1'b0;
        end
        else begin
            if(i_penable && i_psel && !i_pwrite && (i_paddr[11:00] == rx_addr)) begin
                rx_ready <= 1'b0;
            end
            else if(rx_done) begin
                rx_ready <= 1'b1;
            end
        end
    end

    assign o_pready = i_penable && i_psel;
    assign o_prdata = (i_paddr[11:00] == cntl_addr) ? cntl_reg :
					  (i_paddr[11:00] == baud_addr) ? baud_reg :
					  (i_paddr[11:00] == tx_addr)   ? tx_reg :
					  (i_paddr[11:00] == rx_addr)   ? {24'b0, rx_data} : 
                      (i_paddr[11:00] == sr_addr)   ? {30'b0, rx_ready, tx_busy} : 0;
    logic w_tick;

    baud_tick U_BUAD_TICK(

    .clk(clk),
    .rst(rst),
    .i_buadrate(baud_reg[01:00]),

    .b_tick(w_tick)

    );

    uart_tx U_TX(

    .clk(clk),
    .rst(rst),
    .tx_start(cntl_reg[0]),
    .b_tick(w_tick),
    .tx_data(tx_reg[7:0]),

    .tx_done(),
    .tx_busy(tx_busy),
    .uart_tx(o_tx)

    );

    uart_rx U_RX(

    .clk(clk),
    .rst(rst),
    .rx(i_rx),
    .b_tick(w_tick),

    .rx_data(rx_data),
    .rx_done(rx_done)

);
endmodule

