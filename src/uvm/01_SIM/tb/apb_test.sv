class apb_base_test extends uvm_test;

	`uvm_component_utils(apb_base_test)

	apb_env env;

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);

	    env = apb_env::type_id::create("env", this);
	endfunction

endclass


class apb_test extends apb_base_test;

	`uvm_component_utils(apb_test)

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	task run_phase(uvm_phase phase);
	    apb_sequence seq;

	    phase.raise_objection(this);

	    seq = apb_sequence::type_id::create("seq");
	    seq.start(env.apb_agt.sqr);

	    phase.drop_objection(this);
	endtask

endclass


class apb_random_test extends apb_base_test;

	`uvm_component_utils(apb_random_test)

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	task run_phase(uvm_phase phase);
	    apb_random_sequence seq;

	    phase.raise_objection(this);

	    seq = apb_random_sequence::type_id::create("seq");
	    seq.start(env.apb_agt.sqr);

	    phase.drop_objection(this);
	endtask

endclass


class uart_test extends apb_base_test;

	`uvm_component_utils(uart_test)

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	task run_phase(uvm_phase phase);
	    uart_sequence seq;

	    phase.raise_objection(this);

	    seq = uart_sequence::type_id::create("seq");
	    seq.start(env.apb_agt.sqr);

	    phase.drop_objection(this);
	endtask

endclass


class gpio_test extends apb_base_test;

	`uvm_component_utils(gpio_test)

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	task run_phase(uvm_phase phase);
	    gpio_config_sequence config_seq;
	    gpio_sequence        gpio_seq;
	    gpio_idata_sequence  idata_seq;

	    phase.raise_objection(this);

	    // GPIO CTL
	    config_seq = gpio_config_sequence::type_id::create("config_seq");
	    config_seq.start(env.apb_agt.sqr);

	    repeat(10) begin
	        gpio_seq = gpio_sequence::type_id::create("gpio_seq");
	        gpio_seq.start(env.gpio_agt.sqr);

	        idata_seq = gpio_idata_sequence::type_id::create("idata_seq");
	        idata_seq.start(env.apb_agt.sqr);
	    end

	    phase.drop_objection(this);
	endtask

endclass
