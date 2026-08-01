`timescale 1ns / 1ps

module uart_tx(

    input               clk,
    input               rst,
    input               tx_start,
    input               b_tick,
    input   [07:00]     tx_data,

    output  reg         tx_done,
    output  reg         tx_busy,
    output              uart_tx

    );



    localparam IDLE = 2'd0,  START = 2'd1, BIT = 2'd2, STOP = 2'd3;

    reg [01:00]     c_st;
    reg [01:00]     n_st;
    reg             tx_reg;
    reg             tx_next;

    reg [02:00]     b_cnt;

    reg [07:00]     data_in_buf;
    reg [03:00]     tick_cnt;

    wire    tick_flag;
    assign  uart_tx = tx_reg;

    assign tick_flag = (tick_cnt == 4'd15 && b_tick) ? 1'b1 : 1'b0;
 
    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tick_cnt <= 4'd0;
        end
        else if(c_st == IDLE) begin
            tick_cnt <= 0;
        end
        else if((c_st != IDLE) && b_tick) begin
            tick_cnt <= tick_cnt + 1'b1;
        end
        else begin
            tick_cnt <= tick_cnt;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            c_st <= IDLE;
            tx_reg <= 1'b1;
        end
        else begin
            c_st <= n_st;
            tx_reg <= tx_next;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            b_cnt <= 3'd0;
        end
        else if(c_st == IDLE) begin
            b_cnt <= 0;
        end
        else if((c_st == BIT) && tick_flag) begin
            b_cnt <= b_cnt + 1'b1;
        end
        else begin
            b_cnt <= b_cnt;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tx_busy <= 1'b0;
        end
        else if(tx_start) begin
            tx_busy <= 1'b1;
        end
        else if(c_st == STOP && tick_flag) begin
            tx_busy <= 1'b0;
        end
        else begin
            tx_busy <= tx_busy;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            tx_done <= 1'b0;
        end
        else if(c_st == STOP && tick_flag) begin
            tx_done <= 1'b1;
        end
        else begin
            tx_done <= 1'b0;
        end
    end

    always @ (posedge clk or posedge rst) begin
        if(rst) begin
            data_in_buf <= 8'd0;
        end
        else if(tx_start) begin
            data_in_buf <= tx_data;
        end
        else if(c_st == BIT && tick_flag)begin
            data_in_buf <= data_in_buf >> 1;
        end
        else begin
            data_in_buf <= data_in_buf;
        end
    end  

    always @ (*) begin
        n_st = c_st;
        tx_next = tx_reg;
        case(c_st)
            IDLE    :   begin
                            tx_next = 1'b1;
                            if(tx_start) begin
                                n_st = START;
                            end
                        end

            START   :   begin
                            tx_next = 1'b0;
                            if(tick_flag) begin
                                n_st = BIT;
                            end
                        end

            BIT     :   begin
                            tx_next = data_in_buf[0];
                            if(b_cnt == 3'd7 && tick_flag) begin
                                n_st = STOP;
                            end
                            else if(tick_flag) begin
                                n_st = BIT;
                            end
                                
                        end

            STOP    :   begin
                            tx_next = 1'b1;
                            if(tick_flag) begin
                                n_st = IDLE;
                            end
                        end
        endcase
    end


        
endmodule
