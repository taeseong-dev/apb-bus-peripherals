class apb_coverage extends uvm_subscriber #(apb_seq_item);

    `uvm_component_utils(apb_coverage)

    bus_op_e    cov_op;
    logic [3:0] cov_psel;

    int transaction_count;

    int read_count;
    int write_count;

    int bram_count;
    int gpio_count;
    int fnd_count;
    int uart_count;

    int bram_read_count;
    int bram_write_count;
    int gpio_read_count;
    int gpio_write_count;
    int fnd_read_count;
    int fnd_write_count;
    int uart_read_count;
    int uart_write_count;


    covergroup cg_apb;

        cp_op : coverpoint cov_op {
            bins read  = {BUS_READ};
            bins write = {BUS_WRITE};
        }

        cp_psel : coverpoint cov_psel {
            bins bram = {4'b0001};
            bins gpio = {4'b0010};
            bins fnd  = {4'b0100};
            bins uart = {4'b1000};
        }

        op_x_slave : cross cp_op, cp_psel;

    endgroup


    function new(string name, uvm_component parent);
        super.new(name, parent);

        cg_apb = new();

        transaction_count = 0;

        read_count  = 0;
        write_count = 0;

        bram_count = 0;
        gpio_count = 0;
        fnd_count  = 0;
        uart_count = 0;

        bram_read_count  = 0;
        bram_write_count = 0;
        gpio_read_count  = 0;
        gpio_write_count = 0;
        fnd_read_count   = 0;
        fnd_write_count  = 0;
        uart_read_count  = 0;
        uart_write_count = 0;
    endfunction


    function void write(apb_seq_item item);

        cov_op   = item.op;
        cov_psel = item.actual_psel;

        cg_apb.sample();

        transaction_count++;

        if(item.op == BUS_READ) begin
            read_count++;
        end
        else begin
            write_count++;
        end


        case(item.actual_psel)

            4'b0001: begin
                bram_count++;

                if(item.op == BUS_READ) begin
                    bram_read_count++;
                end
                else begin
                    bram_write_count++;
                end
            end


            4'b0010: begin
                gpio_count++;

                if(item.op == BUS_READ) begin
                    gpio_read_count++;
                end
                else begin
                    gpio_write_count++;
                end
            end


            4'b0100: begin
                fnd_count++;

                if(item.op == BUS_READ) begin
                    fnd_read_count++;
                end
                else begin
                    fnd_write_count++;
                end
            end


            4'b1000: begin
                uart_count++;

                if(item.op == BUS_READ) begin
                    uart_read_count++;
                end
                else begin
                    uart_write_count++;
                end
            end

        endcase

    endfunction


    function void report_phase(uvm_phase phase);

        int    op_bin_count;
        int    slave_bin_count;
        int    cross_bin_count;
        real   op_coverage;
        real   slave_coverage;
        real   cross_coverage;
        real   total_coverage;
        string report;

        super.report_phase(phase);


        op_bin_count = 0;

        if(read_count > 0) begin
            op_bin_count++;
        end

        if(write_count > 0) begin
            op_bin_count++;
        end


        slave_bin_count = 0;

        if(bram_count > 0) begin
            slave_bin_count++;
        end

        if(gpio_count > 0) begin
            slave_bin_count++;
        end

        if(fnd_count > 0) begin
            slave_bin_count++;
        end

        if(uart_count > 0) begin
            slave_bin_count++;
        end


        cross_bin_count = 0;

        if(bram_read_count > 0) begin
            cross_bin_count++;
        end

        if(bram_write_count > 0) begin
            cross_bin_count++;
        end

        if(gpio_read_count > 0) begin
            cross_bin_count++;
        end

        if(gpio_write_count > 0) begin
            cross_bin_count++;
        end

        if(fnd_read_count > 0) begin
            cross_bin_count++;
        end

        if(fnd_write_count > 0) begin
            cross_bin_count++;
        end

        if(uart_read_count > 0) begin
            cross_bin_count++;
        end

        if(uart_write_count > 0) begin
            cross_bin_count++;
        end


        op_coverage    = 100.0 * op_bin_count / 2.0;
        slave_coverage = 100.0 * slave_bin_count / 4.0;
        cross_coverage = 100.0 * cross_bin_count / 8.0;
        total_coverage = cg_apb.get_coverage();


        report = {
            "\n============================================\n",
            " APB FUNCTIONAL COVERAGE\n",
            "--------------------------------------------\n",
            $sformatf(" Transactions : %0d\n", transaction_count),
            "\n",
            $sformatf(" Operation    : %0d / 2 bins (%.1f%%)\n", op_bin_count, op_coverage),
            $sformatf(" Slave Select : %0d / 4 bins (%.1f%%)\n", slave_bin_count, slave_coverage),
            $sformatf(" Op x Slave   : %0d / 8 bins (%.1f%%)\n", cross_bin_count, cross_coverage),
            "\n",
            $sformatf(" Read  : %0d\n", read_count),
            $sformatf(" Write : %0d\n", write_count),
            $sformatf(" BRAM  : %0d\n", bram_count),
            $sformatf(" GPIO  : %0d\n", gpio_count),
            $sformatf(" FND   : %0d\n", fnd_count),
            $sformatf(" UART  : %0d\n", uart_count),
            "--------------------------------------------\n",
            $sformatf(" Total Coverage : %.1f%%\n", total_coverage),
            "============================================"
        };

        `uvm_info(get_type_name(), report, UVM_LOW)

    endfunction

endclass
