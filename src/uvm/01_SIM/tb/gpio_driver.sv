class gpio_driver extends uvm_driver #(gpio_seq_item);

	`uvm_component_utils(gpio_driver)

	virtual apb_if vif;

	function new(string name, uvm_component parent);
	    super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
	    super.build_phase(phase);

	    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin
	        `uvm_fatal(get_type_name(), "apb_if is not found in config_db")
		end
	endfunction

	task run_phase(uvm_phase phase);
	    gpio_seq_item item;

	    gpio_init();

	    wait(vif.rst == 0);
	    repeat(3) @(vif.gpio_drv_cb);

	    forever begin
	        seq_item_port.get_next_item(item);

	        drive_gpio(item);

	        seq_item_port.item_done();
	    end
	endtask

	task gpio_init();
	    vif.gpio_drv_cb.gpio_in_data <= 8'b0;
	    vif.gpio_drv_cb.gpio_in_en   <= 1'b0;
	endtask

	task drive_gpio(gpio_seq_item item);
	    @(vif.gpio_drv_cb);

	    vif.gpio_drv_cb.gpio_in_data <= item.data;
	    vif.gpio_drv_cb.gpio_in_en   <= 1'b1;
	endtask

endclass
