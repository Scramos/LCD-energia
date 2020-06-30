
`include "baudgen.vh"

module Top(
			input clk,
			input [3:0] datoAgua,
			input [3:0] datoPeso,
			output wire tx,
			output [1:0] stat
			);

	//Cables y registros para conexión de modulos 

	parameter BAUD = `B115200;

		reg resetUart = 0;
		reg startUart;

		wire [3:0] Comida;
		wire [3:0] Agua;

		wire [7:0] comidaFinal;
		wire [7:0] aguaFinal;
		assign comidaFinal = 8'b01111011;
		assign aguaFinal = 8'b01111101;
		reg [7:0] data;

		reg counter;
		reg cena;
		wire readyUart;

		reg divStart = 0;
		wire divOut;

	//Instanciación modulos

	always @(posedge clk) begin
		resetUart <= 1;
	end

	uart_tx #(.BAUD(BAUD)) Uart_txComida(
			.clk(clk),
			.rstn(resetUart),
			.start(startUart),
			.data(data),
			.tx(tx),
			.ready(readyUart)
			);

	aguaMedida medicionAgua(
			.clk(clk),
			.agua(datoAgua),
			.salidaAgua(Agua)
			);

	pesoMedida medicionComida(
			.clk(clk),
			.peso(datoPeso),
			.salidaPeso(Comida)
			);

	always @*
  		case (counter)
    		1'b0: data <= comidaFinal;
   			1'b1: data <= aguaFinal;
    		default: data <= ".";
  		endcase


  	always @(posedge clk)
		if (resetUart == 0)
    		counter = 0;
  		else if (cena)
    		counter = counter + 1;

	divisorTop divider(
		.clk(clk),
		.inicio(divStart),
		.CLKOUT(divOut)
		);

	// Máquina de estados para el control de las señales

	reg [1:0] state = START;
	parameter START=0, S1=1, S2=2, WAIT=3;
	assign stat = state;



	always @ (posedge clk)
	begin

		case(state)
			
			START: begin 
				divStart <= 1;
					if(divOut) begin 
						state <= S1;
						divStart <= 0;
					end
					else state <= START;
			end
		
			S1:  begin
				if(readyUart == 1) state <= S2;
				else state <= S1;
			end

			S2: begin
				if(counter == 1) state <= WAIT;
				else state <= S1;
			end

			WAIT: begin
				divStart <= 1;
					if(divOut) begin 
						state <= START;
						divStart <= 0;
					end
					else state <= WAIT;
			end

			default: state <= START;

		endcase

	end

	always @*

			case(state)
				START: begin
					startUart <= 0;
					cena <= 0;
				end

				S1: begin
					startUart <= 1;
					cena <= 0;
				end

				S2: begin  
					startUart <= 0;
					cena <= 1;
				end

				WAIT: begin
					startUart <= 0;
					cena <= 0;
				end

				default: begin 
					startUart <= 0;
					cena <= 0;
				end

			endcase

endmodule
