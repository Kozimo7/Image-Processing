`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output filter_done);	// semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)

// TODO add your finite state machines here

endmodule
