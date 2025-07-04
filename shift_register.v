`timescale 1ns/1ps

module shift_reg (
    input   PCLK,
    input   PRESETn,
    input   ss,
    input   send_data,
    input   receive_data,
    input   lsbfe,
    input   cpha,
    input   cpol,
    input   flag_low,
    input   flag_high,
    input   flags_low,
    input   flags_high,
    input   [7:0]  data_mosi,//transmited data
    input   miso,
    output  reg mosi,
    output  [7:0]  data_miso//received data
);
//BASED ON PROVIDED ARCHITECTURE

reg [2:0] count,count1,count2,count3;
reg [7:0] shift_register,temp_reg;

wire condition_one;
assign condition_one =cpha ^ cpol;

assign data_miso = (receive_data)? temp_reg:8'h00;

always @(posedge PCLK or negedge PRESETn) begin 
    if (!PRESETn)   shift_register<=8'b0;
    else      shift_register<= send_data? data_mosi:shift_register;
end 

always @(posedge PCLK or negedge PRESETn) begin///mosi logic..condition_one redundant logic wise
    if (!PRESETn || ss)     mosi<=1'b0;
    else begin
        if (lsbfe) begin//lsb first
      if (count <=3'd7) begin
    if ((condition_one && flags_high)||(!condition_one && flags_low))//nested if to be used based on arch
        mosi<=shift_register[count];      //instead used ||
      end
        end else begin//msb first
      if (count1 >=3'd0) begin
    if ((condition_one && flags_high)||(!condition_one && flags_low))//modified
        mosi<=shift_register[count1];
      end
        end
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn || ss) begin
        count<=3'b000;
        count1<=3'b111;
    end else begin
        if (lsbfe) begin
      if ((condition_one && flags_high) || (!condition_one && flags_low)) begin
    count<=(count <= 3'd7) ? (count + 1'b1):3'd0;//inc LSB counter(transmitting)
      end
        end else begin
      if ((condition_one && flags_high) || (!condition_one && flags_low)) begin
    count1<=(count1 > 3'd0) ? (count1 - 1'b1):3'd7;//dec MSB counter(transmitting)
      end
      
        end
    end
    
end


always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn || ss) begin 
        count2<=3'b000;
        count3<=3'b111;
    end else begin
        if (lsbfe) begin
      if ((condition_one && flag_high) || (!condition_one && flag_low)) begin//modified arch..used ||
    count2<=(count2 <= 3'd7)? (count2 + 1'b1):3'd0;//inc LSB counter(receiving)
      end
        end else begin
      if ((condition_one && flag_high) || (!condition_one && flag_low)) begin//modified arch
    count3<=(count3 > 3'd0)? (count3 - 1'b1):3'd7;//dec MSB(rx)
      end
      
        end
    end
    
end


always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)       temp_reg<=8'b0;
    else begin
        if (!ss) begin
      if (lsbfe) begin
    if (((flag_high || flag_low)&&(count2<=3'd7)))//modified arch..used ||
        temp_reg[count2]<=miso;//store bit in LSB
      end else begin
    if (((flag_high || flag_low)&&(count3 >= 3'd0))) //modified arch..used ||
        temp_reg[count3]<=miso;//store bit in MSB
    
      end
        end
    end
end




endmodule
