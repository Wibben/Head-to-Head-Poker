// FSM for drawing money to screen
module drawMoney(
	input clock,resetn,go,
	input[14:0] money_n,money_p,pot,bet_n,bet_p,
	output reg ld_xy,ld_pos,ld_colour,
	output reg draw_pixel,done,
	output reg[8:0] dx,dy,
	output[8:0] x,y,
	output[8:0] colour
	);
	
	// Size of each digit
	localparam 	X_DIGIT	= 4'd6,
					Y_DIGIT 	= 4'd9;
	
	// Current item states
	localparam	N_MONEY	= 3'd0,
					P_MONEY	= 3'd1,
					POT		= 3'd2,
					N_BET		= 3'd3,
					P_BET		= 3'd4;
	
	// Keeps track of states
	reg[3:0] current_state,next_state;
	
	// Internal controls
	reg reset_item,reset_digit,reset_dx,reset_dy;
	reg inc_item,inc_digit,inc_dx,inc_dy;
	
	// Assigning state variables
	localparam	S_LOAD			= 4'd0,
					S_SET_UP			= 4'd1,
					S_DRAW_0			= 4'd2,
					S_DRAW_1 		= 4'd3,
					S_DRAW_2 		= 4'd4,
					S_DRAW_3 		= 4'd5,
					S_DRAW_4 		= 4'd6,
					S_NEXT_DIGIT	= 4'd7,
					S_NEXT_ITEM		= 4'd8,
					S_DRAW_DONE		= 4'd9;
	
	// Counter register for dx,dy, and current digit and item
	reg[2:0] current_item,current_digit;
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			current_item <= N_MONEY;
			current_digit <= 3'd0;
			dx <= 9'd0;
			dy <= 9'd0;
		end
		else 
		begin
			// Current item counter
			if(reset_item) // Reset current item
				current_item <= N_MONEY;
			else if(inc_item) // Next item
				current_item <= (current_item==P_BET) ? (N_MONEY):(current_item+1);
		
			// Current digit counter
			if(reset_digit) // Reset current digit
				current_digit <= 3'd0;
			else if(inc_digit) // Next digit
				current_digit <= (current_digit==4) ? (3'd0):(current_digit+1);
			
			// dx counter
			if(reset_dx)
				dx <= 9'b0;
			else if(inc_dx)
				dx <= (dx==X_DIGIT-1) ? (9'b0):(dx+1);
			
			// dy counter
			if(reset_dy)
				dy <= 9'b0;
			else if(inc_dy)
				dy <= (dy==Y_DIGIT-1) ? (9'b0):(dy+1);
		end
	end
	
	// Separating money into individual digits
	wire[19:0] digit_mn,digit_mp,digit_pot,digit_bn,digit_bp;
	
	digitSeparation dS1(.money(money_n),.digits(digit_mn));
	digitSeparation dS2(.money(money_p),.digits(digit_mp));
	digitSeparation dS3(.money(pot),.digits(digit_pot));
	digitSeparation dS4(.money(bet_n),.digits(digit_bn));
	digitSeparation dS5(.money(bet_p),.digits(digit_bp));
	
	// Instantiating module for determining x,y and colour output
	drawMoneyData dMD(
		.clock(clock),
		.digit_mn(digit_mn),.digit_mp(digit_mp),.digit_pot(digit_pot),
		.digit_bn(digit_bn),.digit_bp(digit_bp),
		.current_item(current_item),.current_digit(current_digit),
		.dx(dx),.dy(dy),.x(x),.y(y),.colour(colour)
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
				next_state = (dx==X_DIGIT-1) ? S_DRAW_4:S_DRAW_1;
			S_DRAW_4: // Increment dy
				next_state = (dy==Y_DIGIT-1) ? S_NEXT_DIGIT:S_DRAW_0;
			S_NEXT_DIGIT: // Increment digit
				next_state = (current_digit==4) ? S_NEXT_ITEM:S_SET_UP;
			S_NEXT_ITEM: // Increment item, reset digit
				next_state = (current_item==P_BET) ? S_DRAW_DONE:S_SET_UP;
			S_DRAW_DONE: // Signal money drawing is done
				next_state = S_LOAD;
			default: next_state = S_LOAD;
		endcase
	end
	
	// Changing control signals
	always @(*)
	begin
		// Internal controls
		reset_item = 0; reset_digit = 0; reset_dx = 0; reset_dy = 0;
		inc_item = 0; inc_digit = 0; inc_dx = 0; inc_dy = 0;
		
		// External controls
		ld_xy = 0; ld_pos = 0; ld_colour = 0;
		draw_pixel = 0; done = 0;
	
		case(current_state)
			S_LOAD: // Loop until signal goes for drawing to start
			begin
				reset_item = 1;
				reset_digit = 1;
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
			end
			S_NEXT_DIGIT: // Increment digit
			begin
				inc_digit = 1;
			end
			S_NEXT_ITEM: // Increment item, reset digit
			begin
				inc_item = 1;
				reset_digit = 1;
			end
			S_DRAW_DONE: // Signal money drawing is done
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

// Sets the x and y values depending on which number/digit is being drawn
module drawMoneyData(
	input clock,
	input[19:0] digit_mn,digit_mp,digit_pot,digit_bn,digit_bp, // All of the money values
	input[2:0] current_item,current_digit, // 0-4, 0 being LSD
	input[8:0] dx,dy,
	output reg[8:0] x,y,
	output[8:0] colour
	);

	// Current item states
	localparam	N_MONEY	= 3'd0,
					P_MONEY	= 3'd1,
					POT		= 3'd2,
					N_BET		= 3'd3,
					P_BET		= 4'd4;
	
	// Size of each digit
	localparam 	X_DIGIT	= 4'd6,
					Y_DIGIT 	= 4'd9;

	// Determining xy and calue of digit that is supposed to be drawn
	reg[3:0] current_value;
	
	always @(*)
	begin
		case(current_item)
			N_MONEY:
			begin
				x = 92 - current_digit*X_DIGIT;
				y = 36;
				current_value = digit_mn[current_digit*4+:4];
			end
			P_MONEY:
			begin
				x = 294 - current_digit*X_DIGIT;
				y = 176;
				current_value = digit_mp[current_digit*4+:4];
			end
			POT:
			begin
				x = 92 - current_digit*X_DIGIT;
				y = 151;
				current_value = digit_pot[current_digit*4+:4];
			end
			N_BET:
			begin
				x = 92 - current_digit*X_DIGIT;
				y = 164;
				current_value = digit_bn[current_digit*4+:4];
			end
			P_BET:
			begin
				x = 92 - current_digit*X_DIGIT;
				y = 177;
				current_value = digit_bp[current_digit*4+:4];
			end
			default:
			begin
				x = 9'd0;
				y = 9'd0;
				current_value = 4'd0;
			end
		endcase
	end
	
	// ROM module with the numbers
	wire[9:0] address;
	assign address = 60*(dy) + current_value*X_DIGIT + dx;
	
	numbers num(
		.clock(clock),
		.address(address),
		.q(colour)
	);
endmodule

// 4 dividers to separate the money value into 5 digits
module digitSeparation(
	input[14:0] money,
	output[19:0] digits
	);
	
	wire[14:0] q1,q2,q3,q4;
	
	divider d1( // Get 1s digit
		.numer(money),.denom(4'd10),
		.quotient(q1),.remain(digits[3:0])
	);
	divider d2( // Get 10s digit
		.numer(q1),.denom(4'd10),
		.quotient(q2),.remain(digits[7:4])
	);
	divider d3( // Get 100s digit
		.numer(q2),.denom(4'd10),
		.quotient(q3),.remain(digits[11:8])
	);
	divider d4( // Get 1000s digit
		.numer(q3),.denom(4'd10),
		.quotient(q4),.remain(digits[15:12])
	);
	assign digits[19:16] = q4[3:0]; // Get 10000s digit
endmodule
