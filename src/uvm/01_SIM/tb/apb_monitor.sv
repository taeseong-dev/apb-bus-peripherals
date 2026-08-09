class apb_monitor extends uvm_monitor;

	`uvm_component_utils(apb_monitor)

	uvm_analysis_port #(apb_seq_item) ap;

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

	    wait(vif.rst == 0);
	    repeat(3) @(vif.apb_mon_cb);

	    forever begin
	        apb_seq_item item;

	        item = apb_seq_item::type_id::create("item");

	        get_request(item);
	        get_apb_transfer(item);

	        ap.write(item);

	        while(vif.apb_mon_cb.bus_wreq || vif.apb_mon_cb.bus_rreq) begin
	            @(vif.apb_mon_cb);
	        end
	    end

	endtask


	task get_request(apb_seq_item item);

	    wait(vif.apb_mon_cb.bus_wreq || vif.apb_mon_cb.bus_rreq);

	    item.addr  = vif.apb_mon_cb.bus_addr;
	    item.wdata = vif.apb_mon_cb.bus_wdata;

	    if(vif.apb_mon_cb.bus_wreq)
	        item.op = BUS_WRITE;
	    else
	        item.op = BUS_READ;

	endtask


	task get_apb_transfer(apb_seq_item item);

	    // SETUP 시작 대기
	    wait(vif.apb_mon_cb.psel0 ||
	         vif.apb_mon_cb.psel1 ||
	         vif.apb_mon_cb.psel2 ||
	         vif.apb_mon_cb.psel3);

	    item.actual_paddr  = vif.apb_mon_cb.paddr;
	    item.actual_pwdata = vif.apb_mon_cb.pwdata;
	    item.actual_pwrite = vif.apb_mon_cb.pwrite;

	    item.actual_psel = {
	        vif.apb_mon_cb.psel3,
	        vif.apb_mon_cb.psel2,
	        vif.apb_mon_cb.psel1,
	        vif.apb_mon_cb.psel0
	    };

	    // ACCESS wait
	    wait(vif.apb_mon_cb.penable);


	    // Transaction done wait
	    wait(vif.apb_mon_cb.bus_ready);

	    item.actual_bus_rdata = vif.apb_mon_cb.bus_rdata;

	    case(item.actual_psel)
	        4'b0001: item.actual_prdata = vif.apb_mon_cb.prdata0;
	        4'b0010: item.actual_prdata = vif.apb_mon_cb.prdata1;
	        4'b0100: item.actual_prdata = vif.apb_mon_cb.prdata2;
	        4'b1000: item.actual_prdata = vif.apb_mon_cb.prdata3;
	        default: item.actual_prdata = '0;
	    endcase

	endtask

endclass
