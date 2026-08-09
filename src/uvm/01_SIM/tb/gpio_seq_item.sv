class gpio_seq_item extends uvm_sequence_item;

	rand logic [7:0] data;

	`uvm_object_utils_begin(gpio_seq_item)
	    `uvm_field_int(data, UVM_DEFAULT)
	`uvm_object_utils_end

	function new(string name = "gpio_seq_item");
	    super.new(name);
	endfunction

endclass
