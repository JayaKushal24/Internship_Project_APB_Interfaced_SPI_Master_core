module tb_shift_reg;

    reg PCLK,PRESETn,ss,send_data,receive_data,lsbfe,cpha,cpol,miso;
    reg flag_low,flag_high,flags_low,flags_high;//flags
    reg [7:0] data_mosi;
    wire [7:0] data_miso;
    wire mosi;

    shift_reg dut (
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
        .data_mosi(data_mosi),
        .miso(miso),
        .mosi(mosi),
        .data_miso(data_miso)
    );

    initial begin
        PCLK=0;
        forever #5 PCLK= ~PCLK;
    end

    integer i;
    reg [7:0] sample1=8'b11001100;//for LSB
    reg [7:0] sample2=8'b11001100;//for MSb

    initial begin
        PRESETn = 0;
        ss = 1;
        send_data = 0;
        receive_data = 0;
        lsbfe = 1;//LSB first
        cpha = 0;
        cpol = 0;
        flag_low = 0;
        flag_high = 0;
        flags_low = 0;
        flags_high = 0;
        data_mosi = 8'b10101010;//tx data
        miso = 0;

        #15 PRESETn = 1;
        #10 ss = 0;

        send_data=1;//load data into shift reg
        #10 send_data=0;

        for (i=0;i<8; i=i+1) begin
            miso=sample1[i];
            flag_low=1;flags_low=1;
            #10;
            flag_low=0;flags_low=0;
            #10;
        end

        receive_data=1;//read data
        #10 receive_data=0;
        $display("LSB test: data_miso = %b", data_miso);
        i=0;
        #10;
        PRESETn = 0;
        #10 PRESETn = 1;


        ss = 0;
        send_data = 0;
        receive_data = 0;
        lsbfe = 0;//MSB first
        cpha = 0;
        cpol = 0;
        flag_low = 0;
        flag_high = 0;
        flags_low = 0;
        flags_high = 0;
        data_mosi = 8'b10101010;//tx data
        miso = 0;

        #10 send_data=1;//load data
        #10 send_data=0;


        for (i=7;i>=0; i=i-1) begin
            miso=sample2[i];
            flag_low=1;flags_low=1;
            #10;
            flag_low=0;flags_low=0;
            #10;
        end


        receive_data=1;//read data
        #10 receive_data=0;
        $display("MSB test: data_miso = %b",data_miso);


        #10 $finish;
    end




endmodule
