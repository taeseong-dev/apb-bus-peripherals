interface apb_if (
    input logic clk,
    input logic rst
);

    // CPU(UVM Driver) <-> APB Master
    logic [31:0] bus_addr;
    logic [31:0] bus_wdata;
    logic [31:0] bus_rdata;
    logic        bus_wreq;
    logic        bus_rreq;
    logic        bus_ready;


    // APB Master <-> Peripheral
    logic [31:0] paddr;
    logic [31:0] pwdata;
    logic        penable;
    logic        pwrite;

    logic        psel0;
    logic        psel1;
    logic        psel2;
    logic        psel3;

    logic [31:0] prdata0;
    logic [31:0] prdata1;
    logic [31:0] prdata2;
    logic [31:0] prdata3;

    logic        pready0;
    logic        pready1;
    logic        pready2;
    logic        pready3;


    // GPIO
	
    tri   [15:0] GPIO;

	logic [7:0] gpio_in_data;
	logic       gpio_in_en;

	assign GPIO[7:0] = gpio_in_en ? gpio_in_data : 8'hzz;
	
    // FND
	
    logic [7:0]  fnd_data;
    logic [3:0]  fnd_digit;

    // UART
    logic        o_tx;

    // Driver Clocking Block
	
    clocking apb_drv_cb @(posedge clk);
        default input #1step output #0;

        output bus_addr;
        output bus_wdata;
        output bus_wreq;
        output bus_rreq;

        input  bus_rdata;
        input  bus_ready;

    endclocking

    // Monitor Clocking Block
	
    clocking apb_mon_cb @(posedge clk);
        default input #1step;

        // CPU Side
        input bus_addr;
        input bus_wdata;
        input bus_wreq;
        input bus_rreq;
        input bus_rdata;
        input bus_ready;

        // APB Side
        input paddr;
        input pwdata;
        input penable;
        input pwrite;

        input psel0;
        input psel1;
        input psel2;
        input psel3;

        input prdata0;
        input prdata1;
        input prdata2;
        input prdata3;

        input pready0;
        input pready1;
        input pready2;
        input pready3;

    endclocking




	// GPIO
	clocking gpio_drv_cb @(posedge clk);
    	default input #1step output #0;
    	output gpio_in_data;
    	output gpio_in_en;
	endclocking

	clocking gpio_mon_cb @(posedge clk);
    	default input #1step;
    	input GPIO;
	endclocking


endinterface
