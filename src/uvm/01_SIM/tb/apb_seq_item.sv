typedef enum bit {
    BUS_READ,
    BUS_WRITE
} bus_op_e;


class apb_seq_item extends uvm_sequence_item;

    rand bus_op_e    op;
    rand logic [31:0] addr;
    rand logic [31:0] wdata;

         logic [31:0] rdata;
	
	// monitor, from apb master output
	logic [31:0] actual_paddr;
	logic [31:0] actual_pwdata;
	logic		 actual_pwrite;
	logic [3:0]  actual_psel;

	// apb transaction result
	logic [31:0] actual_prdata;
	logic [31:0] actual_bus_rdata;

    `uvm_object_utils_begin(apb_seq_item)
        `uvm_field_enum(bus_op_e, op, 		UVM_DEFAULT)
        `uvm_field_int (addr, 				UVM_DEFAULT)
        `uvm_field_int (wdata, 				UVM_DEFAULT)
        `uvm_field_int (rdata, 				UVM_DEFAULT)

        `uvm_field_int(actual_paddr,      	UVM_DEFAULT)
        `uvm_field_int(actual_pwdata,    	UVM_DEFAULT)
        `uvm_field_int(actual_pwrite,     	UVM_DEFAULT)
        `uvm_field_int(actual_psel,       	UVM_DEFAULT)
        `uvm_field_int(actual_prdata,     	UVM_DEFAULT)
        `uvm_field_int(actual_bus_rdata,  	UVM_DEFAULT)
    `uvm_object_utils_end


	function new(string name = "apb_seq_item");
	    super.new(name);
	endfunction

    constraint c_addr_align {
        addr[1:0] == 2'b00;
    }

endclass
