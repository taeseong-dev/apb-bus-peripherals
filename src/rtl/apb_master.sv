`timescale 1ns / 1ps

module apb_master(

    // BUS Global signal
    input           clk,
    input           rst,

    // SoC Internal signal with CPU
    input           [31:00] i_addr, 
    input           [31:00] i_wdata,
    input                   i_wreq,
    input                   i_rreq,

    output  logic   [31:00] o_rdata,
    output  logic           o_ready,

    // APB Interface signal
    output          [31:00] o_paddr,
    output          [31:00] o_pdata,
    output                  o_penable,
    output                  o_pwrite,
    output                  o_psel0,
    output                  o_psel1,
    output                  o_psel2,
    output                  o_psel3,

    input           [31:00] i_prdata0,
    input           [31:00] i_prdata1,
    input           [31:00] i_prdata2,
    input           [31:00] i_prdata3,

    input                   i_pready0,
    input                   i_pready1,
    input                   i_pready2,
    input                   i_pready3

    );

    reg           p_enable;
    reg           p_write;

    reg   [31:00] r_addr;
    reg   [31:00] r_wdata;
    reg   [03:00] r_psel;
    reg           decode_en;


    typedef enum {
        IDLE, SETUP, ACCESS
    } state_t;

    state_t c_st, n_st;


    assign {o_psel3, o_psel2, o_psel1, o_psel0} = r_psel;

    assign o_pdata = r_wdata;
    assign o_paddr = r_addr;
    assign o_penable = p_enable;
    assign o_pwrite = p_write;

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            p_enable <= 1'b0;
        end
        else if(c_st == IDLE && (i_wreq || i_rreq)) begin
            p_enable <= 1'b0;
        end
        else if(c_st == SETUP) begin
            p_enable <= 1'b1;
        end
        else begin
            p_enable <= p_enable;
        end
    end


    // state : ACCESS -> SETUP 
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            p_write <= 1'b0;
        end
        else if(c_st == IDLE && i_wreq) begin
            p_write <= 1'b1;
        end
        else if(c_st == ACCESS && o_ready) begin
            p_write <= 1'b0;
        end
        else begin
            p_write <= p_write;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            r_addr <= 32'd0;
        end
        else if(c_st == IDLE && (i_wreq || i_rreq)) begin
            r_addr <= i_addr;
        end
        else begin
            r_addr <= r_addr;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            r_wdata <= 32'd0;
        end
        else if(c_st == IDLE && (i_wreq || i_rreq)) begin
            r_wdata <= i_wdata;
        end
        else begin
            r_wdata <= r_wdata;
        end
    end

    always_comb begin
        r_psel = 4'd0;
        if(decode_en) begin

            casex({r_addr[29:28], r_addr[14:12]})
                5'b01_xxx : r_psel = 4'b0001;        //RAM
                5'b10_000 : r_psel = 4'b0010;        //GPIO
                5'b10_001 : r_psel = 4'b0100;        //FND
                5'b10_010 : r_psel = 4'b1000;        //UART
            endcase
        end
    end



    always_comb begin
        o_rdata = 32'd0;
        o_ready = 1'b0;
        case(r_psel)
            4'b0001 : begin
                            o_rdata = i_prdata0;
                            o_ready = i_pready0;
                        end
            4'b0010 : begin
                            o_rdata = i_prdata1;
                            o_ready = i_pready1;
                        end
            4'b0100 : begin
                            o_rdata = i_prdata2;
                            o_ready = i_pready2;
                        end
            4'b1000 : begin
                            o_rdata = i_prdata3;
                            o_ready = i_pready3;
                        end
        endcase
    end

    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            decode_en <= 1'b0;
        end
        else if(n_st == SETUP) begin
            decode_en <= 1'b1;
        end
        else if(n_st == IDLE) begin
            decode_en <= 1'b0;
        end
        else begin
            decode_en <= decode_en;
        end
    end

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            c_st <= IDLE;
        end
        else begin
            c_st <= n_st;
        end
    end


    always_comb begin
        n_st = IDLE;
        case(c_st)
            IDLE    :   begin
                            if(i_wreq || i_rreq) begin
                                n_st = SETUP;
                            end
                        end

            SETUP   :   begin
                            n_st = ACCESS;
                        end

            ACCESS  :   begin
                            if(o_ready) begin
                                n_st = IDLE;
                            end
                            else begin
                                n_st = ACCESS;
                            end
                        end
        endcase
    end





endmodule
