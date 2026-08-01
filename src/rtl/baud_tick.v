`timescale 1ns / 1ps

module baud_tick(

    input   clk,
    input   rst,
    input   [01:00] i_buadrate,


    output  reg  b_tick

    );


    reg [09:00] f_count;

//100MHz
//    always (*) begin
//        f_count = 10'd0;
//        case(i_buadrate)
//            2'b00 : f_count = 651;
//            2'b01 : f_count = 325;
//            2'b10 : f_count = 54;
//        endcase
//    end

//50MHz

    always @ (*) begin
        f_count = 10'd0;
        case(i_buadrate)
            2'b00 : f_count = 325;
            2'b01 : f_count = 162;
            2'b10 : f_count = 27;
        endcase
    end


    reg     [09:00] clk_cnt;


    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            clk_cnt <= 0;
        end
        else if(clk_cnt == f_count - 1) begin
            clk_cnt <= 0;
        end
        else begin
            clk_cnt <= clk_cnt + 1'b1;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_tick <= 1'b0;
        end
        else if(clk_cnt == f_count - 1) begin
            b_tick <= 1'b1;
        end
        else begin
            b_tick <= 1'b0;
        end
    end




endmodule
