// Modifies data and outputs depending on control signals
module datapath(
	input clock,resetn,
	input[8:0] X_IN,Y_IN,
	input[8:0] COLOUR_DATA,
	input ld_xy,ld_colour,ld_pos,
	input[8:0] dx,dy,
	output reg[8:0] xpos,
	output reg[8:0] ypos,
	output reg[8:0] colour
	);
	
	// Internal registers
	reg[8:0] x,y;
	
	// Registers x,y,xpos,ypos and colour with input logic
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			x <= 9'b0;
			y <= 9'b0;
			xpos <= 9'b0;
			ypos <= 9'b0;
			colour <= 9'b0;
		end
		else
		begin
			// x and register
			if(ld_xy)
			begin
				x <= X_IN;
				y <= Y_IN;
			end
			// xpos and ypos registers (for drawing shape)
			if(ld_pos)
			begin
				xpos <= x+dx;
				ypos <= y+dy;
			end
			// colour register
			if(ld_colour)
				colour <= COLOUR_DATA;
		end
	end
endmodule
