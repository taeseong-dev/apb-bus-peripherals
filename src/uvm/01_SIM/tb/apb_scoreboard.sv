class apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_scoreboard)

    uvm_tlm_analysis_fifo #(apb_seq_item)  act_fifo;
    uvm_tlm_analysis_fifo #(gpio_seq_item) gpio_fifo;


    int transaction_count;

    int apb_check_count;
    int apb_error_count;

    int bram_check_count;
    int bram_error_count;

    int gpio_check_count;
    int gpio_error_count;

    int fnd_check_count;
    int fnd_error_count;

    int uart_check_count;
    int uart_error_count;


    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        act_fifo  = new("act_fifo", this);
        gpio_fifo = new("gpio_fifo", this);

        transaction_count = 0;

        apb_check_count  = 0;
        apb_error_count  = 0;

        bram_check_count = 0;
        bram_error_count = 0;

        gpio_check_count = 0;
        gpio_error_count = 0;

        fnd_check_count  = 0;
        fnd_error_count  = 0;

        uart_check_count = 0;
        uart_error_count = 0;
    endfunction


    task run_phase(uvm_phase phase);

        apb_seq_item  item;
        gpio_seq_item gpio_item;


        // APB Master
        logic       expected_pwrite;
        logic [3:0] expected_psel;


        // BRAM
        logic [31:0] bram_model [0:1023];


        // GPIO
        logic [31:0] gpio_cntl_model  = 32'd0;
        logic [31:0] gpio_odata_model = 32'd0;

        logic [7:0] gpio_input_model = 8'd0;
        bit         gpio_input_valid = 1'b0;


        // FND
        logic [31:0] fnd_model = 32'd0;


        // UART
        logic [31:0] uart_baud_model = 32'd0;
        logic [31:0] uart_tx_model   = 32'd0;

        bit uart_rx_clear_check = 1'b0;


        // GPIO Input Monitor
        fork
            forever begin
                gpio_fifo.get(gpio_item);

                gpio_input_model = gpio_item.data;
                gpio_input_valid = 1'b1;
            end
        join_none


        forever begin

            act_fifo.get(item);

            transaction_count++;


            // PADDR check
            apb_check_count++;

            if(item.actual_paddr !== item.addr) begin
                apb_error_count++;
                `uvm_error(get_type_name(), $sformatf("PADDR MISMATCH : expected=%08h actual=%08h", item.addr, item.actual_paddr))
            end


            // PWRITE check
            expected_pwrite = (item.op == BUS_WRITE);

            apb_check_count++;

            if(item.actual_pwrite !== expected_pwrite) begin
                apb_error_count++;
                `uvm_error(get_type_name(), $sformatf("PWRITE MISMATCH : expected=%0b actual=%0b", expected_pwrite, item.actual_pwrite))
            end


            // PWDATA check
            if(item.op == BUS_WRITE) begin

                apb_check_count++;

                if(item.actual_pwdata !== item.wdata) begin
                    apb_error_count++;
                    `uvm_error(get_type_name(), $sformatf("PWDATA MISMATCH : expected=%08h actual=%08h", item.wdata, item.actual_pwdata))
                end

            end


            // PSEL check
            if(item.addr >= 32'h1000_0000 && item.addr <= 32'h1000_0FFF) begin
                expected_psel = 4'b0001;     // BRAM
            end
            else if(item.addr >= 32'h2000_0000 && item.addr <= 32'h2000_0FFF) begin
                expected_psel = 4'b0010;     // GPIO
            end
            else if(item.addr >= 32'h2000_1000 && item.addr <= 32'h2000_1FFF) begin
                expected_psel = 4'b0100;     // FND
            end
            else if(item.addr >= 32'h2000_2000 && item.addr <= 32'h2000_2FFF) begin
                expected_psel = 4'b1000;     // UART
            end
            else begin
                expected_psel = 4'b0000;
            end

            apb_check_count++;

            if(item.actual_psel !== expected_psel) begin
                apb_error_count++;
                `uvm_error(get_type_name(), $sformatf("PSEL MISMATCH : addr=%08h expected=%04b actual=%04b", item.addr, expected_psel, item.actual_psel))
            end


            // READ DATA check
            if(item.op == BUS_READ) begin

                apb_check_count++;

                if(item.actual_bus_rdata !== item.actual_prdata) begin
                    apb_error_count++;
                    `uvm_error(get_type_name(), $sformatf("READ DATA MISMATCH : PRDATA=%08h BUS_RDATA=%08h", item.actual_prdata, item.actual_bus_rdata))
                end

            end


            // Slave BRAM Write
            if(item.op == BUS_WRITE && item.actual_psel == 4'b0001) begin
                bram_model[item.addr[11:2]] = item.wdata;
            end


            // Slave BRAM Read
            if(item.op == BUS_READ && item.actual_psel == 4'b0001) begin

                bram_check_count++;

                if(item.actual_prdata !== bram_model[item.addr[11:2]]) begin
                    bram_error_count++;
                    `uvm_error(get_type_name(), $sformatf("BRAM DATA MISMATCH : addr=%08h expected=%08h actual=%08h", item.addr, bram_model[item.addr[11:2]], item.actual_prdata))
                end

            end


            // Slave GPIO Write
            if(item.op == BUS_WRITE && item.actual_psel == 4'b0010) begin

                case(item.addr[11:0])

                    12'h000: begin       // CTL
                        gpio_cntl_model = item.wdata;
                    end

                    12'h004: begin       // ODATA
                        gpio_odata_model = {16'b0, item.wdata[7:0], 8'b0};
                    end

                endcase

            end


            // Slave GPIO Read
            if(item.op == BUS_READ && item.actual_psel == 4'b0010) begin

                case(item.addr[11:0])

                    12'h000: begin       // CTL

                        gpio_check_count++;

                        if(item.actual_prdata !== gpio_cntl_model) begin
                            gpio_error_count++;
                            `uvm_error(get_type_name(), $sformatf("GPIO CTL MISMATCH : expected=%08h actual=%08h", gpio_cntl_model, item.actual_prdata))
                        end

                    end


                    12'h004: begin       // ODATA

                        gpio_check_count++;

                        if(item.actual_prdata !== gpio_odata_model) begin
                            gpio_error_count++;
                            `uvm_error(get_type_name(), $sformatf("GPIO ODATA MISMATCH : expected=%08h actual=%08h", gpio_odata_model, item.actual_prdata))
                        end

                    end


                    12'h008: begin       // IDATA

                        gpio_check_count++;

                        if(!gpio_input_valid) begin
                            gpio_error_count++;
                            `uvm_error(get_type_name(), "GPIO IDATA Read before GPIO input")
                        end
                        else if(item.actual_prdata[7:0] !== gpio_input_model) begin
                            gpio_error_count++;
                            `uvm_error(get_type_name(), $sformatf("GPIO IDATA MISMATCH : expected=%02h actual=%02h", gpio_input_model, item.actual_prdata[7:0]))
                        end

                    end

                endcase

            end


            // Slave FND Write
            if(item.op == BUS_WRITE && item.actual_psel == 4'b0100) begin
                fnd_model = item.wdata;
            end


            // Slave FND Read
            if(item.op == BUS_READ && item.actual_psel == 4'b0100) begin

                fnd_check_count++;

                if(item.actual_prdata !== fnd_model) begin
                    fnd_error_count++;
                    `uvm_error(get_type_name(), $sformatf("FND MISMATCH : expected=%08h actual=%08h", fnd_model, item.actual_prdata))
                end

            end


            // Slave UART Write
            if(item.op == BUS_WRITE && item.actual_psel == 4'b1000) begin

                case(item.addr[11:0])

                    12'h004: begin       // BAUD
                        uart_baud_model = item.wdata;
                    end

                    12'h00C: begin       // TXDATA
                        uart_tx_model = item.wdata;
                    end

                endcase

            end


            // Slave UART Read
            if(item.op == BUS_READ && item.actual_psel == 4'b1000) begin

                case(item.addr[11:0])

                    12'h004: begin       // BAUD

                        uart_check_count++;

                        if(item.actual_prdata !== uart_baud_model) begin
                            uart_error_count++;
                            `uvm_error(get_type_name(), $sformatf("UART BAUD MISMATCH : expected=%08h actual=%08h", uart_baud_model, item.actual_prdata))
                        end

                    end


                    12'h008: begin       // SR

                        if(uart_rx_clear_check) begin

                            uart_check_count++;

                            if(item.actual_prdata[1]) begin
                                uart_error_count++;
                                `uvm_error(get_type_name(), "UART RX READY was not cleared")
                            end

                            uart_rx_clear_check = 1'b0;

                        end

                    end


                    12'h00C: begin       // TXDATA

                        uart_check_count++;

                        if(item.actual_prdata !== uart_tx_model) begin
                            uart_error_count++;
                            `uvm_error(get_type_name(), $sformatf("UART TXDATA MISMATCH : expected=%08h actual=%08h", uart_tx_model, item.actual_prdata))
                        end

                    end


                    12'h010: begin       // RXDATA

                        uart_check_count++;

                        if(item.actual_prdata !== {24'b0, uart_tx_model[7:0]}) begin
                            uart_error_count++;
                            `uvm_error(get_type_name(), $sformatf("UART RXDATA MISMATCH : expected=%08h actual=%08h", {24'b0, uart_tx_model[7:0]}, item.actual_prdata))
                        end

                        uart_rx_clear_check = 1'b1;

                    end

                endcase

            end

        end

    endtask

	function void report_phase(uvm_phase phase);
	
	    int    total_check_count;
	    int    total_error_count;
	    int    total_pass_count;
	    string report;
	    string result;
	
	    super.report_phase(phase);
	
	    total_check_count = apb_check_count  + 
							bram_check_count + 
							gpio_check_count + 
							fnd_check_count  +
							uart_check_count;

	    total_error_count = apb_error_count  + 
							bram_error_count + 
							gpio_error_count + 
							fnd_error_count  + 
							uart_error_count;

	    total_pass_count  = total_check_count - total_error_count;
	
	    if(total_check_count > 0 && total_error_count == 0)
	        result = "PASS";
	    else
	        result = "FAIL";
	
	    report = {
	        "\n============================================\n",
	        " APB SCOREBOARD RESULT\n",
	        "--------------------------------------------\n",
	        $sformatf(" Transactions : %0d\n", transaction_count),
	        "\n"
	    };
	
	    if(apb_check_count > 0) begin
	        report = {report, $sformatf(" APB Master : %s (%0d / %0d)\n", (apb_error_count == 0) ? "PASS" : "FAIL", apb_check_count - apb_error_count, apb_check_count)};
	    end
	
	    if(bram_check_count > 0) begin
	        report = {report, $sformatf(" BRAM       : %s (%0d / %0d)\n", (bram_error_count == 0) ? "PASS" : "FAIL", bram_check_count - bram_error_count, bram_check_count)};
	    end
	
	    if(gpio_check_count > 0) begin
	        report = {report, $sformatf(" GPIO       : %s (%0d / %0d)\n", (gpio_error_count == 0) ? "PASS" : "FAIL", gpio_check_count - gpio_error_count, gpio_check_count)};
	    end
	
	    if(fnd_check_count > 0) begin
	        report = {report, $sformatf(" FND        : %s (%0d / %0d)\n", (fnd_error_count == 0) ? "PASS" : "FAIL", fnd_check_count - fnd_error_count, fnd_check_count)};
	    end
	
	    if(uart_check_count > 0) begin
	        report = {report, $sformatf(" UART       : %s (%0d / %0d)\n", (uart_error_count == 0) ? "PASS" : "FAIL", uart_check_count - uart_error_count, uart_check_count)};
	    end
	
	    report = {
	        report,
	        "--------------------------------------------\n",
	        $sformatf(" Total Checks : %0d\n", total_check_count),
	        $sformatf(" Total Passed : %0d\n", total_pass_count),
	        $sformatf(" Total Errors : %0d\n", total_error_count),
	        $sformatf(" Result       : %s\n", result),
	        "============================================"
	    };
	
	    `uvm_info(get_type_name(), report, UVM_LOW)
	
	endfunction

endclass
