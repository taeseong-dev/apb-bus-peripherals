`timescale 1ns / 1ps

module fnd_controller(

    input                   clk,
    input                   rst,
    input       [15:00]     i_fnd_data,


    output      [03:00]     o_fnd_digit,
    output      [07:00]     o_fnd_data

    );

    wire        [03:00]      w_digit_1;
    wire        [03:00]      w_digit_10; 
    wire        [03:00]      w_digit_100;
    wire        [03:00]      w_digit_1000;

    wire        [01:00]      w_cnt8_digit_sel;

    wire        [03:00]      w_mux_out;


    digit_splitter #(
        .BIT_WIDTH(16)
    )
    U_DS
    (
    
    .i_data             (i_fnd_data    ),
    .o_digit_1          (w_digit_1     ),
    .o_digit_10         (w_digit_10    ),
    .o_digit_100        (w_digit_100   ),
    .o_digit_1000       (w_digit_1000  )

    );


    clk_div U_CLK_DIV (

        .clk        (clk),
        .rst        (rst),
        .o_1khz     (w_clk_div_1khz)

    );

    counter_8 U_COUNTER_4 (

    .clk        (w_clk_div_1khz),
    .rst        (rst),
    .o_digit_sel  (w_cnt8_digit_sel)
    );


    decoder_2x4 U_DECODER_2x4(

    .i_digit_sel(w_cnt8_digit_sel),
    .o_fnd_digit(o_fnd_digit)

);

    mux_4x1 U_MUX_4x1(

    .i_sel            (w_cnt8_digit_sel  ),
    .i_digit_1        (w_digit_1         ),
    .i_digit_10       (w_digit_10        ),
    .i_digit_100      (w_digit_100       ),
    .i_digit_1000     (w_digit_1000      ),

    .mux_out          (w_mux_out)
    
    );


    bcd U_BCD (
        .bcd        (w_mux_out),
        .o_fnd_data   (o_fnd_data)
    );

endmodule

module counter_8(

    input               clk,
    input               rst,
    
    output   [01:00]     o_digit_sel
);

    reg     [01:00]     counter_r;

    assign  o_digit_sel = counter_r;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            counter_r <= 2'd0;
        end
        else begin
            counter_r <= counter_r + 1'b1;
        end
    end


endmodule

module decoder_2x4 (

    input           [01:00]     i_digit_sel,
    output reg      [03:00]     o_fnd_digit

);

    always @ (i_digit_sel) begin
        case(i_digit_sel)
            2'b00 : o_fnd_digit = 4'b1110;
            2'b01 : o_fnd_digit = 4'b1101;
            2'b10 : o_fnd_digit = 4'b1011;
            2'b11 : o_fnd_digit = 4'b0111;
        endcase
    end
    
endmodule
                



module mux_4x1(

    input       [01:00]     i_sel,
    input       [03:00]     i_digit_1,
    input       [03:00]     i_digit_10,
    input       [03:00]     i_digit_100,
    input       [03:00]     i_digit_1000,

    output reg  [03:00]     mux_out

);

    always @ (*) begin
        case(i_sel)
            2'b00 : mux_out = i_digit_1;
            2'b01 : mux_out = i_digit_10;
            2'b10 : mux_out = i_digit_100;
            2'b11 : mux_out = i_digit_1000;
        endcase
    end

endmodule



module digit_splitter  #(parameter BIT_WIDTH = 7)

(
    
    input       [BIT_WIDTH - 1:00]     i_data,
    output      [03:00]     o_digit_1,
    output      [03:00]     o_digit_10,
    output      [03:00]     o_digit_100,
    output      [03:00]     o_digit_1000

);

    assign o_digit_1        = (i_data     )   % 10;
    assign o_digit_10       = (i_data/10  )   % 10;
    assign o_digit_100      = (i_data/100 )   % 10;
    assign o_digit_1000     = (i_data/1000)   % 10;


endmodule


module bcd (
    
    input           [03:00]     bcd,
    output  reg     [07:00]     o_fnd_data      

);

    always @ (bcd) begin
        case(bcd)
            4'd0 : o_fnd_data = 8'hc0;
            4'd1 : o_fnd_data = 8'hf9;
            4'd2 : o_fnd_data = 8'ha4;
            4'd3 : o_fnd_data = 8'hb0;
            4'd4 : o_fnd_data = 8'h99;
            4'd5 : o_fnd_data = 8'h92;
            4'd6 : o_fnd_data = 8'h82;
            4'd7 : o_fnd_data = 8'hf8;
            4'd8 : o_fnd_data = 8'h80;
            4'd9 : o_fnd_data = 8'h90;
            4'd10 : o_fnd_data = 8'hff;
            4'd11 : o_fnd_data = 8'hff;
            4'd12 : o_fnd_data = 8'hff;
            4'd13 : o_fnd_data = 8'hff;
            4'd14 : o_fnd_data = 8'h7f;
            4'd15 : o_fnd_data = 8'hff;

            default : o_fnd_data = 8'hff;
        endcase
    end

endmodule


module clk_div(
    input           clk,
    input           rst,
    output   reg    o_1khz
);

    reg   [16:00]   counter_r;

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            counter_r <= 17'd0;
        end
        else if(counter_r == 17'd99999) begin
            counter_r <= 17'd0;
        end 
        else begin
            counter_r <= counter_r + 1'b1;
        end
    end        

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            o_1khz <= 1'b0;
        end
        else if(counter_r == 17'd99999) begin
            o_1khz <= 1'b1;
        end
        else begin
            o_1khz <= 1'b0;
        end
    end
            

endmodule
