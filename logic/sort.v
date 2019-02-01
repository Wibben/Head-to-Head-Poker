//sort cards
module sort (input  wire clk,input  wire[41:0] card_in, output reg[41:0] card_out);
	reg [5:0] dat1, dat2, dat3, dat4, dat5, dat6, dat7;
	always @(posedge clk)
		begin
			dat1 <= card_in[5:0];
			dat2 <= card_in[11:6];
			dat3 <= card_in[17:12];
			dat4 <= card_in[23:18];
			dat5 <= card_in[29:24];
			dat6 <= card_in[35:30];
			dat7 <= card_in[41:36];
		end
	integer i, j;
	reg [5:0] temp;
	reg [5:0] array [1:7];
	always @(*)
		begin
			array[1] = dat1;
			array[2] = dat2;
			array[3] = dat3;
			array[4] = dat4;
			array[5] = dat5;
			array[6] = dat6;
			array[7] = dat7;
			temp = 6'd0;
			for (i = 7; i > 0; i = i - 1) 
				begin
					for (j = 1 ; j < i; j = j + 1) 
						begin
							if (array[j][3:0] < array[j + 1][3:0])
								begin
									temp = array[j];
									array[j] = array[j + 1];
									array[j + 1] = temp;
								end 			
						end
				end 
		end
	always @(posedge clk)
		begin
			card_out[41:36] <= array[1];
			card_out[35:30] <= array[2];
			card_out[29:24] <= array[3];
			card_out[23:18] <= array[4];
			card_out[17:12] <= array[5];
			card_out[11:6] <= array[6];
			card_out[5:0] <= array[7];
		end
endmodule 
