// FSM for drawing an image to screen
module drawImage(
	input clock,resetn,go,
	input[5:0] card,
	input[3:0] drawID,menuOFF,
	input[1:0] menuID,menuDepth,winID,
	output reg ld_pos,ld_colour,
	output reg draw_pixel,done,
	output reg[8:0] dx,dy,
	output[8:0] colour
	);
	
	// Keeps track of size of images
	wire[8:0] x_size,y_size;
	
	// Module for determinging x and y size and colour output
	drawImageData dID(
		.clock(clock),
		.card(card),.drawID(drawID),.menuOFF(menuOFF),
		.menuID(menuID),.menuDepth(menuDepth),.winID(winID),
		.dx(dx),.dy(dy),
		.x_size(x_size),.y_size(y_size),.colour(colour)
	);
	
	// Keeps track of state
	reg[2:0] current_state,next_state;
	
	// Internal controls
	reg reset_dx,reset_dy,inc_dx,inc_dy;
	
	// Assigning state variables
	localparam 	S_DRAW_LOAD = 3'd0,
					S_DRAW_0 	= 3'd1,
					S_DRAW_1 	= 3'd2,
					S_DRAW_2 	= 3'd3,
					S_DRAW_3 	= 3'd4,
					S_DRAW_4 	= 3'd5,
					S_DRAW_DONE = 3'd6;
	
	// Counter registers for dx and dy
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
				dx <= (dx==x_size-1) ? (9'b0):(dx+1);
			
			// dy counter
			if(reset_dy)
				dy <= 9'b0;
			else if(inc_dy)
				dy <= (dy==y_size-1) ? (9'b0):(dy+1);
		end
	end
	
	// State table
	always @(*)
	begin
		case(current_state)
			S_DRAW_LOAD: // Loop until signal goes for drawing to start, reset dy
				next_state = go ? S_DRAW_0:S_DRAW_LOAD;
			S_DRAW_0: // Reset dx
				next_state = S_DRAW_1;
			S_DRAW_1: // Set pixel fill position
				next_state = S_DRAW_2;
			S_DRAW_2: // Fill pixel
				next_state = S_DRAW_3;
			S_DRAW_3: // Increment dx
				next_state = (dx==x_size-1) ? S_DRAW_4:S_DRAW_1;
			S_DRAW_4: // Increment dy
				next_state = (dy==y_size-1) ? S_DRAW_DONE:S_DRAW_0;
			S_DRAW_DONE: // Finished drawing
				next_state = S_DRAW_LOAD;
			default: next_state = S_DRAW_LOAD;
		endcase
	end
	
	// Changing control signals
	always @(*)
	begin
		// Initializing signals to 0 to avoid latches
		// Internal controls
		reset_dx = 0; reset_dy = 0; inc_dx = 0; inc_dy = 0;
		// External controls
		ld_pos = 0; ld_colour = 0;
		draw_pixel = 0; done = 0; 
	
		case(current_state)
			S_DRAW_LOAD: // Loop until signal goes for drawing to start, reset dy
			begin
				reset_dy = 1;
			end
			S_DRAW_0: // Reset dx
			begin
				reset_dx = 1;
			end
			S_DRAW_1: // Set pixel fill position and colour
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
			S_DRAW_DONE: // Finished drawing
			begin
				done = 1;
			end
		endcase
	end
	
	// Register for current state
	always @(posedge clock)
	begin
		if(!resetn) // Reset to value input, active low
			current_state <= S_DRAW_LOAD;
		else // Load next state
			current_state <= next_state;
	end
endmodule

// Module to determine x_size, y_size, and colour of image
module drawImageData(
	input clock,
	input[5:0] card,
	input[3:0] drawID,menuOFF,
	input[1:0] menuID,menuDepth,winID,
	input[8:0] dx,dy,
	output reg[8:0] x_size,y_size,colour
	);
	
	// Encoding for drawID
	localparam 	CARD_BACK 	= 4'd0,
					CARD_FACE 	= 4'd1,
					MENU_BG		= 4'd2,
					MENU			= 4'd3,
					CURSOR		= 4'd4,
					NAME			= 4'd5;
	
	// Size of images
	localparam 	X_CARD 	= 9'd44,
					Y_CARD 	= 9'd59,
					X_MENUBG	= 9'd320,
					Y_MENUBG	= 9'd21,
					X_MENU	= 9'd60,
					Y_MENU	= 9'd14,
					X_CURSOR = 9'd9,
					Y_CURSOR = 9'd14,
					X_NAME	= 9'd60,
					Y_NAME	= 9'd14;

	// ROM modules with all of the images
	reg[17:0] addressFace;
	reg[11:0] addressBack;
	reg[12:0] addressMenuBG;
	reg[14:0] addressMenu;
	reg[6:0] addressCursor;
	reg[11:0] addressName;
	wire[8:0] colourFace,colourBack,colourMenuBG;
	wire[8:0] colourMenu,colourCursor,colourName;
	wire[1:0] suit;
	wire[3:0] name;
	assign suit = card[5:4];
	assign name = card[3:0];
	playingCards pc(
		.clock(clock),
		.address(addressFace),
		.q(colourFace)
	);
	cardBack cb(
		.clock(clock),
		.address(addressBack),
		.q(colourBack)
	);
	menuBG mbg(
		.clock(clock),
		.address(addressMenuBG),
		.q(colourMenuBG)
	);
	menu m(
		.clock(clock),
		.address(addressMenu),
		.q(colourMenu)
	);
	cursor csr(
		.clock(clock),
		.address(addressCursor),
		.q(colourCursor)
	);
	winnerName wn(
		.clock(clock),
		.address(addressName),
		.q(colourName)
	);
	
	// Mux for choosing x, y sizes, output colours, and addresses
	always @(*)
	begin
		// Set addresses to 0 so no risk of reading from out of bounds
		addressFace = 0;
		addressBack = 0;
		addressMenuBG = 0;
		addressMenu = 0;
		addressCursor = 0;
		addressName = 0;
		
		case(drawID)
			CARD_BACK:
			begin
				x_size = X_CARD;
				y_size = Y_CARD;
				colour = colourBack;
				addressBack = (X_CARD*dy+dx);
			end
			CARD_FACE:
			begin
				x_size = X_CARD;
				y_size = Y_CARD;
				colour = colourFace;
				addressFace = ((237*suit)/4+dy)*571 + ((571*((name==14) ? 0:(name-1)))/13+dx) + 1;
			end
			MENU_BG:
			begin
				x_size = X_MENUBG;
				y_size = Y_MENUBG;
				colour = colourMenuBG;
				addressMenuBG = (X_MENUBG*dy+dx);
			end
			MENU:
			begin
				x_size = X_MENU;
				y_size = Y_MENU;
				colour = colourMenu;
				addressMenu = 	((dy+1)*245 + (menuID*(X_MENU+1)+dx+2)) + // Actual menu option
									menuDepth*15*245 + // Depth of menu
									menuOFF[menuID]*45*245; // Greyed out options
			end
			CURSOR:
			begin
				x_size = X_CURSOR;
				y_size = Y_CURSOR;
				colour = colourCursor;
				addressCursor = (X_CURSOR*dy+dx);
			end
			NAME:
			begin
				x_size = X_NAME;
				y_size = Y_NAME;
				colour = colourName;
				addressName = ((dy+1)*62 + dx+1) + winID*15*62;
			end
			default:
			begin
				x_size = 9'b0;
				y_size = 9'b0;
				colour = 9'b0;
			end
		endcase
	end
endmodule
