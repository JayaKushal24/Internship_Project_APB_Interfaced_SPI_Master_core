`timescale 1ns/1ps

module tb_spi_slave_control;
    reg PCLK;
    reg PRESETn;
    reg mstr;
    reg spiswai;
    reg [1:0] spi_mode;
    reg send_data;
    reg [11:0] BaudRateDivisor;
    wire receive_data;
    wire tip;
    wire ss;

    spi_slave_control_top dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .mstr(mstr),
        .spiswai(spiswai),
        .spi_mode(spi_mode),
        .send_data(send_data),
        .BaudRateDivisor(BaudRateDivisor),
        .receive_data(receive_data),
        .tip(tip),
        .ss(ss)
    );
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;
task run_transaction(input [1:0] mode, input mstr_val, input spiswai_val);
    begin
        spi_mode = mode;
        mstr = mstr_val;
        spiswai = spiswai_val;
        send_data = 1;
        #10;//1cycle
        send_data = 0;
        #(350);//to reach 31
        spiswai = 0;
        mstr = 0;
        #40;
    end
endtask



    initial begin
        PRESETn = 0;
        mstr = 0;
        spiswai = 0;
        spi_mode = 2'b00;
        send_data = 0;
        BaudRateDivisor = 12'd2;//target 32
        #20; PRESETn = 1;
        #20;
        run_transaction(2'b00,0,1);
        run_transaction(2'b01,1,0);
        run_transaction(2'b10,1,1);
//        run_transaction(2'b00, 0, 0);
        $finish;
    end

endmodule
