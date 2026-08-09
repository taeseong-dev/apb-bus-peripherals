class apb_env extends uvm_env;

	`uvm_component_utils(apb_env)

	apb_agent      apb_agt;
	gpio_agent     gpio_agt;
	apb_scoreboard sb;
	apb_coverage   cov;


	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction


	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);

	    apb_agt  = apb_agent::type_id::create("apb_agt", this);
	    gpio_agt = gpio_agent::type_id::create("gpio_agt", this);
	    sb       = apb_scoreboard::type_id::create("sb", this);
	    cov      = apb_coverage::type_id::create("cov", this);
	endfunction


	function void connect_phase(uvm_phase phase);
	    super.connect_phase(phase);

	    apb_agt.mon.ap.connect(sb.act_fifo.analysis_export);
	    apb_agt.mon.ap.connect(cov.analysis_export);

	    gpio_agt.mon.ap.connect(sb.gpio_fifo.analysis_export);
	endfunction

endclass
