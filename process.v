`timescale 1ns / 1ps

module process(
	input clk,				// clock 
	input [23:0] in_pix,	// valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
	output reg [5:0] row, col, 	// selecteaza un rand si o coloana din imagine
	output reg out_we, 			// activeaza scrierea pentru imaginea de iesire (write enable)
	output reg [23:0] out_pix,	// valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
	output reg mirror_done,		// semnaleaza terminarea actiunii de oglindire (activ pe 1)
	output reg gray_done,		// semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
	output reg filter_done);	// semnaleaza terminarea actiunii de aplicare a filtrului de sharpness (activ pe 1)
	
	// TODO add your finite state machines here

// Parameters for finite state machine
reg [5:0] next_row, next_col;

parameter mirror_0 = 0;	// declaring the states of the finite state machine
parameter mirror_1 = 1;
parameter mirror_2 = 2;
parameter mirror_3 = 3;
parameter mirror_4 = 4;
parameter mirror_5 = 5;

parameter grayscale_0 = 6;
parameter grayscale_1 = 7;
parameter grayscale_2 = 8;

parameter filter_0 = 9;
parameter filter_1 = 10;
parameter filter_2 = 11;
parameter filter_3 = 12;
parameter filter_4 = 13;
parameter filter_5 = 14;
parameter filter_6 = 15;
parameter filter_7 = 16;
parameter filter_8 = 17;
parameter filter_9 = 18;
parameter filter_10 = 19;
parameter filter_11 = 20;
parameter filter_12 = 21;

reg [4:0] state = mirror_0;
reg [4:0] next_state = mirror_0;

// Parameters for mirror
reg [23:0] aux1_pix;	// auxiliary pixel 1, to retain the current pixel value
reg [23:0] aux2_pix;	// auxiliary pixel 2, to retain the mirrored pixel value

// Parameters for grayscale
reg [7:0] R;	// Red channel
reg [7:0] G;	// Green channel
reg [7:0] B;	// Blue channel

reg [7:0] max_value;	// maximum value between the rgb values
reg [7:0] min_value;	// minimum value between the rgb values
reg [7:0] gray_value;	// grayscale value

// Parameters for filter
reg [5:0] aux_row;	// auxiliary row, to retain the original row
reg [5:0] aux_col;	// auxiliary column, to retain the original column
reg [23:0] sum;	// sum of the filter, to be written in the output pixel

// Finite State Machine

always @(posedge clk) begin	// the finite state machine is activated on the rising edge of the clock
	state <= next_state;	// the current state is updated with the next state
    row <= next_row;	// the row is updated with the next row
    col <= next_col;	// the column is updated with the next column
	out_we = 0; 
end

always @(*) begin	// the finite state machine is activated on any change of clock or input
	case (state)
		// Mirror
		mirror_0: begin	// initial state for the mirror parameters
		    next_row = 0;
			next_col = 0;
			mirror_done = 0;
			next_state = mirror_1;
			end
			  
		mirror_1: begin	// retaining the current pixel value in aux1_pix
        	aux1_pix = in_pix;
			if(row < 32) begin	// if the row is less than 32, we are in the upper half of the image
			    next_row = 63 - row;	// the next row is the mirror of the current row
				next_state = mirror_2;
			end
			else begin	// else, the whole image was processed and mirror_done is activated
				mirror_done = 1;
				next_state = grayscale_0;
			end
		end
		  
		mirror_2: begin	// retaining the mirrored pixel value in aux2_pix
		    aux2_pix = in_pix;	
			out_we = 1;
			out_pix = aux1_pix;	// writing the current pixel value in the mirrored output pixel
			next_state = mirror_3;
		end 

		mirror_3: begin
			out_we = 0;
			next_row = 63 - row;	// the next row is the mirrored again, to the current row of the original pixel 
			next_state = mirror_4;
		end
			
		mirror_4: begin
			out_we = 1;
			out_pix = aux2_pix;	// writing the mirrored pixel value in the current output pixel
			next_state = mirror_5;
		end	  

        mirror_5: begin
        	if(col < 63) begin	// if the column is less than 63, we are not at the end of the row
				next_col = col + 1;	// and we move to the next column
			end
			else begin	// else, we are at the end of the row
			    next_row = row + 1;	// and we move to the next row
				next_col = 0;	// and reset the column to 0
			end
			next_state = mirror_1;
        end

		// Grayscale 	
		grayscale_0: begin	// inital state for the grayscale parameters
			next_row = 0;
			next_col = 0;
			gray_done = 0;
			next_state = grayscale_1;
		end
			
		grayscale_1: begin	// retaining the rgb values in separate variables
			R = in_pix[23:16];
			G = in_pix[15:8];
			B = in_pix[7:0];
				
			max_value = R;	// determining the max/min value between the rgb values
			min_value = R;
				
			if(G > max_value)
				max_value = G;
				
			if(G < min_value)
				min_value = G;
				
			if(B > max_value)
				max_value = B;
				
			if(B < min_value)
				min_value = B;
				
			gray_value = (min_value + max_value) / 2;	// calculate the grayscale value
			out_we = 1;
			out_pix[7:0] = 0;	// write the grayscale value in the Green channel
			out_pix[15:8] = gray_value;	// the Red and Blue channels are set to 0
			out_pix[23:16] = 0;
				
			next_state = grayscale_2;
		end
			
		grayscale_2: begin
			out_we = 0;
			if(col < 63) begin // if the column is less than 63, we are not at the end of the row
				next_col = col + 1;	// and we move to the next column
				next_state = grayscale_1;
			end
			else begin
				if(row < 63) begin	// else, if the row is less than 63, we are not at the end of the image
					next_row = row + 1;	// and we move to the next row
					next_col = 0;	// and reset the column to 0
					next_state = grayscale_1;
				end
				else begin
					gray_done = 1;
					next_state = filter_0;
				end
			end
		end
	
		// Filter
		filter_0 : begin	// initial state for the filter parameters
			next_row = 1;
			next_col = 1;
			filter_done = 0;
			next_state = filter_1;
		end

		filter_1: begin
			// retaining the original row and col
			aux_row = row;
			aux_col = col;

			// resetting the sum
			sum[23:16] = 0;
			sum[15:8] = 0;
			sum[7:0] = 0;

			next_state = filter_2;
		end

		filter_2: begin
			// middle line
			sum[23:16] = sum[23:16] + in_pix[23:16] * 9;	// the current pixel is multiplied by 9 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * 9;
			sum[7:0] = sum[7:0] + in_pix[7:0] * 9;
			next_col = col - 1;	

            next_state = filter_3;
        end

        filter_3: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the left pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_col = col + 2;

            next_state = filter_4;
        end

        filter_4: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the right pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_row = row - 1;

            next_state = filter_5;
        end
			// upper line
        filter_5: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the upper right pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_col = col - 1;

            next_state = filter_6;
        end

        filter_6: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the upper pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_col = col - 1;

            next_state = filter_7;
        end
        
			
        filter_7: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the upper left pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_row = row + 2;

            next_state = filter_8;
        end
			// lower line
        filter_8: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the lower left pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_col = col + 1;

            next_state = filter_9;
        end

        filter_9: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the lower pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);
			next_col = col + 1;

            next_state = filter_10;
        end

        filter_10: begin
			sum[23:16] = sum[23:16] + in_pix[23:16] * (-1);	// the lower right pixel is multiplied by -1 and added to the sum
			sum[15:8] = sum[15:8] + in_pix[15:8] * (-1);
			sum[7:0] = sum[7:0] + in_pix[7:0] * (-1);

			next_row = aux_row;	// the row and column are reset to the original values
			next_col = aux_col;

			next_state = filter_11;
		end

		filter_11: begin
            out_we = 1;
			out_pix[23:16] = sum[23:16];	// the sum is written in the output pixel
			out_pix[15:8] = sum[15:8];
			out_pix[7:0] = sum[7:0];

			next_state = filter_12;
		end

		filter_12: begin
			out_we = 0;
			if(col < 62) begin	// if the column is less than 62, we are not at the end of the row
				next_col = col + 1;	// and we move to the next column
				next_state = filter_1;
			end
			else begin
				if(row < 62) begin	// else, if the row is less than 62, we are not at the end of the image
					next_row = row + 1;	// and we move to the next row
					next_col = 1;	// and reset the column to 1
					next_state = filter_1;
				end
				else begin
					filter_done = 1;
				end
			end
		end

	endcase
end

endmodule