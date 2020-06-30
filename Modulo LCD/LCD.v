`include "baudgen.vh"

module LCD(
  clock_100,
  push_button,
  datobase,
  rs,
  e,
  d,
);

input clock_100;
input push_button;
input [31:0] datobase;
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

  // Delay 100ms después de prender
  STATE00: begin                        
    busy_flag <= 1'b1;                  
    if (count == D_100ms) begin         
      rs <= 1'b0;                       
      d  <= 8'b00110000;              
      count <= 24'h000000;              
      state <= STATE01;                 
    end
    else begin                          
      count <= count + 24'h000001;      
    end
  end

  

  // Primer set de instrucciones
  STATE01: begin                        
    if (count == D_50ns) begin         
      e <= 1'b1;                          
      count <= 24'h000000;              
      state <= STATE02;                 
    end
    else begin                          
      count <= count + 24'h000001;     
    end
  end
  STATE02: begin                         
    if (count == D_250ns) begin        
      e <= 1'b0;                         
      count <= 24'h000000;               
      state <= STATE03;                 
    end
    else begin                        
      count <= count + 24'h000001;      
    end
  end
  STATE03: begin
    if (count == D_5ms) begin           
      e <= 1'b1;                          
      count <= 24'h000000;                   
      state <= STATE04;                 
    else begin                          
      count <= count + 24'h000001;    
    end
  end

 // Segundo set de instrucciones
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

  // Ultimo set de instrucciones
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
      d  <= 8'b00111000;              
      count <= 24'h000000;               
      state <= STATE08;
    end
    else begin
      count <= count + 24'h000001;
    end
  end

  //Comando de configuración
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
      d  <= 8'b00001000;                
      count <= 24'h000000;
      state <= STATE11;
    end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Apagar el display
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
      d  <= 8'b00000001;                
      count <= 24'h000000; 
      state <= STATE14;
     end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Comando clear
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
      d  <= 8'b00000110;                  
      count <= 24'h000000; 
      state <= STATE17;
     end
    else begin
      count <= count + 24'h000001;
    end
  end

  //Modo de entrada
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
      d  <= 8'b00001100;                
      count <= 24'h000000;
      state <= STATE20;
    end
    else begin
      count <= count + 24'h000001;
    end
  end

  // Encender display
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
    if (count == D_60us) begin          
      busy_flag <= 1'b0;                
      count <= 24'h000000; 
      state <= STATE23;  
    end
    else begin
      count <= count + 24'h000001;
    end
  end

// Inicio de entrada de datos

  STATE23: begin
    if (start) begin                                
      if (count == 24'h000000) begin      
        busy_flag <= 1'b1;                
        rs <= d_in[8];                           
        d  <= d_in[7:0];                       
        count <= count + 24'h000001;      
      end  
      else if (count == D_50ns) begin     
       count <= 24'h000000;               
       state <= STATE24;                  
       end
      else begin                          
        count <= count + 24'h000001;      
      end
    end
  end
  STATE24: begin                        
    if (count == 24'h000000) begin        
      e <= 1'b1;                          
      count <= count + 24'h000001;        
    end
    else if (count == D_250ns) begin      
      count <= 24'h000000;                
      state <= STATE25;                   
    end
    else begin                            
      count <= count + 24'h00000001;      
    end
  end
  STATE25: begin
    if (count == 24'h000000) begin       
      e <= 1'b0;                          
      count <= count + 24'h000001;       
    end
    else if (count == D_40us && rs == 1'b1) begin  
      start <= 1'b0;                      
      busy_flag <= 1'b0;                  
      count <= 24'h000000;               
      state <= STATE23;                  
    end
    else if (count == D_2ms && rs == 1'b0) begin 
      start <= 1'b0;                      
      busy_flag <= 1'b0;                  
      count <= 24'h000000;                 
      state <= STATE23;                   
    end
    else begin                           
      count <= count + 24'h000001;        
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

  // reset
  if (internal_reset) begin             
     rom_address <= 4'b0000;
     data_ready <= 1'b0;
     current_lcd_state <= 1'b0;
     halt <= 1'b0;
  end

  // stop
  if (rom_address == 4'b1111) begin    
    halt <= 1'b1;
    data_ready <= 1'b0;
    rom_address <= 4'b0000;
   
  end

  
  if (rom_address == 4'b0000 && halt == 1'b0) begin  
    current_lcd_state <= 1'b1;                       
  end

  
                               
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
