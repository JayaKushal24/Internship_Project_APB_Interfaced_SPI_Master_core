////////////////////////////////////////CODE IS WRITTEN BASED ON GIVEN ARCHITECTURE
module apb_spi_interface (
    input  PCLK,
    input  PRESETn,
    input  [2:0]  PADDR,
    input  PWRITE,
    input  PSEL,
    input  PENABLE,
    input  [7:0]  PWDATA,
    input  ss,
    input  [7:0]  miso_data,
    input  receive_data,
    input  tip,
    output mstr,
    output cpol,
    output cpha,
    output lsbfe,
    output spiswai,
    output [2:0]  sppr,
    output [2:0]  spr,
    output PREADY,
    output PSLVERR,
    output spi_interrupt_request,
    output reg  send_data,
    output reg  mosi_data,
    output reg  [7:0]  PRDATA,
    output [1:0]  spi_mode

);

    reg  [7:0] SPI_CR_1;
    reg  [7:0] SPI_CR_2;  
    reg  [7:0] SPI_BR;
    reg  [7:0] SPI_SR;
    reg  [7:0] SPI_DR;

    reg [1:0] apb_state, apb_next_state;
    localparam APB_IDLE  =2'b00;
    localparam APB_SETUP =2'b01;
    localparam APB_ENABLE=2'b10;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            apb_state<=APB_IDLE;
        else
            apb_state<=apb_next_state;
    end

    always @(*) begin
        case (apb_state)
            APB_IDLE: 
                apb_next_state=(PSEL && !PENABLE) ? APB_SETUP : APB_IDLE;
            APB_SETUP: 
                if (PSEL && PENABLE)
                    apb_next_state=APB_ENABLE;
                else if (PSEL && !PENABLE)
                    apb_next_state=APB_SETUP;
                else
                    apb_next_state=APB_IDLE;
            APB_ENABLE: 
                if (PSEL && !PENABLE)
                    apb_next_state=APB_SETUP;
                else if (PSEL && PENABLE)
                    apb_next_state=APB_ENABLE;
                else
                    apb_next_state=APB_IDLE;
            default: 
                apb_next_state=APB_IDLE; 
        endcase
    end

    wire in_enable_state=(apb_state==APB_ENABLE);
    wire wr_enb=in_enable_state && PWRITE;
    wire rd_enb=in_enable_state && !PWRITE;

    assign PREADY =in_enable_state;
    assign PSLVERR=in_enable_state ? tip : 1'b0;

    reg [1:0] spi_controller_state, spi_controller_next;
    localparam SPI_RUN =2'b00;
    localparam SPI_WAIT=2'b01;
    localparam SPI_STOP=2'b10;

    wire spe=SPI_CR_1[6]; 

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            spi_controller_state<=SPI_RUN;
        else
            spi_controller_state<=spi_controller_next;
    end

    always @(*) begin
        case (spi_controller_state)
            SPI_RUN: 
                spi_controller_next=(!spe) ? SPI_WAIT : SPI_RUN;
            SPI_WAIT: 
                if (spe)
                    spi_controller_next=SPI_RUN;
                else if (spiswai)
                    spi_controller_next=SPI_STOP;
                else
                    spi_controller_next=SPI_WAIT;
            SPI_STOP: 
                if (!spiswai)
                    spi_controller_next=SPI_WAIT;
                else
                    spi_controller_next=SPI_STOP;
            default: 
                spi_controller_next=SPI_RUN;
        endcase
    end

    wire [7:0] cr2_mask=8'b0001_1011;
    wire [7:0] br_mask =8'b0111_0111;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            SPI_CR_1<=8'h04;
        else if (wr_enb && (PADDR==3'b000))
            SPI_CR_1<=PWDATA;
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            SPI_CR_2<=8'h00;
        else if (wr_enb && (PADDR==3'b001))
            SPI_CR_2<=PWDATA & cr2_mask;
    end

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            SPI_BR<=8'h00;
        else if (wr_enb && (PADDR==3'b010))
            SPI_BR<=PWDATA & br_mask;
    end

    wire spi_run_or_wait=(spi_controller_state==SPI_RUN) || (spi_controller_state==SPI_WAIT);
    wire [7:0] mux1_out=(receive_data && spi_run_or_wait) ? miso_data : SPI_DR;
    wire [7:0] mux2_out=((SPI_DR==PWDATA) && (SPI_DR != miso_data) && spi_run_or_wait) ? mux1_out:8'b0;//modified here

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            SPI_DR<=8'b0;
        else if (wr_enb && (PADDR==3'b101))
            SPI_DR<=PWDATA;
        else if (!wr_enb)
            SPI_DR<=mux2_out;
    end


    wire spie=SPI_CR_1[7]; 
    wire sptie=SPI_CR_1[5];
    assign mstr   =SPI_CR_1[4];
    assign cpol   =SPI_CR_1[3];
    assign cpha   =SPI_CR_1[2];
    wire ssoe     =SPI_CR_1[1];
    assign lsbfe  =SPI_CR_1[0];
    assign spiswai=SPI_CR_2[1];
    assign sppr   =SPI_BR[6:4];
    assign spr    =SPI_BR[2:0];
    assign modfen =SPI_CR_2[4];

    wire sptef=(SPI_DR==8'b00000000);
    wire spif=(SPI_DR != 8'b00000000);
    wire ss_bar=~ss;
    wire modfen_bar=~modfen;
    wire mstr_and_ss=mstr & ss_bar;
    wire modf=mstr_and_ss & modfen_bar & ssoe;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            SPI_SR<=8'b0010_0000;
        else
            SPI_SR<={spif, 1'b0, sptef, modf, 4'b0000};
    end

    wire mux_receive_zero=(receive_data && spi_run_or_wait) ? 1'b0 : 1'b0;
    wire mux_condition_check=((SPI_DR==PWDATA) && (SPI_DR != miso_data) && spi_run_or_wait) ? 1'b1 : mux_receive_zero;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            send_data<=1'b0;
        else if (!wr_enb)
            send_data<=mux_condition_check;
    end

    always @(*) begin
        if (rd_enb) begin
            case (PADDR)
                3'b000: PRDATA=SPI_CR_1;
                3'b001: PRDATA=SPI_CR_2;
                3'b010: PRDATA=SPI_BR;
                3'b011: PRDATA=SPI_SR;
                3'b101: PRDATA=SPI_DR;
                default: PRDATA=8'b0;
            endcase
        end else begin
            PRDATA=8'b0;
        end
    end

    // assign spi_interrupt_request=SPI_CR_1[7] & (spif | modf);
    // assign mosi_data=lsbfe ? SPI_DR[0] : SPI_DR[7];
    assign spi_mode=spi_controller_state;

    assign spi_interrupt_request=( !spie && !sptie )?0: ( spie && !sptie )? (spif || modf ):( !spie && sptie )? sptef :(spif || sptef || modf );//given logic 
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) mosi_data<=1'b0;
        else if (((SPI_DR==PWDATA) && (SPI_DR != miso_data)) && 
                ((spi_mode==SPI_RUN) || (spi_mode==SPI_WAIT)) && 
                ~wr_enb) begin
            mosi_data<=lsbfe ? SPI_DR[0] : SPI_DR[7];
        end
    end


endmodule
