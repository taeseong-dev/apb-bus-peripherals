class apb_base_sequence extends uvm_sequence #(apb_seq_item);

	`uvm_object_utils(apb_base_sequence)

	function new(string name = "apb_base_sequence");
	    super.new(name);
	endfunction

	task do_write(input logic [31:0] addr, input logic [31:0] wdata);
	    apb_seq_item req;

	    req = apb_seq_item::type_id::create("req");

	    start_item(req);
	    req.op    = BUS_WRITE;
	    req.addr  = addr;
	    req.wdata = wdata;
	    finish_item(req);
	endtask

	task do_read(input logic [31:0] addr, output logic [31:0] rdata);
	    apb_seq_item req;

	    req = apb_seq_item::type_id::create("req");

	    start_item(req);
	    req.op   = BUS_READ;
	    req.addr = addr;
	    finish_item(req);

	    rdata = req.rdata;
	endtask

endclass


class apb_sequence extends apb_base_sequence;

	`uvm_object_utils(apb_sequence)

	function new(string name = "apb_sequence");
	    super.new(name);
	endfunction

	task body();
	    logic [31:0] rdata;

	    // BRAM
	    do_write(32'h1000_0000, 32'h1234_5678);
	    do_read (32'h1000_0000, rdata);

	    // GPIO CTL
	    do_write(32'h2000_0000, 32'h0000_FF00);
	    do_read (32'h2000_0000, rdata);

	    // GPIO ODATA
	    do_write(32'h2000_0004, 32'h0000_0055);
	    do_read (32'h2000_0004, rdata);

	    // FND
	    do_write(32'h2000_1000, 32'h0000_1234);
	    do_read (32'h2000_1000, rdata);

	    // UART BAUD
	    do_write(32'h2000_2004, 32'h0000_0002);
	    do_read (32'h2000_2004, rdata);

	    // UART TXDATA
	    do_write(32'h2000_200C, 32'h0000_0055);
	    do_read (32'h2000_200C, rdata);
	endtask

endclass


class apb_random_sequence extends apb_base_sequence;

	`uvm_object_utils(apb_random_sequence)

	function new(string name = "apb_random_sequence");
	    super.new(name);
	endfunction

	task body();
	    logic [31:0] addr;
	    logic [31:0] data;
	    logic [31:0] rdata;

	    // BRAM Random
	    repeat(100) begin
	        addr = 32'h1000_0000 + ($urandom_range(0, 1023) << 2);
	        data = $urandom;

	        do_write(addr, data);
	        do_read(addr, rdata);
	    end

	    // GPIO Random
	    repeat(100) begin
	        data = $urandom_range(0, 16'hffff);
	        do_write(32'h2000_0000, data);
	        do_read(32'h2000_0000, rdata);

	        data = $urandom_range(0, 8'hff);
	        do_write(32'h2000_0004, data);
	        do_read(32'h2000_0004, rdata);
	    end

	    // FND Random
	    repeat(100) begin
	        data = $urandom_range(0, 16'hffff);

	        do_write(32'h2000_1000, data);
	        do_read(32'h2000_1000, rdata);
	    end

	    // UART Random
	    repeat(100) begin

	        // BAUD
	        data = $urandom_range(0, 2);
	        do_write(32'h2000_2004, data);
	        do_read(32'h2000_2004, rdata);

	        // TXDATA
	        data = $urandom_range(0, 8'hff);
	        do_write(32'h2000_200C, data);
	        do_read(32'h2000_200C, rdata);

	    end
	endtask

endclass


class uart_sequence extends apb_base_sequence;

	`uvm_object_utils(uart_sequence)

	function new(string name = "uart_sequence");
	    super.new(name);
	endfunction

	task body();
	    logic [31:0] baud;
	    logic [31:0] tx_data;
	    logic [31:0] rdata;

	    repeat(10) begin

	        // BAUD
	        baud = $urandom_range(0, 2);
	        do_write(32'h2000_2004, baud);
	        do_read (32'h2000_2004, rdata);

	        // TXDATA
	        tx_data = $urandom_range(0, 8'hff);
	        do_write(32'h2000_200C, tx_data);
	        do_read (32'h2000_200C, rdata);

	        // TX START
	        do_write(32'h2000_2000, 32'h0000_0001);

	        // tx_busy = 1 Wait
	        do begin
	            do_read(32'h2000_2008, rdata);
	        end while(!rdata[0]);

	        // tx_busy = 0 Wait
	        do begin
	            do_read(32'h2000_2008, rdata);
	        end while(rdata[0]);

	        // rx_ready = 1 Wait
	        do begin
	            do_read(32'h2000_2008, rdata);
	        end while(!rdata[1]);

	        // RXDATA
	        do_read(32'h2000_2010, rdata);

	        // rx_ready = 0 Check
	        do_read(32'h2000_2008, rdata);

	    end
	endtask

endclass


class gpio_idata_sequence extends apb_base_sequence;

	`uvm_object_utils(gpio_idata_sequence)

	function new(string name = "gpio_idata_sequence");
	    super.new(name);
	endfunction

	task body();
	    logic [31:0] rdata;

	    do_read(32'h2000_0008, rdata);
	endtask

endclass


class gpio_config_sequence extends apb_base_sequence;

	`uvm_object_utils(gpio_config_sequence)

	function new(string name = "gpio_config_sequence");
	    super.new(name);
	endfunction

	task body();
	    do_write(32'h2000_0000, 32'h0000_FF00);
	endtask

endclass
