`timescale 1ns/1ps

module baud_rate_generator (
    input   PCLK,
    input   PRESETn,
    input   [1:0]    spi_mode,
    input   spiswai,
    input   [2:0]  sppr,
    input   [2:0]  spr,
    input   cpol,//CPOL sets the idle level of the clock
    input   cpha,//CPHA sets which clock edge is used for sampling/shifting
    input   ss,
    output  reg sclk,
    output  reg flag_low,
    output reg flag_high,
    output  reg flags_low,
    output  reg flags_high,
    output   [11:0] baudratedivisor
);
//CPOL and CPHA are set according to the requirements of the slave device you want to communicate with
//Not all SPI devices use the same clock polarity and phase.If the master and slave don't agree on CPOL/CPHA, data will be sampled or shifted at the wrong times, leading to communication errors
// Every SPI slave device (sensor,flash,display...) will specify in its datasheet which SPI mode it supports (Mode 0,1,2,3)or will describe the required clock idle state and which clock edge to sample data on
reg [11:0]count;
wire mode_sel;
wire enable_count;
wire count_eq;

assign   baudratedivisor =(sppr+1)*(1<<(spr+ 1));//baud rate calculation

assign mode_sel=(spi_mode==2'b00)||(spi_mode==2'b01);
assign enable_count= mode_sel & (~ss) & (~spiswai);
//assign count_eq=(count==(baudratedivisor - 1'b1));

always@(posedge PCLK or negedge PRESETn) begin//count logic 
    if (!PRESETn)  count<=12'b0;
    else if (enable_count) begin
        if (count==(baudratedivisor - 1'b1)) count<=12'b0;
        else count<=count+1'b1;
    end
    else count<=12'b0;
end

 wire pre_sclk = cpol;//need to check this logic

//sclk generatino
always@(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) sclk<=pre_sclk;
    else if (enable_count)begin
        if (count==(baudratedivisor - 1'b1)) sclk<= ~sclk;
    end
    else sclk<= pre_sclk;
end


//FLAGS


//flag_low and flags_low are used for Modes 0 and 3 (CPOL==CPHA)
//flag_high and flags_high are used for Modes 1 and 2 (CPOL!=CPHA)
wire enable_flags;
assign enable_flags = cpha ^ cpol;//The combination of CPOL and CPHA determines which flags the logic should use to coordinate data transfer, ensuring compatibility with any SPI device
assign count_flags=(count==(baudratedivisor - 2'b10));

/////////////flags_low
//This flag is asserted to tell the SPI logic to send (shift out) data on the MOSI line when both CPOL and CPHA are the same
always@(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)   flags_low<=1'b0;
        else if (!enable_flags)begin
            if (!sclk) begin
                flags_low<= (count_flags)? 1'b1:1'b0;
            end
            else flags_low<=1'b0;
        end
end


/////////////flags_high
//This flag pulses to signal the SPI master (or slave) that it should sample the incoming data (MISO) when either CPOL or CPHA is high 
always@(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)   flags_high<=1'b0;
        else if (enable_flags)begin
            if (sclk) begin
                flags_high<= (count_flags)? 1'b1:1'b0;
            end
            else flags_high<=1'b0;
        end
end


/////////////flags_low
//This flag pulses to signal the SPI master (or slave) that it should sample the incoming data (MISO) when both the clock phase and clock polarity are the same
always@(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)   flag_low<=1'b0;
        else if (!enable_flags)begin
            if (!sclk) begin
                flag_low<= (count==(baudratedivisor - 1'b1))? 1'b1:1'b0;
            end
            else flag_low<=1'b0;
        end
end

/////////////flag_high
//This flag pulses to signal the SPI master (or slave) that it should sample the incoming data (MISO) when either CPOL or CPHA is high
always@(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)   flag_high<=1'b0;
        else if (enable_flags)begin
            if (sclk) begin
                flag_high<= (count==(baudratedivisor - 1'b1))? 1'b1:1'b0;
            end
            else flag_high<=1'b0;
        end
end

//the flags are specifically designed to tell SPI logic when to sample or shift data, depending on CPOL/CPHA.

endmodule
