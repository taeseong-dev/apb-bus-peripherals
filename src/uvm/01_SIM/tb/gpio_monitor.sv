class gpio_monitor extends uvm_monitor;

	`uvm_component_utils(gpio_monitor)

	uvm_analysis_port #(gpio_seq_item) ap;

	virtual apb_if vif;

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);

	    ap = new("ap", this);

	    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
	        `uvm_fatal(get_type_name(), "apb_if is not found in config_db")
	    end
	endfunction

	task run_phase(uvm_phase phase);
	    gpio_seq_item item;
	    logic [7:0] prev_data;

	    wait(vif.rst == 0);

	    prev_data = vif.gpio_mon_cb.GPIO[7:0];

	    forever begin
	        @(vif.gpio_mon_cb);

	        if(vif.gpio_mon_cb.GPIO[7:0] !== prev_data) begin

	            if(!$isunknown(vif.gpio_mon_cb.GPIO[7:0])) begin
	                item = gpio_seq_item::type_id::create("item");

	                item.data = vif.gpio_mon_cb.GPIO[7:0];

	                ap.write(item);
	            end

	            prev_data = vif.gpio_mon_cb.GPIO[7:0];
	        end
	    end
	endtask

endclass
