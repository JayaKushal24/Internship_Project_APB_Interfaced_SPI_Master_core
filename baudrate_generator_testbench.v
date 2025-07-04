`timescale 1ns/1ps

module tb_baud_rate_generator;

reg PCLK;
reg PRESETn;
reg[1:0] spi_mode;
reg spiswai;
reg[2:0] sppr;
reg[2:0] spr;
reg cpol;
reg cpha;
reg ss;

wire sclk;
wire flag_low,flag_high,flags_low,flags_high;
wire[11:0] baudratedivisor;

baud_rate_generator DUT(
    .PCLK(PCLK),        .PRESETn(PRESETn),          .spi_mode(spi_mode),
    .spiswai(spiswai),  .sppr(sppr),                .spr(spr),          .cpol(cpol),
    .cpha(cpha),        .ss(ss),                    .sclk(sclk),        .flag_low(flag_low),
    .flag_high(flag_high),                          .flags_low(flags_low),
    .flags_high(flags_high),                        .baudratedivisor(baudratedivisor)
);

initial PCLK=0;
always #5 PCLK=~PCLK;

task test_spi_flags(input cpol_in,input cpha_in);
    integer i;
    begin
        PRESETn=0;
        spi_mode=2'b00;//run mode
        spiswai=0;
        sppr=3'b000;
        spr=3'b001;//4
        cpol=cpol_in;
        cpha=cpha_in;
        ss=1;//off

       #10 PRESETn = 1;
#20;
ss = 0;
    
        for(i=0;i<20;i=i+1)begin
            @(posedge PCLK);
        end
        ss=1;//off
        #10;
    end
endtask

initial begin
    test_spi_flags(0,0);
    test_spi_flags(0,1);
    test_spi_flags(1,0);
    test_spi_flags(1,1);
    $finish;
end

endmodule
