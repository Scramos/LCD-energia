# LCD-energia.

En este repositorio se presenta la visualización de los datos obtenidos desde la base de datos. Inicialmente, se plantea mostrarlo en una pantalla LCD 16x2.

## Pantalla LCD

Se tiene que la pantalla LCD tiene los pines que se muestran a continuación: 
![](https://github.com/Scramos/LCD-energia/blob/master/Docs/lcdpines.png)

Los pines Vss y Vdd son tierra y alimentación respectivamente, V0 controla el contraste (puede que se llegue a necesitar un potenciometro), A y K son la alimentación para la retroiluminación, RS se usa para indicar si los datos en el bus con un caracter o una instrucción, E habilita la entrada de dato, R/W habilita o la lectura o la escritura en el dispositivo. Los ocho pines restantes son el bus de datos, que en este caso serán caracteres del código ASCII.

El controlador tiene un modo de 8 bits donde los caracteres y comandos se cargan un byte a la vez, y un modo de 4 bits donde los datos de 8 bits se cargan en dos paquetes de 4 bits.

## Funcionamiento

Inicialmente se plantea en el modulo una máquina de estados para generar los caracteres. Se utiliza un reloj de 100MHz que es el que tiene la tarjeta programable utilizada. 

Lo primero que se realiza es una inicialización para asegurarse de una recepción correcta del dato. Además, se debe tener en cuenta los retrazos que se generarn en cada ejecución de unsa instrucción. 

En este caso, se procesa los datos recibidos, que serán un bus de nueve datos (RS y DB0-7) por una maquina de estado de 26 pasos, de los cuales 23-25 se utilizan para la escritura en la LCD. Los otros son isntrucciones para realizar diferentes acciones, como enceder o apagar la pantalla, iniciar la entreda de datos o limpiar.

Se tendrá un dato de entrada dependiendo de lo que se entregue en la base de datos, también se tendrá un botón para la actualización de al base.

### Módulos

#### LCD

En este módulo se genera el funcionamiento de la pantalla LCD, para esto se tienen las entradas clock_100, push_button y datobase; las salidas rs, e y d. Los 23 estados mencionados anteriormente y así poder transmitir la información a la pantalla.

```verilog
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
```
Además, cuenta con un internal reset:

```verilog
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
```

#### baudgen.v y baudgen.vh

Son los módulos encargados de la generar transmisión de bits en una velocidad de 115200 baudios. En el fichero baudgen.vh se tiene valores de los divisores para transmitir a las velocidades estándares.
```verilog
`define B115200 217 
`define B57600  434
`define B38400  651
`define B19200  1302
`define B9600   2604
`define B4800   5208
`define B2400   10416
`define B1200   20833
`define B600    41666
`define B300    83333
```

Y en baudgen.v se genera una señal de reloj continua a la velocidad pedida. 
```verilog
always @(posedge clk)

  if (clk_ena)
    //-- Funcionamiento normal
    divcounter <= (divcounter == BAUD - 1) ? 0 : divcounter + 1;
  else
    //-- Contador "congelado" al valor maximo
    divcounter <= BAUD - 1;
```

Estos dos ejemplos se tomaron del repositorio de Juan Gonzales (Obijuan) que tiene una implementación de este estilo. 

#### uart_tx
Este protocolo es utilizado para comunicación serie entre dispositivos digitales. El UART toma bytes de datos y transmite los bits individuales de forma secuencial. En el destino, un segundo UART reensambla los bits en bytes completos. 
![](https://github.com/Scramos/LCD-energia/blob/master/Docs/UART2.jpeg)

Con este módulo se realiza la comunicación serial, tiene definido el parámetro para la velocidad de transmisión y wires para trabajar localmente la comunicación. Cuenta con un divisor, un contador, carga, desplazamiento, y un controlador. 
```verilog
(
    parameter BAUD = `B115200
    )
    (
         input wire clk,       
         input wire rstn,       
         input wire start,      
         input wire [7:0] data, 
         output reg tx,         
         output wire ready      
       );
```


#### PruebaLCD

Es el primer módulo utilizado para probar el funcionamiento de LCD con la tarjeta, tiene configurado un mensaje por defecto que se almacena en una rom para poder mostrarse en pantalla. 
```verilog
module rom (
rom_in   , 
rom_out    
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
```
