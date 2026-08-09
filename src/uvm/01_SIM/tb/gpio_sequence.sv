class gpio_sequence extends uvm_sequence #(gpio_seq_item);

	`uvm_object_utils(gpio_sequence)

	function new(string name = "gpio_sequence");
	    super.new(name);
	endfunction

	task body();
	    gpio_seq_item req;

	    req = gpio_seq_item::type_id::create("req");

	    start_item(req);

	    if(!req.randomize()) begin
	        `uvm_fatal(get_type_name(), "Randomize failed")
	    end

	    finish_item(req);
	endtask

endclass
