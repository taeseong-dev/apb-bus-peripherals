import uvm_pkg::*;
`include "uvm_macros.svh"
`uvm_analysis_imp_decl(_exp)
`uvm_analysis_imp_decl(_act)

interface spi_if(input logic clk, input logic rst);


	logic			start;
	logic [07:00]	tx_data;
	logic [07:00]	rx_data;
	logic 			done;
	logic 			busy;

	logic			sclk;
	logic			mosi;
	logic			miso;
	logic			cs_n;

	logic [07:00]	slv_rx_data;


	clocking drv_cb @(posedge clk);
		default input #1step output #0;
		input done;
		input busy;
		input rx_data;

		output start;
		output tx_data;

	endclocking

	clocking mon_cb @(posedge clk);
		default input #1step;
		input done;
		input sclk;
		input cs_n;
		input mosi;
		input miso;

		input rx_data;
		input slv_rx_data;
	endclocking

endinterface

class spi_seq_item extends uvm_sequence_item;

	rand logic [07:00] tx_data;
		 
		 logic [07:00] mst_rx_data;
		 logic [07:00] slv_data;

		 logic [07:00] act_tx_data;
		 logic [07:00] act_rx_data;



	`uvm_object_utils_begin(spi_seq_item)
		`uvm_field_int(tx_data		, UVM_ALL_ON)
		`uvm_field_int(mst_rx_data	, UVM_ALL_ON)
		`uvm_field_int(act_tx_data	, UVM_ALL_ON)
		`uvm_field_int(act_rx_data	, UVM_ALL_ON)
		`uvm_field_int(slv_data		, UVM_ALL_ON)
	`uvm_object_utils_end
	

	function new(string name="spi_seq_item");
		super.new(name);
	endfunction

	function string convert2string();
		return $sformatf("tx_data=0x%02h", tx_data);
	endfunction

endclass

