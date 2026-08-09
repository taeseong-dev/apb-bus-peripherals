class apb_driver extends uvm_driver #(apb_seq_item);

	`uvm_component_utils(apb_driver)

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
	    apb_seq_item item;

	    bus_init();

	    wait(vif.rst == 0);
	    repeat(3) @(vif.apb_drv_cb);

	    forever begin
	        seq_item_port.get_next_item(item);

	        if(item.op == BUS_WRITE)
	            bus_write(item);
	        else
	            bus_read(item);

	        seq_item_port.item_done();
	    end
	endtask


	task bus_init();
	    vif.apb_drv_cb.bus_addr  <= 32'b0;
	    vif.apb_drv_cb.bus_wdata <= 32'b0;
	    vif.apb_drv_cb.bus_wreq  <= 1'b0;
	    vif.apb_drv_cb.bus_rreq  <= 1'b0;
	endtask


	task bus_write(apb_seq_item item);
	    @(vif.apb_drv_cb);

	    vif.apb_drv_cb.bus_addr  <= item.addr;
	    vif.apb_drv_cb.bus_wdata <= item.wdata;
	    vif.apb_drv_cb.bus_wreq  <= 1'b1;
	    vif.apb_drv_cb.bus_rreq  <= 1'b0;

	    @(vif.apb_drv_cb);
	    wait(vif.apb_drv_cb.bus_ready);

	    vif.apb_drv_cb.bus_wreq <= 1'b0;

	    @(vif.apb_drv_cb);
	endtask


	task bus_read(apb_seq_item item);
	    @(vif.apb_drv_cb);

	    vif.apb_drv_cb.bus_addr <= item.addr;
	    vif.apb_drv_cb.bus_wreq <= 1'b0;
	    vif.apb_drv_cb.bus_rreq <= 1'b1;

	    @(vif.apb_drv_cb);
	    wait(vif.apb_drv_cb.bus_ready);

	    item.rdata = vif.apb_drv_cb.bus_rdata;
	    vif.apb_drv_cb.bus_rreq <= 1'b0;

	    @(vif.apb_drv_cb);
	endtask

endclass
