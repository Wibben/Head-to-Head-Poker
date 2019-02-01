// FSM for drawing decision to screen
// Waits 1.5 seconds then erases it
module drawAction(
	input clock,resetn,go,
	input[2:0] suggested_action,
	output reg ld_xy,ld_pos,ld_colour,
	output reg draw_pixel,done,
	output reg[8:0] dx,dy,
	output[8:0] x,y,
	output[8:0] colour
	);
	
	// x and y positions are fixed
	assign x = 9'd230;
	assign y = 9'd20;
	
	// Size of action word
	localparam 	X_ACTION = 9'd60,
					Y_ACTION = 9'd14;
					
	// Keeps track of state
	reg[3:0] current_state,next_state;
	
	// Internal controls
	reg reset_dx,reset_dy,inc_dx,inc_dy;
	reg draw,reset_draw,erase;
	reg reset_delay;
	reg[26:0] delay_counter;
	
	// Assigning state variables
	localparam 	S_LOAD 		= 4'd0,
					S_SET_UP		= 4'd1,
					S_DRAW_0 	= 4'd2,
					S_DRAW_1 	= 4'd3,
					S_DRAW_2 	= 4'd4,
					S_DRAW_3 	= 4'd5,
					S_DRAW_4 	= 4'd6,
					S_DELAY		= 4'd7,
					S_DRAW_DONE = 4'd8;
	
	// Counter registers for dx,dy, and delay
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			dx <= 9'b0;
			dy <= 9'b0;
			delay_counter <= 27'd75000000-1;
		end
		else
		begin
			// dx counter
			if(reset_dx)
				dx <= 9'b0;
			else if(inc_dx)
				dx <= (dx==X_ACTION-1) ? (9'b0):(dx+1);
			
			// dy counter
			if(reset_dy)
				dy <= 9'b0;
			else if(inc_dy)
				dy <= (dy==Y_ACTION-1) ? (9'b0):(dy+1);
			
			// Delay counter
			if(reset_delay)
				delay_counter <= 27'd75000000-1;
			else
				delay_counter <= delay_counter-1;
		end
	end
	
	// Register for whether it's drawing or erasing
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			draw <= 1'b1;
		else if(reset_draw)
			draw <= 1'b1;
		else if(erase)
			draw <= 1'b0;
	end
	
	// ROM module with the numbers
	reg[12:0] address;
	
	always @(*)
	begin
		if(draw)
			address = ((dy+1)*62+dx+1) + suggested_action*15*62;
		else // Blank
			address = ((dy+1)*62+dx+1) + 7*15*62;
	end
	
	action ac(
		.clock(clock),
		.address(address),
		.q(colour)
	);
	
	// State table
	always @(*)
	begin
		case(current_state)
			S_LOAD: // Loop until signal goes for drawing to start
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
				next_state = (dx==X_ACTION-1) ? S_DRAW_4:S_DRAW_1;
			S_DRAW_4: // Increment dy
			begin
				if(dy==Y_ACTION-1)
					next_state = draw ? S_DELAY:S_DRAW_DONE;
				else
					next_state = S_DRAW_0;
			end
			S_DELAY: // 1.5 second delay
				next_state = (delay_counter==0) ? S_SET_UP:S_DELAY;
			S_DRAW_DONE: // Signal action drawing is done
				next_state = S_LOAD;
			default: next_state = S_LOAD;
		endcase
	end
	
	// Changing control signals
	always @(*)
	begin
		// Internal controls
		reset_draw = 0; erase = 0; reset_delay = 0;
		reset_dx = 0; reset_dy = 0; inc_dx = 0; inc_dy = 0;
		
		// External controls
		ld_xy = 0; ld_pos = 0; ld_colour = 0;
		draw_pixel = 0; done = 0;
	
		case(current_state)
			S_LOAD: // Loop until signal goes for drawing to start
			begin
				reset_draw = 1;
			end
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
				reset_delay = 1;
			end
			S_DELAY: // 1.5 second delay
			begin
				erase = 1;
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
