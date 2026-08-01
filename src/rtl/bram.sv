`timescale 1ns / 1ps



module bram(

    input           clk,

    input           [31:00] i_paddr,
    input           [31:00] i_pdata,
    input                   i_penable,
    input                   i_pwrite,
    input                   i_psel,

    output  logic   [31:00] o_prdata,
    output  logic           o_pready

    );
    logic [31:0] bmem[0:1023];

    assign o_pready = (i_penable && i_psel);

    always_ff @(posedge clk) begin
        if (i_psel && i_penable && i_pwrite) begin
            bmem[i_paddr[11:2]] <= i_pdata;  // SW
        end
    end

    assign o_prdata = bmem[i_paddr[11:2]];



endmodule
