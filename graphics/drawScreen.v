// FSM for drawing the entire image
module drawScreen(
	input clock,resetn,go,
	input[53:0] cards,
	input[8:0] faceup,
	input[1:0] cursorID,menuDepth,winID,
	input[3:0] menuOFF,
	output ld_pos,ld_colour,
	output draw_pixel,
	output[8:0] x,y,dx,dy,
	output[8:0] colour,
	output reg ld_xy,done
	);
	
	// Determine if winner's name should be drawn or not
	wire display_winner;
	assign display_winner = (faceup==9'b111111111);
	
	// Current item states
	localparam	ITEM_OPP_1 		= 4'd0,
					ITEM_OPP_2 		= 4'd1,
					ITEM_PLAYER_1 	= 4'd2,
					ITEM_PLAYER_2 	= 4'd3,
					ITEM_RIVER_1 	= 4'd4,
					ITEM_RIVER_2 	= 4'd5,
					ITEM_RIVER_3 	= 4'd6,
					ITEM_RIVER_4 	= 4'd7,
					ITEM_RIVER_5 	= 4'd8,
					ITEM_MENU_BG	= 4'd9,
					ITEM_MENU_1		= 4'd10,
					ITEM_MENU_2		= 4'd11,
					ITEM_MENU_3		= 4'd12,
					ITEM_MENU_4		= 4'd13,
					ITEM_CURSOR		= 4'd14,
					ITEM_WINNER		= 4'd15;
	
	// Keeps track of state
	reg[2:0] current_state,next_state;
	
	// Internal controls
	reg go_draw;
	reg ld_back,ld_face,ld_menuBG;
	reg ld_menu,ld_cursor,ld_win;
	reg reset_item_counter;
	reg inc_item;
	reg[3:0] current_item;
	
	// Assigning state variables
	localparam 	S_LOAD 		= 3'd0,
					S_SET_UP 	= 3'd1,
					S_DRAW_GO	= 3'd2,
					S_DRAW_ITEM = 3'd3,
					S_NEXT_ITEM = 3'd4,
					S_DRAW_DONE = 3'd5;
	
	// Counter for current item to draw
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			current_item <= ITEM_OPP_1;
		else if(reset_item_counter)
			current_item <= ITEM_OPP_1;
		else if(inc_item)
			current_item <= (current_item==(display_winner ? ITEM_WINNER:ITEM_CURSOR)) ? (ITEM_OPP_1):(current_item+1);
	end
	
	// x and y position register
	determineXY detXY(.current_item(current_item),.cursorID(cursorID),.x(x),.y(y));
	
	// Instantiating the module for drawing images
	// And registers required for it
	wire draw_done;
	wire[3:0] drawID;
	wire[1:0] menuID;
	wire[5:0] currentCard;
	
	// drawID, menuID and currentCard for drawImage
	drawImgInput dII(
		.clock(clock),.resetn(resetn),
		.cards(cards),.current_item(current_item),
		.ld_back(ld_back),.ld_face(ld_face),.ld_menuBG(ld_menuBG),
		.ld_menu(ld_menu),.ld_cursor(ld_cursor),.ld_win(ld_win),
		.drawID(drawID),.menuID(menuID),.currentCard(currentCard)
	);
	// drawing FSM
	drawImage dImg(
		.clock(clock),.resetn(resetn),.go(go_draw),
		.card(currentCard),.drawID(drawID),.winID(winID),
		.menuID(menuID),.menuDepth(menuDepth),.menuOFF(menuOFF),
		.ld_pos(ld_pos),.ld_colour(ld_colour),
		.draw_pixel(draw_pixel),.done(draw_done),
		.dx(dx),.dy(dy),
		.colour(colour)
	);
	
	// State table
	always @(*)
	begin
		case(current_state)
			S_LOAD: // Loop until dignal goes for drawing to start
				next_state = go ? S_SET_UP:S_LOAD;
			S_SET_UP: // Set x,y position (top left of image) and preps drawImage
				next_state = S_DRAW_GO;
			S_DRAW_GO: // Starts the drawImage FSM
				next_state = S_DRAW_ITEM;
			S_DRAW_ITEM: // Draw item (bg. card, etc.)
				next_state = draw_done ? S_NEXT_ITEM:S_DRAW_ITEM;
			S_NEXT_ITEM: // Increment item
				next_state = (current_item==(display_winner ? ITEM_WINNER:ITEM_CURSOR)) ? S_DRAW_DONE:S_SET_UP;
			S_DRAW_DONE: // Signal screen drawing is done
				next_state = S_LOAD;
			default: next_state = S_LOAD;
		endcase
	end
	
	// Changing control signals
	always @(*)
	begin
		// Internal controls
		ld_back = 0; ld_face = 0; ld_menuBG = 0;
		ld_menu = 0; ld_cursor = 0; ld_win = 0;
		reset_item_counter = 0; go_draw = 0;
		inc_item = 0;
		// External controls
		ld_xy = 0; done = 0;
		
		case(current_state)
			S_LOAD: // Loop until dignal goes for drawing to start
			begin
				reset_item_counter = 1;
			end
			S_SET_UP: // Set x,y position (top left of image) and preps drawImage
			begin
				ld_xy = 1;
				
				// Figuring out what to load into drawID
				if(current_item>=ITEM_OPP_1 && current_item<=ITEM_RIVER_5)
				begin // Load a card related graphic
					if(faceup[current_item - ITEM_OPP_1]) // Load the card face
						ld_face = 1;
					else // Load the back of the card
						ld_back = 1;
				end
				else if(current_item==ITEM_MENU_BG) // Load the menu background
					ld_menuBG = 1;
				else if(current_item>=ITEM_MENU_1 && current_item<=ITEM_MENU_4) // Load the menu
					ld_menu = 1;
				else if(current_item==ITEM_CURSOR) // Load the cursor
					ld_cursor = 1;
				else if(current_item==ITEM_WINNER) // Load the winner
					ld_win = 1;
			end
			S_DRAW_GO: // Starts drawImage FSM
			begin
				go_draw = 1;
			end
			S_NEXT_ITEM: // Increment item
			begin
				inc_item = 1;
			end
			S_DRAW_DONE: // Signal screen drawing is done
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

// x and y position mux
module determineXY(input[3:0] current_item, input[1:0] cursorID, output reg[8:0] x,y);
	// Current item states
	localparam	ITEM_OPP_1 		= 4'd0,
					ITEM_OPP_2 		= 4'd1,
					ITEM_PLAYER_1 	= 4'd2,
					ITEM_PLAYER_2 	= 4'd3,
					ITEM_RIVER_1 	= 4'd4,
					ITEM_RIVER_2 	= 4'd5,
					ITEM_RIVER_3 	= 4'd6,
					ITEM_RIVER_4 	= 4'd7,
					ITEM_RIVER_5 	= 4'd8,
					ITEM_MENU_BG	= 4'd9,
					ITEM_MENU_1		= 4'd10,
					ITEM_MENU_2		= 4'd11,
					ITEM_MENU_3		= 4'd12,
					ITEM_MENU_4		= 4'd13,
					ITEM_CURSOR		= 4'd14,
					ITEM_WINNER		= 4'd15;
	
	// Mux
	always @(*)
	begin
		case(current_item)
			ITEM_OPP_1:
			begin
				x = 9'd110;
				y = 9'd10;
			end
			ITEM_OPP_2:
			begin
				x = 9'd160;
				y = 9'd10;
			end
			ITEM_PLAYER_1:
			begin
				x = 9'd110;
				y = 9'd150;
			end
			ITEM_PLAYER_2:
			begin
				x = 9'd160;
				y = 9'd150;
			end
			ITEM_RIVER_1:
			begin
				x = 9'd35;
				y = 9'd80;
			end
			ITEM_RIVER_2:
			begin
				x = 9'd85;
				y = 9'd80;
			end
			ITEM_RIVER_3:
			begin
				x = 9'd135;
				y = 9'd80;
			end
			ITEM_RIVER_4:
			begin
				x = 9'd185;
				y = 9'd80;
			end
			ITEM_RIVER_5:
			begin
				x = 9'd235;
				y = 9'd80;
			end
			ITEM_MENU_BG:
			begin
				x = 9'd0;
				y = 9'd219;
			end
			ITEM_MENU_1:
			begin
				x = 9'd30;
				y = 9'd222;
			end
			ITEM_MENU_2:
			begin
				x = 9'd100;
				y = 9'd222;
			end
			ITEM_MENU_3:
			begin
				x = 9'd170;
				y = 9'd222;
			end
			ITEM_MENU_4:
			begin
				x = 9'd240;
				y = 9'd222;
			end
			ITEM_CURSOR:
			begin
				case(cursorID) // Different cursor locations for user input
					0:
						x = 9'd20;
					1:
						x = 9'd90;
					2:
						x = 9'd160;
					3:
						x = 9'd230;
					default: x = 9'd20;
				endcase
				// Same y pos for all cursor locations
				y = 9'd223;
			end
			ITEM_WINNER:
			begin
				x = 9'd240;
				y = 9'd222;
			end
			default:
			begin
				x = 9'd0;
				y = 9'd0;
			end
		endcase
	end
endmodule

// drawID and currentCard register
module drawImgInput(
	input clock,resetn,
	input[53:0] cards,
	input[3:0] current_item,
	input ld_back,ld_face,ld_menuBG,
	input ld_menu,ld_cursor,ld_win,
	output reg[3:0] drawID,
	output reg[1:0] menuID,
	output reg[5:0] currentCard
	);
	
	// Encoding for drawID
	localparam 	CARD_BACK 	= 4'd0,
					CARD_FACE 	= 4'd1,
					MENU_BG		= 4'd2,
					MENU			= 4'd3,
					CURSOR		= 4'd4,
					NAME			= 4'd5;
	
	// Current item states
	localparam	ITEM_OPP_1 		= 4'd0,
					ITEM_OPP_2 		= 4'd1,
					ITEM_PLAYER_1 	= 4'd2,
					ITEM_PLAYER_2 	= 4'd3,
					ITEM_RIVER_1 	= 4'd4,
					ITEM_RIVER_2 	= 4'd5,
					ITEM_RIVER_3 	= 4'd6,
					ITEM_RIVER_4 	= 4'd7,
					ITEM_RIVER_5 	= 4'd8,
					ITEM_MENU_1		= 4'd10,
					ITEM_MENU_2		= 4'd11,
					ITEM_MENU_3		= 4'd12,
					ITEM_MENU_4		= 4'd13;
	
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			drawID <= 4'b0;
			currentCard <= 6'b000010; // C2
		end
		begin
			// Set drawID
			if(ld_back) // Draw card back
				drawID <= CARD_BACK;
			else if(ld_face) // Draw card face
				drawID <= CARD_FACE;
			else if(ld_menuBG) // Draw menu BG
				drawID <= MENU_BG;
			else if(ld_menu) // Draw menu
				drawID <= MENU;
			else if(ld_cursor) // Draw cursor
				drawID <= CURSOR;
			else if(ld_win) // Draw winner name
				drawID <= NAME;
			// Set current card
			case(current_item)
				ITEM_OPP_1:
					currentCard <= cards[5:0];
				ITEM_OPP_2:
					currentCard <= cards[11:6];
				ITEM_PLAYER_1:
					currentCard <= cards[17:12];
				ITEM_PLAYER_2:
					currentCard <= cards[23:18];
				ITEM_RIVER_1:
					currentCard <= cards[29:24];
				ITEM_RIVER_2:
					currentCard <= cards[35:30];
				ITEM_RIVER_3:
					currentCard <= cards[41:36];
				ITEM_RIVER_4:
					currentCard <= cards[47:42];
				ITEM_RIVER_5:
					currentCard <= cards[53:48];
				default:
					currentCard <= 6'b000010; // C2
			endcase
			// Set menuID
			case(current_item)
				ITEM_MENU_1:
					menuID <= 2'b00;
				ITEM_MENU_2:
					menuID <= 2'b01;
				ITEM_MENU_3:
					menuID <= 2'b10;
				ITEM_MENU_4:
					menuID <= 2'b11;
				default:
					menuID <= 2'b00;
			endcase
		end
	end
endmodule
