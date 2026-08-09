`timescale 1ns / 1ps


module apb_gpio(

    input           clk,
    input           rst,

    input           [31:00] i_paddr,
    input           [31:00] i_pdata,
    input                   i_penable,
    input                   i_pwrite,
    input                   i_psel,     


    output  logic   [31:00] o_prdata,
    output  logic           o_pready,
    inout   wire    [15:00] gpio


    );

    localparam [11:00]  GPIO_CNTL_ADDR = 12'h000;
    localparam [11:00]  GPIO_ODATA_ADDR = 12'h004;
    localparam [11:00]  GPIO_IDATA_ADDR = 12'h008;

    logic [15:00] gpio_odata_reg;
    logic [15:00] gpio_cntl_reg;

    logic [15:00] gpio_idata;

    assign o_pready = (i_penable && i_psel);

    assign o_prdata = (i_paddr[11:00] == GPIO_CNTL_ADDR)  ? {16'd0, gpio_cntl_reg} :
                      (i_paddr[11:00] == GPIO_ODATA_ADDR) ? {16'd0, gpio_odata_reg} : 
                      (i_paddr[11:00] == GPIO_IDATA_ADDR) ? {16'd0, gpio_idata} : 32'hxxxx_xxxx; //last data

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            gpio_odata_reg <= 16'd0;
        end
        else if(i_penable && i_psel && i_pwrite && (i_paddr[11:00] == GPIO_ODATA_ADDR)) begin
            gpio_odata_reg <= {i_pdata[07:00], 8'b0};
        end
        else begin
            gpio_odata_reg <= gpio_odata_reg;
        end
    end 

    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            gpio_cntl_reg <= 16'd0;
        end
        else if(i_penable && i_psel && i_pwrite && (i_paddr[11:00] == GPIO_CNTL_ADDR)) begin
            gpio_cntl_reg <= i_pdata[15:00];
        end
        else begin
            gpio_cntl_reg <= gpio_cntl_reg;
        end
    end

    gpio_sub U_GPIO(
    .i_cntl(gpio_cntl_reg),
    .i_data(gpio_idata),
    .o_data(gpio_odata_reg),
    .gpio(gpio)
);



endmodule

module gpio_sub(
    input   logic   [15:00] i_cntl,
    output  logic   [15:00] i_data,
    input   logic   [15:00] o_data,
    inout   wire    [15:00] gpio
);

    genvar i;

    generate
        for(i=0; i<16; i=i+1) begin
            assign gpio[i] = i_cntl[i] ? o_data[i] : 1'bz;
            assign i_data[i] = ~i_cntl[i] ? gpio[i] : 1'b0;
        end
    endgenerate



endmodule