class spi_rand_seq extends uvm_sequence #(spi_seq_item);
	`uvm_object_utils(spi_rand_seq)

	int num_trans = 10;

	function new(string name="spi_rand_seq");
		super.new(name);
	endfunction

	task body();
		spi_seq_item item;
		repeat(num_trans) begin
			item = spi_seq_item::type_id::create("item");
			start_item(item);
			if(!item.randomize()) begin
				`uvm_fatal(get_type_name(), "spi_seq_item randomize() fail")
			end
			`uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)
			finish_item(item);
		end
	endtask

endclass

class spi_coverage extends uvm_subscriber #(spi_seq_item);
	`uvm_component_utils(spi_coverage)

    logic [7:0] cov_act_tx_data = 0;
    logic [7:0] cov_slv_data 	= 0;
    logic [7:0] cov_act_rx_data = 0;
    logic [7:0] cov_mst_rx_data = 0;

	covergroup spi_cg;
       // Master TX Data
        cp_master_tx : coverpoint cov_act_tx_data {
            bins zero  = {8'h00};
            bins ff    = {8'hFF};
            bins aa    = {8'hAA};
            bins fiftyfive = {8'h55};
            bins others = default;
        }

        // Slave RX Register
        cp_slave_rx : coverpoint cov_slv_data {
            bins zero  = {8'h00};
            bins ff    = {8'hFF};
            bins aa    = {8'hAA};
            bins fiftyfive = {8'h55};
            bins others = default;
        }

        // Slave TX (MISO)
        cp_slave_tx : coverpoint cov_act_rx_data {
            bins zero  = {8'h00};
            bins ff    = {8'hFF};
            bins aa    = {8'hAA};
            bins fiftyfive = {8'h55};
            bins others = default;
        }

        // Master RX Register
        cp_master_rx : coverpoint cov_mst_rx_data {
            bins zero  = {8'h00};
            bins ff    = {8'hFF};
            bins aa    = {8'hAA};
            bins fiftyfive = {8'h55};
            bins others = default;
        }
	endgroup


	function new(string name, uvm_component parent);
		super.new(name, parent);
		spi_cg = new();
	endfunction

	function void write(spi_seq_item item);
		cov_act_tx_data = item.act_tx_data;
		cov_slv_data 	= item.slv_data;
        cov_act_rx_data = item.act_rx_data;
        cov_mst_rx_data = item.mst_rx_data;
        spi_cg.sample();
	endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "==== Coverage Summary ====", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Master TX : %.1f%%", spi_cg.cp_master_tx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Slave RX  : %.1f%%", spi_cg.cp_slave_rx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Slave TX  : %.1f%%", spi_cg.cp_slave_tx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Master RX : %.1f%%", spi_cg.cp_master_rx.get_coverage()), UVM_LOW)
        `uvm_info(get_type_name(), "==========================", UVM_LOW)
    endfunction


endclass

class spi_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(spi_scoreboard)

	uvm_analysis_imp_exp #(spi_seq_item, spi_scoreboard) exp_imp;
	uvm_analysis_imp_act #(spi_seq_item, spi_scoreboard) act_imp;

	spi_seq_item exp_item;
	spi_seq_item act_item;

	bit [07:00] prev_slv_data = 0;
	bit			first = 1'b1;

	int seq_num = 0;


	int m_tx_pass = 0;
	int m_tx_fail = 0;
	int m_rx_pass = 0;
	int m_rx_fail = 0;

	int s_tx_pass = 0;
	int s_tx_fail = 0;
	int s_rx_pass = 0;
	int s_rx_fail = 0;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		exp_imp = new("exp_imp",this);
		act_imp = new("act_imp",this);
	endfunction

	function void write_exp(spi_seq_item t);
		exp_item = t;
	endfunction;

	function void write_act(spi_seq_item t);
		act_item = t;
		compare();
	endfunction

	function void compare();
		// random tx_data == mosi data
		if(exp_item.tx_data == act_item.act_tx_data) begin
			`uvm_info(get_type_name(), $sformatf("[Master TX] exp_tx_data == act_tx_data, MATCH, exp=0x%02h, act=0x%02h", 
													exp_item.tx_data, act_item.act_tx_data), UVM_MEDIUM);
			m_tx_pass++;	
		end		
		else begin
			`uvm_error(get_type_name(), $sformatf("[Master TX] exp_tx_data != act_tx_data, MISMATCH, exp=0x%02h, act=0x%02h", 
													exp_item.tx_data, act_item.act_tx_data));
			m_tx_fail++;			
		end
		// random tx_data == slave_rx_data
		if(exp_item.tx_data == act_item.slv_data) begin
			`uvm_info(get_type_name(), $sformatf("[Slave RX] exp_tx_data == slv_data, MATCH, exp=0x%02h, act=0x%02h", 
													exp_item.tx_data, act_item.slv_data), UVM_MEDIUM);
			s_rx_pass++;	
		end		
		else begin
			`uvm_error(get_type_name(), $sformatf("[Slave RX] exp_tx_data != slv_data, MISMATCH, exp=0x%02h, act=0x%02h", 
													exp_item.tx_data, act_item.slv_data));
			s_rx_fail++;			
		end

		if(!first) begin
			// prev tx_data == miso data
			if(prev_slv_data == act_item.act_rx_data) begin
				`uvm_info(get_type_name(), $sformatf("[Slave TX] prev_slv_data == act_rx_data, MATCH, exp=0x%02h, act=0x%02h", 
														prev_slv_data, act_item.act_rx_data), UVM_MEDIUM);
				s_tx_pass++;	
			end		
			else begin
				`uvm_error(get_type_name(), $sformatf("[Slave TX] prev_slv_data != act_rx_data, MISMATCH, exp=0x%02h, act=0x%02h", 
														prev_slv_data, act_item.act_rx_data));
				s_tx_fail++;			
			end
			// prev tx_data == master rx_data
			if(prev_slv_data == act_item.mst_rx_data) begin
				`uvm_info(get_type_name(), $sformatf("[Master RX] exp_tx_data == act_slv_data, MATCH, exp=0x%02h, act=0x%02h", 
														prev_slv_data, act_item.mst_rx_data), UVM_MEDIUM);
				m_rx_pass++;	
			end		
			else begin
				`uvm_error(get_type_name(), $sformatf("[Master RX] exp_tx_data != act_slv_data, MISMATCH, exp=0x%02h, act=0x%02h", 
														prev_slv_data, act_item.mst_rx_data));
				m_rx_fail++;			
			end
		end

		prev_slv_data = act_item.slv_data;
		first = 1'b0;
		seq_num ++;
	endfunction

	virtual function void report_phase (uvm_phase phase);

		bit overall_pass;

		super.report_phase(phase);

   		overall_pass =  
						(m_tx_fail == 0) &&
						(m_rx_fail == 0) &&
						(s_tx_fail == 0) &&
						(s_rx_fail == 0);


		`uvm_info(get_type_name(), "\n\n", UVM_LOW)
		`uvm_info(get_type_name(), "================= Scoreboard Summary ==================", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("   Test Total        : %4d", seq_num), UVM_LOW)
		`uvm_info(get_type_name(), "", UVM_LOW)
   		`uvm_info(get_type_name(), "Transaction Summary", UVM_LOW)
   		`uvm_info(get_type_name(), "******************************************************", UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("   Master TX -> MOSI        : PASS=%5d  FAIL=%4d",m_tx_pass, m_tx_fail), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("   Master TX -> Slave RX    : PASS=%5d  FAIL=%4d",s_rx_pass, s_rx_fail), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("   Slave  TX -> MISO        : PASS=%5d  FAIL=%4d",s_tx_pass, s_tx_fail), UVM_LOW)
		`uvm_info(get_type_name(), $sformatf("   Slave  TX -> Master RX   : PASS=%5d  FAIL=%4d",m_rx_pass, m_rx_fail), UVM_LOW)
   		`uvm_info(get_type_name(), "******************************************************", UVM_LOW)
    	if (overall_pass) begin
			`uvm_info(get_type_name(), 		 "Overall Result       : PASS", UVM_LOW)
		end
		else begin
			`uvm_info(get_type_name(), 		 "Overall Result       : FAIL", UVM_LOW)
		end
		`uvm_info(get_type_name(), "======================================================", UVM_LOW)

	endfunction

endclass


class spi_monitor extends uvm_monitor;
	`uvm_component_utils(spi_monitor)

	uvm_analysis_port #(spi_seq_item) ap;
	virtual spi_if vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap = new("ap", this);
		if(!uvm_config_db #(virtual spi_if)::get(this, "", "vif", vif)) begin
			`uvm_fatal(get_type_name(), "spi_if is not found in config_db");
		end
	endfunction

	task run_phase(uvm_phase phase);

		forever begin

			spi_seq_item item = spi_seq_item::type_id::create("item");
			int i;
			
			@(negedge vif.cs_n);

			item.act_tx_data = 0;
			item.act_rx_data = 0;


			for(i=0; i<8; i++) begin
				@(posedge vif.sclk);
			
				item.act_tx_data = {item.act_tx_data[6:0], vif.mosi};
				item.act_rx_data = {item.act_rx_data[6:0], vif.miso};

				@(negedge vif.sclk);
			end

			@(posedge vif.cs_n);

			@(vif.mon_cb);
			@(vif.mon_cb);
			@(vif.mon_cb);
			@(vif.mon_cb);
			@(vif.mon_cb);

			
			item.mst_rx_data = vif.mon_cb.rx_data;
			item.slv_data = vif.mon_cb.slv_rx_data;

			`uvm_info(get_type_name(), $sformatf("act_tx_data = 0x%02h, act_rx_data = 0x%02h",
													item.act_tx_data, item.act_rx_data ), UVM_HIGH)
			ap.write(item);
		end
	endtask
endclass

class spi_driver extends uvm_driver #(spi_seq_item);
	`uvm_component_utils(spi_driver)
	uvm_analysis_port #(spi_seq_item) ap;

	virtual spi_if vif;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ap = new("ap", this);
		if(!uvm_config_db#(virtual spi_if)::get(this, "", "vif", vif)) begin
			`uvm_fatal(get_type_name(), "spi interface is not found in config_db");
		end
	endfunction

	task run_phase(uvm_phase phase);
		spi_seq_item item;
		spi_seq_item exp_item;

		vif.tx_data <= 8'h00;
		vif.start <= 1'b0;

		wait(vif.rst == 0);
		repeat(3) @(vif.drv_cb);

		forever begin
			seq_item_port.get_next_item(item);

			while(vif.drv_cb.busy) @(vif.drv_cb);
			@(vif.drv_cb);
			vif.tx_data <= item.tx_data;
			vif.start <= 1'b1;

			$cast(exp_item, item.clone());

			`uvm_info(get_type_name(), "send exp item", UVM_MEDIUM)
			ap.write(exp_item);

			@(vif.drv_cb);
			vif.start <= 1'b0;
			`uvm_info(get_type_name(), $sformatf("tansmisstion start: tx_data = 0x%02h", item.tx_data), UVM_HIGH)
			@(vif.drv_cb);
			while(!vif.drv_cb.busy) @(vif.drv_cb); //waiting for busy 0 -> 1
			while(vif.drv_cb.busy) @(vif.drv_cb); //waiting for busy 1 -> 0
			`uvm_info(get_type_name(), $sformatf("tansmisstion done: tx_data = 0x%02h", item.tx_data), UVM_HIGH)

			@(vif.drv_cb);
			@(vif.drv_cb);
			@(vif.drv_cb);
			@(vif.drv_cb);
			@(vif.drv_cb);
			@(vif.drv_cb);
			@(vif.drv_cb);
			@(vif.drv_cb);
			`uvm_info(get_type_name(), $sformatf("1byte sequence done"), UVM_HIGH)

			seq_item_port.item_done();
		end

	endtask

endclass

class spi_agent extends uvm_agent;
	`uvm_component_utils(spi_agent)
	
	spi_driver drv;
	spi_monitor mon;
	uvm_sequencer#(spi_seq_item) sqr;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		drv = spi_driver::type_id::create("drv", this);
		mon = spi_monitor::type_id::create("mon", this);
		sqr = uvm_sequencer#(spi_seq_item)::type_id::create("sqr", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		drv.seq_item_port.connect(sqr.seq_item_export);
	endfunction

endclass

class spi_env extends uvm_env;
	`uvm_component_utils(spi_env)
	
	spi_agent agt;
	spi_scoreboard scb;
	spi_coverage cov;


	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		agt = spi_agent::type_id::create("agt", this);
		scb = spi_scoreboard::type_id::create("scb", this);
		cov = spi_coverage::type_id::create("cov", this);		
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		agt.drv.ap.connect(scb.exp_imp);
		agt.mon.ap.connect(scb.act_imp);
		agt.mon.ap.connect(cov.analysis_export);
	endfunction


endclass


class spi_rand_test extends uvm_test;
	`uvm_component_utils(spi_rand_test)

	spi_env env;

	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = spi_env::type_id::create("env", this);
	endfunction

	task run_phase(uvm_phase phase);
		spi_rand_seq seq;
		phase.raise_objection(this);
		seq = spi_rand_seq::type_id::create("seq");
		seq.num_trans = 1000;
		seq.start(env.agt.sqr); //sequence connected to sequencer
		phase.drop_objection(this);

	endtask


endclass


module tb_spi_uvm();

	logic clk;
	logic rst;

	logic slv_done;
	logic slv_busy;

	always #5 clk =~ clk;

	initial begin
		clk = 0;
		rst = 1;
		repeat (3) @(posedge clk);
		rst = 0;
		@(posedge clk);
	end

	spi_if vif(clk,rst);


	spi_top dut(

	.clk(clk),
	.rst(rst),
	.tx_data(vif.tx_data),
	.start(vif.start),


	.sclk(vif.sclk),
	.mosi(vif.mosi),
	.miso(vif.miso),
	.cs_n(vif.cs_n),

	.rx_data(vif.rx_data),
	.done(vif.done),
	.busy(vif.busy),

	.slv_busy(slv_busy),
	.slv_done(slv_done),
	.slv_rx_data(vif.slv_rx_data)
);


	initial begin
		uvm_config_db#(virtual spi_if)::set(null, "*", "vif", vif);
		run_test("spi_rand_test");
	end

	initial begin
		$fsdbDumpfile("novas.fsdb");
		$fsdbDumpvars(0, tb_spi_uvm, "+all");
	end
		

endmodule

