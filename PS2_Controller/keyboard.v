// FSM for handling keyboard input
module keyboard(
	input clock,resetn,
	inout PS2_CLK,PS2_DAT,
	output reg go,left,right
	);
	
	// Keyboard I/O
	wire[7:0] ps2_key_data;
	wire ps2_key_pressed;
	reg reset_keyboard;
	
	// Instantiate PS2 controller
	PS2_Controller PS2 (
		// Inputs
		.CLOCK_50(clock),
		.reset(!resetn),
		// Bidirectionals
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		// Outputs
		.received_data(ps2_key_data),
		.received_data_en(ps2_key_pressed),
		// Reset
		.the_command(8'hFF),
		.send_command(reset_keyboard)
	);
	
	// Keep track of state
	reg[2:0] current_state,next_state;
	
	// Assigning state variables
	localparam	S_WAIT			= 3'd0,
					S_SPACE_WAIT	= 3'd1,
					S_SPACE			= 3'd2,
					S_LEFT_WAIT		= 3'd3,
					S_LEFT			= 3'd4,
					S_RIGHT_WAIT	= 3'd5,
					S_RIGHT			= 3'd6,
					S_RESET_KEY		= 3'd7;

	// State table
	always @(*)
	begin
		case(current_state)
			S_WAIT: // Wait for a valid key to be pressed
			begin
				if(ps2_key_data==8'h29)
					next_state = S_SPACE_WAIT;
				else if(ps2_key_data==8'h6B)
					next_state = S_LEFT_WAIT;
				else if(ps2_key_data==8'h74)
					next_state = S_RIGHT_WAIT;
				else 
					next_state = S_WAIT;
			end
			S_SPACE_WAIT: // Wait for space to be released
				next_state = (ps2_key_data==8'hF0) ? S_SPACE:S_SPACE_WAIT;
			S_SPACE: // Send go signal
				next_state = S_RESET_KEY;
			S_LEFT_WAIT: // Wait for left key to be released
				next_state = (ps2_key_data==8'hF0) ? S_LEFT:S_LEFT_WAIT;
			S_LEFT: // Send left signal
				next_state = S_RESET_KEY;
			S_RIGHT_WAIT: // Wait for right key to be released
				next_state = (ps2_key_data==8'hF0) ? S_RIGHT:S_RIGHT_WAIT;
			S_RIGHT: // Send right signal
				next_state = S_RESET_KEY;
			S_RESET_KEY: // Reset signal from keyboard
				next_state = S_WAIT;
			default:
				next_state = 0;
		endcase
	end

	// Control signals
	always @(*)
	begin
		go = 0; left = 0; right = 0; reset_keyboard = 0;
		case(current_state)
			S_SPACE: // Send go signal
			begin
				go = 1;
			end
			S_LEFT: // Send left signal
			begin
				left = 1;
			end
			S_RIGHT: // Send right signal
			begin
				right = 1;
			end
			S_RESET_KEY: // Reset signal from keyboard
			begin
				reset_keyboard = 1;
			end
		endcase
	end

	// Register for current state
	always @(posedge clock)
	begin
		if(~resetn)
			current_state <= S_WAIT;
		else
			current_state <= next_state;
	end
endmodule
