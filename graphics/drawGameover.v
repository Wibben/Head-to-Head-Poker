// FSM for drawing the game over notification
module drawGameover(
	input clock,resetn,go,
	input[14:0] money_negreanu,
	output reg ld_xy,ld_pos,ld_colour,
	output reg draw_pixel,done,
	output reg[8:0] dx,dy,
	output[8:0] x,y,
	output[8:0] colour
	);
	
	// x and y positions are fixed
	assign x = 9'd30;
	assign y = 9'd222;
	
	// Size of action word
	localparam 	X_GAMEOVER = 9'd270,
					Y_GAMEOVER = 9'd14;
	
	// Keeps track of state
	reg[2:0] current_state,next_state;
	
	// Internal controls
	reg reset_dx,reset_dy,inc_dx,inc_dy;
	
	// Assigning state variables
	localparam 	S_LOAD		= 3'd0,
					S_SET_UP		= 3'd1,
					S_DRAW_0 	= 3'd2,
					S_DRAW_1 	= 3'd3,
					S_DRAW_2 	= 3'd4,
					S_DRAW_3 	= 3'd5,
					S_DRAW_4 	= 3'd6,
					S_DRAW_DONE = 3'd7;
	
	// Counter registers for dx,dy, and delay
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			dx <= 9'b0;
			dy <= 9'b0;
		end
		else
		begin
			// dx counter
			if(reset_dx)
				dx <= 9'b0;
			else if(inc_dx)
				dx <= (dx==X_GAMEOVER-1) ? (9'b0):(dx+1);
			
			// dy counter
			if(reset_dy)
				dy <= 9'b0;
			else if(inc_dy)
				dy <= (dy==Y_GAMEOVER-1) ? (9'b0):(dy+1);
		end
	end
	
	// ROM module with the numbers
	wire[13:0] address;
	
	assign address = ((dy+1)*272+dx+1) + (money_negreanu==0)*15*272;
	
	gameover gover(
		.clock(clock),
		.address(address),
		.q(colour)
	);
	
	// State table
	always @(*)
	begin
		case(current_state)
			S_LOAD: // Wait for go signal
				next_state = go ? S_SET_UP:S_LOAD;
			S_SET_UP: // Set x,y, reset dy
				next_state = S_DRAW_0;
			S_DRAW_0: // Reset dx
				next_state = S_DRAW_1;
			S_DRAW_1: // Set pixel fill position
				next_state = S_DRAW_2;
			S_DRAW_2: // Fill pixel
				next_state = S_DRAW_3;
			S_DRAW_3: // Increment dx
				next_state = (dx==X_GAMEOVER-1) ? S_DRAW_4:S_DRAW_1;
			S_DRAW_4: // Increment dy
				next_state = (dy==Y_GAMEOVER-1) ? S_DRAW_DONE:S_DRAW_0;
			S_DRAW_DONE: // Signal action drawing is done
				next_state = S_LOAD;
			default: next_state = S_LOAD;
		endcase
	end
	
	// Changing control signals
	always @(*)
	begin
		// Internal controls
		reset_dx = 0; reset_dy = 0; inc_dx = 0; inc_dy = 0;
		
		// External controls
		ld_xy = 0; ld_pos = 0; ld_colour = 0;
		draw_pixel = 0; done = 0;
	
		case(current_state)
			S_SET_UP: // Set x,y, reset dy
			begin
				ld_xy = 1;
				reset_dy = 1;
			end
			S_DRAW_0: // Reset dx
			begin
				reset_dx = 1;
			end
			S_DRAW_1: // Set pixel fill position
			begin
				ld_pos = 1;
				ld_colour = 1;
			end
			S_DRAW_2: // Fill pixel
			begin
				draw_pixel = 1;
			end
			S_DRAW_3: // Increment dx
			begin
				inc_dx = 1;
			end
			S_DRAW_4: // Increment dy
			begin
				inc_dy = 1;
			end
			S_DRAW_DONE: // Signal action drawing is done
			begin
				done = 1;
			end
		endcase
	end
	
	// Register for current state
	always @(posedge clock)
	begin
		if(!resetn) // Reset to value input, active low
			current_state <= S_LOAD;
		else // Load next state
			current_state <= next_state;
	end
endmodule
