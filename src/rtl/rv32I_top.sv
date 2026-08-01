`timescale 1ns / 1ps

module rv32I_top (
    input clk,
    input rst,
    input   i_rx,

    output  o_tx,
    output  [07:00] o_fnd_data,
    output  [03:00] o_fnd_digit,
    inout   [15:00] GPIO
);

    logic   clk_50MHz; 

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            clk_50MHz <= 1'b0;
        end
        else begin
            clk_50MHz <= ~clk_50MHz;
        end
    end

    logic [2:0] o_funct3;
    logic [31:0] instr_addr, instr_data, bus_addr, bus_wdata, bus_rdata;
    logic        bus_wreq, bus_rreq, bus_ready;

    logic [31:0] paddr, pwdata;
    logic        penable, pwrite;
    logic        psel0, psel1, psel2, psel3;
    logic        pready0, pready1, pready2, pready3;
    logic [31:0] prdata0, prdata1, prdata2, prdata3;

    instruction_mem U_INSTRUTION_MEM (.*);

    rv32i_cpu U_RV32I (
        .*,
        .clk(clk_50MHz),
        .o_funct3(o_funct3)
    );
    apb_master U_APB_MASTER(

    // BUS Global signal
    .clk(clk_50MHz),
    .rst(rst),

    // SoC Internal signal with CPU
    .i_addr(bus_addr),
    .i_wdata(bus_wdata),
    .i_wreq(bus_wreq),
    .i_rreq(bus_rreq),

    .o_rdata(bus_rdata),
    .o_ready(bus_ready),

    // APB Interface signal
    .o_paddr(paddr),
    .o_pdata(pwdata),
    .o_penable(penable),
    .o_pwrite(pwrite),
    .o_psel0(psel0),
    .o_psel1(psel1),
    .o_psel2(psel2),
    .o_psel3(psel3),

    .i_prdata0(prdata0),
    .i_prdata1(prdata1),
    .i_prdata2(prdata2),
    .i_prdata3(prdata3),

    .i_pready0(pready0),
    .i_pready1(pready1),
    .i_pready2(pready2),
    .i_pready3(pready3)

    );

    bram U_BRAM(
    .clk(clk_50MHz),
    .i_paddr(paddr),
    .i_pdata(pwdata),
    .i_penable(penable),
    .i_pwrite(pwrite),
    .i_psel(psel0),
    .o_prdata(prdata0),
    .o_pready(pready0)

    );

    apb_gpio U_APB_GPIO(

    .clk(clk_50MHz),
    .rst(rst),

    .i_paddr(paddr),
    .i_pdata(pwdata),
    .i_penable(penable),
    .i_pwrite(pwrite),
    .i_psel(psel1),


    .o_prdata(prdata1),
    .o_pready(pready1),
    .gpio(GPIO)

    );

    fnd U_FND(
    
    .clk(clk_50MHz),
    .rst(rst),

    .i_paddr(paddr),
    .i_pdata(pwdata),
    .i_penable(penable),
    .i_pwrite(pwrite),
    .i_psel(psel2),

    .o_prdata(prdata2),
    .o_pready(pready2),
    .o_fnd_data(o_fnd_data),
    .o_fnd_digit(o_fnd_digit)

    );

    uart U_UART_APB(

    .clk(clk_50MHz),
    .rst(rst),

    .i_paddr(paddr),
    .i_pdata(pwdata),
    .i_penable(penable),
    .i_pwrite(pwrite),
    .i_psel(psel3),

    .i_rx(i_rx),

    .o_tx(o_tx),

    .o_prdata(prdata3),
    .o_pready(pready3)

    );



endmodule
