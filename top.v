`timescale 1ns/1ps

module top (
    input        PCLK,
    input   PRESETn,
    input   [2:0]  PADDR,
    input  PWRITE,
    input   PSEL,
    input   PENABLE,
    input   [7:0]  PWDATA,
    output  [7:0]  PRDATA,
    output  PREADY,
    output  PSLVERR,
    input    miso,
    output  mosi,
    output  sclk,
    output  ss,
    output  spi_interrupt_request
);

    wire    [7:0] miso_data;
    wire    receive_data;
    wire    tip;
    wire    mstr, cpol,cpha,lsbfe,spiswai;
    wire    [2:0] sppr,spr;
    wire    send_data;
    wire    mosi_data;
    wire    [1:0]spi_mode;
    wire    [11:0]baudratedivisor;

    wire flag_low,flag_high,flags_low,flags_high;

    apb_spi_interface    mod1 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .ss(ss),
        .miso_data(miso_data),
        .receive_data(receive_data),
        .tip(tip),
        .mstr(mstr),
        .cpol(cpol),
        .cpha(cpha),
        .lsbfe(lsbfe),
        .spiswai(spiswai),
        .sppr(sppr),
        .spr(spr),
        .spi_interrupt_request(spi_interrupt_request),
        .send_data(send_data),
        .mosi_data(mosi_data),
        .spi_mode(spi_mode)
    );

    baud_rate_generator    mod2 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .spi_mode(spi_mode),
        .spiswai(spiswai),
        .sppr(sppr),
        .spr(spr),
        .cpol(cpol),
        .cpha(cpha),
        .ss(ss),
        .sclk(sclk),
        .flag_low(flag_low),
        .flag_high(flag_high),
        .flags_low(flags_low),
        .flags_high(flags_high),
        .baudratedivisor(baudratedivisor)
    );

    spi_slave_control_top  mod3 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .mstr(mstr),
        .spiswai(spiswai),
        .spi_mode(spi_mode),
        .send_data(send_data),
        .receive_data(receive_data),
        .BaudRateDivisor(baudratedivisor),
        .tip(tip),
        .ss(ss)
    );

    shift_reg mod4 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .ss(ss),
        .send_data(send_data),
        .receive_data(receive_data),
        .lsbfe(lsbfe),
        .cpha(cpha),
        .cpol(cpol),
        .flag_low(flag_low),
        .flag_high(flag_high),
        .flags_low(flags_low),
        .flags_high(flags_high),
        .data_mosi(PWDATA),
        .miso(miso),
        .mosi(mosi),
        .data_miso(miso_data)
    );

endmodule
