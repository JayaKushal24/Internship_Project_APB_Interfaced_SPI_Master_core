`timescale 1ns/1ps

module spi_slave_control_top (
    input   PCLK,
    input   PRESETn,
    input   mstr,
    input   spiswai,
    input   [1:0] spi_mode,
    input   send_data,
    output  receive_data,
    input   [11:0] BaudRateDivisor,
    output  tip,
    output  ss
);

    reg [15:0] count;
    wire [15:0] target= BaudRateDivisor<< 4;
    reg rcv;
    wire count_eq_target_m1=(count == (target - 16'd1));
    wire count_le_target_m1=(count<= (target - 16'd1));
    wire spi_mode_is_0=(spi_mode == 2'b00);
    wire spi_mode_is_1=(spi_mode == 2'b01);
//    wire ctrl_and=(spi_mode_is_0 & spiswai) | (spi_mode_is_1 & mstr);//modified
    wire ctrl_and=( mstr & (spi_mode == 2'b00 || spi_mode == 2'b01) & (!spiswai) );
    wire rcv_mux0_out=count_eq_target_m1 ? 1'b1 : rcv;
    wire rcv_mux1_out=count_le_target_m1 ? rcv_mux0_out:1'b0;
    wire rcv_mux2_out=send_data ? 1'b0:rcv_mux1_out;
    wire rcv_mux3_out=ctrl_and ? rcv_mux2_out : 1'b0;
    
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            rcv<= 1'b0;
        else
            rcv<=rcv_mux3_out;
    end

    wire ss_mux0_out=count_le_target_m1 ? 1'b0 : 1'b1;
    wire ss_mux1_out=send_data ? 1'b0:ss_mux0_out;
    wire ss_mux2_out=ctrl_and ? ss_mux1_out : 1'b1;
    reg ss_dff;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            ss_dff<= 1'b1;     
        else
            ss_dff<=ss_mux2_out;
    end
    
    assign ss=PRESETn ? ss_dff : 1'b1;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            count<= 16'hffff;
        end else if (ctrl_and) begin
            if (send_data) begin
                count<= 16'b0;
            end else if (count<= (target - 16'd1)) begin
                count<= count + 16'd1;
            end else begin
                count<= 16'hffff;
            end
        end else begin
            count<= 16'hffff;
        end
    end

    reg receive_dff;
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            receive_dff<= 1'b0;
        else
            receive_dff<=rcv;
    end
    
    assign receive_data=PRESETn ? receive_dff : 1'b0;
    assign tip=~ss;

endmodule
