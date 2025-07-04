`timescale 1ns/1ps

module testbench;
    reg        PCLK;
    reg        PRESETn;
    reg [2:0]  PADDR;
    reg        PWRITE;
    reg        PSEL;
    reg        PENABLE;
    reg [7:0]  PWDATA;
    reg        miso;
    wire [7:0] PRDATA;
    wire       PREADY;
    wire       PSLVERR;
    wire       mosi, sclk, ss;
    wire       spi_interrupt_request;


    top dut (
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
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .ss(ss),
        .spi_interrupt_request(spi_interrupt_request)
    );

    initial PCLK = 0;
    always #5 PCLK = ~PCLK;  

    reg [7:0] slave_data = 8'hA5;
    always @(negedge sclk or posedge ss) begin
        if (ss)
            slave_data <= 8'hA5;
        else
            slave_data<= {slave_data[6:0], 1'b1};
    end
    always @(*) begin
        miso = slave_data[7];
    end

    initial begin
        PRESETn = 0;
        PADDR = 0;
        PWRITE = 0;
        PSEL = 0;
        PENABLE = 0;
        PWDATA = 0;
        #20 PRESETn = 1;

        //SPI_CR_1
        apb_write(3'b000,8'b11010101); //SPIE=1,SPE=1,MSTR=1,CPOL=0,CPHA=1,LSBFE=1
        #20;
        //SPI_CR_2
        apb_write(3'b001,8'b00000000); //SPISWAI=0
        #20;
        //SPI_BR
        apb_write(3'b010,8'b00000000); //fastest baud rate
        #20;
        //SPI_DR
        apb_write(3'b101,8'hF0);
        #20;
        apb_read(3'b000);//SPI_CR_1
        apb_read(3'b001);//SPI_CR_2
        apb_read(3'b010);//SPI_BR
        apb_read(3'b011);//SPI_SR
        apb_read(3'b101);//SPI_DR
        #500;

        $finish;
    end

    task apb_write;
        input [2:0] addr;
        input [7:0] data;
        begin
            //Setup phase: set addr/data, PWRITE  but PSEL=0 PENABLE=0
            @(posedge PCLK);
            PADDR   = addr;
            PWDATA  = data;
            PWRITE  = 1;
            PSEL    = 0;
            PENABLE = 0;
            @(posedge PCLK);
            PSEL    = 1;
            @(posedge PCLK);
            PENABLE = 1;
            wait (PREADY);
            @(posedge PCLK);
            PSEL    = 0;
            PENABLE = 0;
            PWRITE  = 0;
        end
    endtask

    task apb_read;
        input [2:0] addr;
        begin
            @(posedge PCLK);
            PADDR   = addr;
            PWRITE  = 0;
            PSEL    = 0;
            PENABLE = 0;
            @(posedge PCLK);
            PSEL    = 1;
            @(posedge PCLK);
            PENABLE = 1;
            wait (PREADY);
            @(posedge PCLK);
            $display("Read from Addr %b=%h",addr,PRDATA);
            PSEL    = 0;
            PENABLE = 0;
        end
    endtask


endmodule
