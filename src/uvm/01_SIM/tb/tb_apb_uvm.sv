`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"


`include "apb_if.sv"
`include "apb_seq_item.sv"
`include "gpio_seq_item.sv"
`include "apb_sequence.sv"
`include "gpio_sequence.sv"
`include "apb_driver.sv"
`include "gpio_driver.sv"
`include "apb_monitor.sv"
`include "gpio_monitor.sv"
`include "apb_agent.sv"
`include "gpio_agent.sv"
`include "apb_scoreboard.sv"
`include "apb_coverage.sv"
`include "apb_env.sv"
`include "apb_test.sv"

module tb_apb_uvm();

	logic clk;
	logic rst;

	always #10 clk =~ clk;

	initial begin
		clk = 0;
		rst = 1;
		repeat (3) @(posedge clk);
		rst = 0;
		@(posedge clk);
	end

	apb_if vif(clk,rst);

    apb_master U_APB_MASTER(

    // BUS Global signal
    .clk(clk),
    .rst(rst),

    // SoC Internal signal with CPU
    .i_addr		(vif.bus_addr),
    .i_wdata	(vif.bus_wdata),
    .i_wreq		(vif.bus_wreq),
    .i_rreq		(vif.bus_rreq),

    .o_rdata	(vif.bus_rdata),
    .o_ready	(vif.bus_ready),

    // APB Interface signal
    .o_paddr	(vif.paddr),
    .o_pdata	(vif.pwdata),
    .o_penable	(vif.penable),
    .o_pwrite	(vif.pwrite),
    .o_psel0	(vif.psel0),
    .o_psel1	(vif.psel1),
    .o_psel2	(vif.psel2),
    .o_psel3	(vif.psel3),

    .i_prdata0	(vif.prdata0),
    .i_prdata1	(vif.prdata1),
    .i_prdata2	(vif.prdata2),
    .i_prdata3	(vif.prdata3),

    .i_pready0	(vif.pready0),
    .i_pready1	(vif.pready1),
    .i_pready2	(vif.pready2),
    .i_pready3	(vif.pready3)

    );

    bram U_BRAM(
    .clk		(clk),
    .i_paddr	(vif.paddr),
    .i_pdata	(vif.pwdata),
    .i_penable	(vif.penable),
    .i_pwrite	(vif.pwrite),
    .i_psel		(vif.psel0),

    .o_prdata	(vif.prdata0),
    .o_pready	(vif.pready0)
    );
 	
	apb_gpio U_APB_GPIO(

    .clk		(clk),
    .rst		(rst),

    .i_paddr	(vif.paddr),
    .i_pdata	(vif.pwdata),
    .i_penable	(vif.penable),
    .i_pwrite	(vif.pwrite),
    .i_psel		(vif.psel1),

    .o_prdata	(vif.prdata1),
    .o_pready	(vif.pready1),
    .gpio		(vif.GPIO)

    );

    fnd U_FND(
    
    .clk		(clk),
    .rst		(rst),

    .i_paddr	(vif.paddr),
    .i_pdata	(vif.pwdata),
    .i_penable	(vif.penable),
    .i_pwrite	(vif.pwrite),
    .i_psel		(vif.psel2),

    .o_prdata	(vif.prdata2),
    .o_pready	(vif.pready2),
    .o_fnd_data	(vif.fnd_data),
    .o_fnd_digit(vif.fnd_digit)

    );

    uart U_UART_APB(

    .clk		(clk),
    .rst		(rst),

    .i_paddr	(vif.paddr),
    .i_pdata	(vif.pwdata),
    .i_penable	(vif.penable),
    .i_pwrite	(vif.pwrite),
    .i_psel		(vif.psel3),
    .i_rx		(vif.o_tx),

    .o_tx		(vif.o_tx),
    .o_prdata	(vif.prdata3),
    .o_pready	(vif.pready3)

    );




	initial begin
		uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
		run_test();
	end

	initial begin
		$fsdbDumpfile("novas.fsdb");
		$fsdbDumpvars(0, tb_apb_uvm, "+all");
	end
		

endmodule

