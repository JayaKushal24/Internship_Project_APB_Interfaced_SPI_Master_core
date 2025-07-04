`timescale 1ns/1ps

module tb_apb_spi_interface;

    reg PCLK;
    reg PRESETn;
    reg [2:0]  PADDR;
    reg PWRITE;
    reg PSEL;
    reg PENABLE;
    reg [7:0]  PWDATA;
    reg ss;
    reg [7:0]  miso_data;
    reg receive_data;
    reg tip;
    wire    [7:0] PRDATA;
    wire PREADY;
    wire    PSLVERR;
    wire    mstr, cpol, cpha, lsbfe, spiswai;
    wire    [2:0] sppr, spr;
    wire    spi_interrupt_request,send_data,mosi_data;
    wire [1:0] spi_mode;

    apb_spi_interface dut (
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

    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

    initial begin
        PRESETn = 0;
        PADDR = 0;
        PWRITE = 0;
        PSEL = 0;
        PENABLE = 0;
        PWDATA = 0;
        ss = 1;
        miso_data = 8'hA5;
        receive_data = 0;
        tip = 0;

        #20 PRESETn = 1;

        apb_write(3'b000,8'b10010101);//SPIE=1,MSTR=1,CPOL=0,CPHA=1,SSOE=0,LSBFE=1
        #20;
        apb_write(3'b001,8'b00011111);//SPISWAI=1,MODFEN=1
        #20;
        apb_write(3'b010,8'b01101011);//SPPR=011,SPR=011
        #20;
        apb_write(3'b101,8'hF0);
        #20;
        apb_read(3'b000);//SPI_CR_1
        apb_read(3'b001);//SPI_CR_2
        apb_read(3'b010);//SPI_BR
        apb_read(3'b011);//SPI_SR
        apb_read(3'b101);//SPI_DR

        receive_data = 1;
        tip = 0;
        ss = 0;
        miso_data = 8'h55;

        #50;
        receive_data = 0;
        ss = 1;
        #100;
        $finish;
    end

    task apb_write(input [2:0] addr, input [7:0] data);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWDATA  <= data;
            PWRITE  <= 1;
            PSEL    <= 1;
            PENABLE <= 0;
            @(posedge PCLK);
            PENABLE <= 1;
            wait (PREADY);
            @(posedge PCLK);
            PSEL    <= 0;
            PENABLE <= 0;
            PWRITE  <= 0;
        end
    endtask

    task apb_read(input [2:0] addr);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWRITE  <= 0;
            PSEL    <= 1;
            PENABLE <= 0;
            @(posedge PCLK);
            PENABLE <= 1;
            wait (PREADY);
            @(posedge PCLK);
            $display("Read from Addr %b=%h",addr,PRDATA);
            PSEL    <= 0;
            PENABLE <= 0;
        end
    endtask

endmodule
