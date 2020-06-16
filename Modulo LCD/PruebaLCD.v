//Test showing 'Hello world'


module top(
  clock_100,
  push_button,
  rs,
  e,
  d,
);

input clock_100;
input push_button;
output rs;
output e;
output [7:0] d;

reg internal_reset = 1'b0;
reg last_signal = 1'b0;
wire clean_signal;
wire data_ready;
wire lcd_busy;
wire [8:0] d_in;
wire [3:0] rom_in;

lcd lcd(
  .clock(clock_100),
  .internal_reset(internal_reset),
  .d_in(d_in),
  .data_ready(data_ready),
  .rs(rs),
  .e(e),
  .d(d),
  .busy_flag(lcd_busy)
);

rom rom(
.rom_in(rom_in),
.rom_out(d_in)
);

controller controller (
  .clock(clock_100),
  .lcd_busy(lcd_busy),
  .internal_reset(internal_reset),
  .rom_address(rom_in),
  .data_ready(data_ready)
);

debounce debounce(
  .clk (clock_100),
  .in  (push_button),
  .out (clean_signal)
);

always @ (posedge clock_100) begin
  if (last_signal != clean_signal) begin
    last_signal <= clean_signal;
    if (clean_signal == 1'b0) begin
      internal_reset <= 1'b1;
    end
  end
  else begin
    internal_reset <= 1'b0;
  end
end

endmodule

//-------------------------------------------------------

module lcd(
  clock,
  internal_reset,
  d_in,
  data_ready,
  rs,
  e,
  d,
  busy_flag
);

parameter CLK_FREQ = 100000000;

parameter integer D_50ns  = 0.000000050 * CLK_FREQ;
parameter integer D_250ns = 0.000000250 * CLK_FREQ;

parameter integer D_40us  = 0.000040000 * CLK_FREQ;
parameter integer D_60us  = 0.000060000 * CLK_FREQ;
parameter integer D_200us = 0.000200000 * CLK_FREQ;

parameter integer D_2ms   = 0.002000000 * CLK_FREQ;
parameter integer D_5ms   = 0.005000000 * CLK_FREQ;
parameter integer D_100ms = 0.100000000 * CLK_FREQ;

parameter STATE00 = 5'b00000;
parameter STATE01 = 5'b00001;
parameter STATE02 = 5'b00010;
parameter STATE03 = 5'b00011;
parameter STATE04 = 5'b00100;
parameter STATE05 = 5'b00101;
parameter STATE06 = 5'b00110;
parameter STATE07 = 5'b00111;
parameter STATE08 = 5'b01000;
parameter STATE09 = 5'b01001;
parameter STATE10 = 5'b01010;
parameter STATE11 = 5'b01011;
parameter STATE12 = 5'b01100;
parameter STATE13 = 5'b01101;
parameter STATE14 = 5'b01110;
parameter STATE15 = 5'b01111;
parameter STATE16 = 5'b10000;
parameter STATE17 = 5'b10001;
parameter STATE18 = 5'b10010;
parameter STATE19 = 5'b10011;
parameter STATE20 = 5'b10100;
parameter STATE21 = 5'b10101;
parameter STATE22 = 5'b10110;
parameter STATE23 = 5'b10111;
parameter STATE24 = 5'b11000;
parameter STATE25 = 5'b11001;

input clock;
input internal_reset;
input [8:0] d_in;
input data_ready;
output rs;
output e;
output [7:0] d;
output busy_flag;

reg rs = 1'b0;
reg e = 1'b0;
reg [7:0] d = 8'b00000000;
reg busy_flag = 1'b0;

reg [4:0] state = 5'b00000;
reg [23:0] count = 24'h000000;
reg start = 1'b0;

always @(posedge clock) begin
  if (data_ready) begin
    start <= 1'b1;
  end
  if (internal_reset) begin
     state <= 5'b00000;
     count <= 24'h000000;    
  end

case (state)

  // Step 1 - 100ms delay after power on
  STATE00: begin                        
    busy_flag <= 1'b1;                  // tells other modules LCD is processing
    if (count == D_100ms) begin         // if 100ms have elapsed
      rs <= 1'b0;                       // pull RS low to indicate instruction
      d  <= 8'b00110000;                // set data to Function Set instruction
      count <= 24'h000000;              // clear the counter
      state <= STATE01;                 // advance to the next state
    end
    else begin                          // if 100ms have not elapsed
      count <= count + 24'h000001;      // increment the counter
    end
  end

  // Steps 2 thru 4 raise and lower the enable pin three times to enter the 
  // Function Set instruction that was loaded to the databus in STATE00 above

  // Step 2 - first Function Set instruction
  STATE01: begin                        
    if (count == D_50ns) begin          // if 50ns have elapsed (lets RS and D settle)
      e <= 1'b1;                        // bring E high to initiate data write    
      count <= 24'h000000;              // clear the counter
      state <= STATE02;                 // advance to the next state
    end
    else begin                          // otherwise
      count <= count + 24'h000001;      // increment the counter
    end
  end
  STATE02: begin                         
    if (count == D_250ns) begin         // if 250ns have elapsed
      e <= 1'b0;                        // bring E low   
      count <= 24'h000000;              // clear the counter 
      state <= STATE03;                 // advance to the next state
    end
    else begin                          // otherwise
      count <= count + 24'h000001;      // increment the counter
    end
  end
  STATE03: begin
    if (count == D_5ms) begin           // if 5ms have elapsed
      e <= 1'b1;                        // bring E high to initiate data write   
      count <= 24'h000000;              // clear the counter      
      state <= STATE04;                 // advance to the next state               
    end
    else begin                          // otherwise
      count <= count + 24'h000001;      // increment the counter
    end
  end

 // Step 3 - second Function Set instruction
  STATE04: begin
    if (count == D_250ns) begin         
      e <= 1'b0;                            
      count <= 24'h000000;              
      state <= STATE05;                   
    end
    else begin                          
      count <= count + 24'h000001;      
    end
  end
  STATE05: begin
    if (count == D_200us) begin         
      e <= 1'b1;                           
      count <= 24'h000000; 
      state <= STATE06;
      end
    else begin
      count <= count + 24'h000001;
    end
    end

  // Step 4 - third and final Function Set instruction
  STATE06: begin
    if (count == D_250ns) begin        
      e <= 1'b0;      
      count <= 24'h000000;
      state <= STATE07;                          
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE07: begin
    if (count == D_200us) begin         
      d  <= 8'b00111000;                // Configuration: 8-bit, 2 lines, 5x7 font 
      count <= 24'h000000;               
      state <= STATE08;
    end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Step 5 - enter the Configuation command
  STATE08: begin                        
    if (count == D_50ns) begin          
      e <= 1'b1; 
      count <= 24'h000000; 
      state <= STATE09;
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE09: begin                        
    if (count == D_250ns) begin         
      e <= 1'b0; 
      count <= 24'h000000; 
      state <= STATE10;
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE10: begin
    if (count == D_60us) begin         
      d  <= 8'b00001000;                // Display Off command
      count <= 24'h000000;
      state <= STATE11;
    end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Step 6 - enter the Display Off command
  STATE11: begin                        
    if (count == D_50ns) begin          
      e <= 1'b1;                       
      count <= 24'h000000; 
      state <= STATE12;
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE12: begin                        
    if (count == D_250ns) begin         
      e <= 1'b0;
      count <= 24'h000000;
      state <= STATE13;
    
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE13: begin
    if (count == D_60us) begin          
      d  <= 8'b00000001;                // Clear command
      count <= 24'h000000; 
      state <= STATE14;
     end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Step 7 - enter the Clear command
  STATE14: begin                        
    if (count == D_50ns) begin          
      e <= 1'b1;
      count <= 24'h000000;
      state <= STATE15;   
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE15: begin                        
    if (count == D_250ns) begin         
      e <= 1'b0;
      count <= 24'h000000;
      state <= STATE16;     
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE16: begin
    if (count == D_5ms) begin           
      d  <= 8'b00000110;                // Entry Mode:cursor moves, display stands still  
      count <= 24'h000000; 
      state <= STATE17;
     end
    else begin
      count <= count + 24'h000001;
    end
  end

  //Step 8 - Set the Entry Mode
  STATE17: begin                        
    if (count == D_50ns) begin          
      e <= 1'b1;   
      count <= 24'h000000; 
      state <= STATE18;
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE18: begin                        
    if (count == D_250ns) begin         
      e <= 1'b0;  
      count <= 24'h000000;
      state <= STATE19;    
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE19: begin
    if (count == D_60us) begin          
      d  <= 8'b00001100;                // Display On
      count <= 24'h000000;
      state <= STATE20;
    end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Step 9 - enter the Display On command
  STATE20: begin                        
    if (count == D_50ns) begin          
      e <= 1'b1;
      count <= 24'h000000;
      state <= STATE21;
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE21: begin                        
    if (count == D_250ns) begin         
      e <= 1'b0;
      count <= 24'h000000;
      state <= STATE22;
    end
    else begin
      count <= count + 24'h000001;
    end
  end
  STATE22: begin
    if (count == D_60us) begin          // 60us
      busy_flag <= 1'b0;                // clear the busy flag
      count <= 24'h000000; 
      state <= STATE23;  
    end
    else begin
      count <= count + 24'h000001;
    end
  end

// End Initialization - Start entering data.

  STATE23: begin
    if (start) begin                      // wait for data            
      if (count == 24'h000000) begin      // if this is the first iteration of STATE23 
        busy_flag <= 1'b1;                // set the busy flag
        rs <= d_in[8];                    // read the RS value from input       
        d  <= d_in[7:0];                  // read the data value input     
        count <= count + 24'h000001;      // increment the counter
      end  
      else if (count == D_50ns) begin     // if 50ns have elapsed
       count <= 24'h000000;               // clear the counter
       state <= STATE24;                  // advance to the next state
       end
      else begin                          // if it's not the first or last
        count <= count + 24'h000001;      // increment the counter
      end
    end
  end
  STATE24: begin                        
    if (count == 24'h000000) begin        // if this is the first iteration of STATE24
      e <= 1'b1;                          // bring E high to initiate data write
      count <= count + 24'h000001;        // increment the counter
    end
    else if (count == D_250ns) begin      // if 250ns have elapsed
      count <= 24'h000000;                // clear the counter
      state <= STATE25;                   // advance to the next state
    end
    else begin                            // if it's not the first or last
      count <= count + 24'h00000001;      // increment the counter
    end
  end
  STATE25: begin
    if (count == 24'h000000) begin        // if this is the first iteration of STATE25
      e <= 1'b0;                          // bring E low
      count <= count + 24'h000001;        // increment the counter
    end
    else if (count == D_40us && rs == 1'b1) begin  // if data is a character and 40us has elapsed
      start <= 1'b0;                      // clear the start flag
      busy_flag <= 1'b0;                  // clear the busy flag
      count <= 24'h000000;                // clear the counter 
      state <= STATE23;                   // go back to STATE23 and wait for next data
    end
    else if (count == D_2ms && rs == 1'b0) begin // if data is a command and 2ms has elapsed
      start <= 1'b0;                      // clear the start flag
      busy_flag <= 1'b0;                  // clear the busy flag
      count <= 24'h000000;                // clear the counter 
      state <= STATE23;                   // go back to STATE23 and wait for next data
    end
    else begin                            // if it's not the first or last
      count <= count + 24'h000001;        // increment the counter
    end
  end
  default: ;
endcase

end

endmodule

//------------------------------------
module controller (
  clock,
  lcd_busy,
  internal_reset,
  rom_address,
  data_ready
);

input clock;
input lcd_busy;
input internal_reset;
output [3:0] rom_address;
output data_ready;

reg [3:0] rom_address = 4'b0000;
reg data_ready = 1'b0;
reg current_lcd_state = 1'b0;
reg halt = 1'b0;

always @ (posedge clock) begin

  // resets the demo on the push button
  if (internal_reset) begin             
     rom_address <= 4'b0000;
     data_ready <= 1'b0;
     current_lcd_state <= 1'b0;
     halt <= 1'b0;
  end

  // stops the demo after one run through the ROM
  if (rom_address == 4'b1111) begin    
    halt <= 1'b1;
    data_ready <= 1'b0;
    rom_address <= 4'b0000;
    //test_trig <= 1;
  end

  // prevent the system from sending 
  // the first character during initialization
  if (rom_address == 4'b0000 && halt == 1'b0) begin  
    current_lcd_state <= 1'b1;                       
  end

  // this logic monitors the LCD module busy flag
  // when the LCD goes from busy to free, the controller raises the 
  // data ready flag and the output of the ROM is presented to the LCD module
  // when the LCD goes from free to busy, the controller increments the
  // ROM address to be ready for the next cycle
                               
  if (halt == 1'b0) begin                        
    if (current_lcd_state != lcd_busy) begin   
      current_lcd_state <= lcd_busy;
      if (lcd_busy == 1'b0) begin
        data_ready <= 1'b1;
      end
      else if (lcd_busy == 1'b1) begin
        rom_address <= rom_address + 4'b0001;
        data_ready <= 1'b0;
      end
    end
  end
end



endmodule



//------------------------------------

module debounce (
  clk,
  in,
  out
);

input clk;
input in;
output out;

reg out;

wire delta;
reg [19:0] timer;

initial timer = 20'b0;
initial out = 1'b0;

assign delta = in ^ out;

always @(posedge clk) begin
  if (timer[19]) begin
    out <= in;
    timer <= 20'b0;
  end
  else if (delta) begin
    timer <= timer + 20'b1;
  end
  else begin
    timer <= 20'b0;
  end
end


endmodule
//--------------------------------------
module rom (
rom_in   , // Address input
rom_out    // Data output
);
input [3:0] rom_in;
output [8:0] rom_out;

reg [8:0] rom_out;
     
always @*
begin
  case (rom_in)
   4'h0: rom_out = 9'b101001000;
   4'h1: rom_out = 9'b101100101;
   4'h2: rom_out = 9'b101101100;
   4'h3: rom_out = 9'b101101100;
   4'h4: rom_out = 9'b101101111;
   4'h5: rom_out = 9'b011000000;
   4'h6: rom_out = 9'b101010111;
   4'h7: rom_out = 9'b101101111;
   4'h8: rom_out = 9'b101110010;
   4'h9: rom_out = 9'b101101100;
   4'ha: rom_out = 9'b101100100;
   4'hb: rom_out = 9'b100100000;
   4'hc: rom_out = 9'b100100000;
   4'hd: rom_out = 9'b100100000;
   4'he: rom_out = 9'b100100000;
   4'hf: rom_out = 9'b100100000;
   default: rom_out = 9'hXXX;
  endcase
end



endmodule

