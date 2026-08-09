`timescale 1ns / 1ps

module fnd(
    
    input           clk,
    input           rst,

    input           [31:00] i_paddr,
    input           [31:00] i_pdata,
    input                   i_penable,
    input                   i_pwrite,
    input                   i_psel,

    output  logic   [31:00] o_prdata,
    output  logic           o_pready,
    output  logic   [07:00] o_fnd_data,
    output  logic   [03:00] o_fnd_digit

    );

    localparam [11:00]  fnd_data    = 12'h000;

    logic   [31:00] fnd_reg;
    logic   [15:00] digit_data;

    assign o_pready = i_penable && i_psel;
    assign o_prdata = {16'b0, fnd_reg[15:00]};


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            fnd_reg <= 32'd0;
        end
        else if(i_penable && i_psel && i_pwrite && (i_paddr[11:00] == fnd_data)) begin
            fnd_reg <= i_pdata;
        end
        else begin
            fnd_reg <= fnd_reg;
        end
    end

    fnd_controller U_FND(

        .clk(clk),
        .rst(rst),
        .i_fnd_data(fnd_reg[15:00]),

        .o_fnd_digit(o_fnd_digit),
        .o_fnd_data(o_fnd_data)

    );

endmodule



