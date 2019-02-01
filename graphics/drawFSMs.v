// Module for all of the drawing FSMS
module drawFSMs(
	input clock,resetn,
	input go_screen,go_money,go_action,go_gameover,
	input[5:0] current_state,
	
	input[1:0] depthDATA,
	input[3:0] menuDATA,
	input[2:0] game_state,
	input reset_menu,reset_cursor,set_cursor,
	input ld_menu,inc_left,inc_right,
	
	input[53:0] cards,
	input[1:0] winID,
	
	input[14:0] money_negreanu,money_player,
	input[14:0] pot,bet_negreanu,bet_player,
	
	input[2:0] suggested_action,
	
	output[1:0] cursorID, // Contains position of cursor
	output[8:0] faceup, // Decides which cards should be face up
	output[1:0] menuDepth, // Decides which menu to pull up
	output[3:0] menuOFF, // Decides which menu options should be turned on
	
	output reg ld_xy,ld_colour,ld_pos,
	output reg draw_pixel,
	output reg[8:0] dx,dy,x,y,
	output reg[8:0] colour,
	output draw_done_s,draw_done_m,draw_done_a,draw_done_g
	);
	
	// Current state variables
	localparam 	S_DRAW_SCREEN 	= 6'd6,
					S_DRAW_MONEY	= 6'd8,
					S_DRAW_ACTION	= 6'd10,
					S_DRAW_GOVER	= 6'd20;
	
	// Outputs from drawScreen
	wire[8:0] x_s,y_s,dx_s,dy_s,colour_s;
	wire ld_xy_s,ld_pos_s,ld_colour_s;
	wire draw_pixel_s;
	
	// Outputs from drawMoney
	wire[8:0] x_m,y_m,dx_m,dy_m,colour_m;
	wire ld_xy_m,ld_pos_m,ld_colour_m;
	wire draw_pixel_m;
	
	// Outputs from drawAction
	wire[8:0] x_a,y_a,dx_a,dy_a,colour_a;
	wire ld_xy_a,ld_pos_a,ld_colour_a;
	wire draw_pixel_a;
	
	// Outputs from drawGameover
	wire[8:0] x_g,y_g,dx_g,dy_g,colour_g;
	wire ld_xy_g,ld_pos_g,ld_colour_g;
	wire draw_pixel_g;
	
	// cursorID, menuDepth, menuOFF, and faceup
	drawScreenInput dSI(
		.clock(clock),.resetn(resetn),
		.depthDATA(depthDATA),.menuDATA(menuDATA),.game_state(game_state),
		.reset_menu(reset_menu),.reset_cursor(reset_cursor),.set_cursor(set_cursor),
		.ld_menu(ld_menu),.inc_left(inc_left),.inc_right(inc_right),
		.faceup(faceup),.cursorID(cursorID),
		.menuDepth(menuDepth),.menuOFF(menuOFF)
	);
	
	// Screen drawing FSM
	drawScreen dScrn(
		.clock(clock),.resetn(resetn),.go(go_screen),
		.cards(cards),.faceup(faceup),.cursorID(cursorID),
		.menuDepth(menuDepth),.menuOFF(menuOFF),.winID(winID),
		.ld_xy(ld_xy_s),.ld_pos(ld_pos_s),.ld_colour(ld_colour_s),
		.draw_pixel(draw_pixel_s),
		.x(x_s),.y(y_s),.dx(dx_s),.dy(dy_s),
		.colour(colour_s),.done(draw_done_s)
	);
	
	// Money drawing FSM
	drawMoney dMon(
		.clock(clock),.resetn(resetn),.go(go_money),
		.money_n(money_negreanu),.money_p(money_player),
		.pot(pot),.bet_n(bet_negreanu),.bet_p(bet_player),
		.ld_xy(ld_xy_m),.ld_pos(ld_pos_m),.ld_colour(ld_colour_m),
		.draw_pixel(draw_pixel_m),
		.x(x_m),.y(y_m),.dx(dx_m),.dy(dy_m),
		.colour(colour_m),.done(draw_done_m)
	);
	
	// Opponent action drawing FSM
	drawAction dAct(
		.clock(clock),.resetn(resetn),.go(go_action),
		.suggested_action(suggested_action),
		.ld_xy(ld_xy_a),.ld_pos(ld_pos_a),.ld_colour(ld_colour_a),
		.draw_pixel(draw_pixel_a),
		.x(x_a),.y(y_a),.dx(dx_a),.dy(dy_a),
		.colour(colour_a),.done(draw_done_a)
	);
	
	// Game over drawing FSM
	drawGameover dGO(
		.clock(clock),.resetn(resetn),.go(go_gameover),
		.money_negreanu(money_negreanu),
		.ld_xy(ld_xy_g),.ld_pos(ld_pos_g),.ld_colour(ld_colour_g),
		.draw_pixel(draw_pixel_g),
		.x(x_g),.y(y_g),.dx(dx_g),.dy(dy_g),
		.colour(colour_g),.done(draw_done_g)
	);
	
	// Mux for deciding what to output
	always @(*)
	begin
		case(current_state)
			S_DRAW_SCREEN: // Feed through output from money FSM
			begin
				ld_xy = ld_xy_s; ld_pos = ld_pos_s; ld_colour = ld_colour_s;
				draw_pixel = draw_pixel_s; colour = colour_s;
				x = x_s; y = y_s; dx = dx_s; dy = dy_s;
			end
			S_DRAW_MONEY: // Feed through output from screen FSM
			begin
				ld_xy = ld_xy_m; ld_pos = ld_pos_m; ld_colour = ld_colour_m;
				draw_pixel = draw_pixel_m; colour = colour_m;
				x = x_m; y = y_m; dx = dx_m; dy = dy_m;
			end
			S_DRAW_ACTION: // Feed through output from action FSM
			begin
				ld_xy = ld_xy_a; ld_pos = ld_pos_a; ld_colour = ld_colour_a;
				draw_pixel = draw_pixel_a; colour = colour_a;
				x = x_a; y = y_a; dx = dx_a; dy = dy_a;
			end
			S_DRAW_GOVER: // Feed through output from game over FSM
			begin
				ld_xy = ld_xy_g; ld_pos = ld_pos_g; ld_colour = ld_colour_g;
				draw_pixel = draw_pixel_g; colour = colour_g;
				x = x_g; y = y_g; dx = dx_g; dy = dy_g;
			end
			default:
			begin
				ld_xy = 0; ld_pos = 0; ld_colour = 0;
				draw_pixel = 0; colour = 0;
				x = 0; y = 0; dx = 0; dy = 0;
			end
		endcase
	end
endmodule

// Inputs into drawScreen
module drawScreenInput(
	input clock,resetn,
	input[1:0] depthDATA,
	input[3:0] menuDATA,
	input[2:0] game_state,
	input reset_menu,reset_cursor,set_cursor,
	input ld_menu,inc_left,inc_right,
	output reg[1:0] cursorID, // Contains position of cursor
	output reg[8:0] faceup, // Decides which cards should be face up
	output reg[1:0] menuDepth, // Decides which menu to pull up
	output reg[3:0] menuOFF // Decides which menu options should be turned on
	);
	
	// Current game states
	localparam 	DEAL 	= 3'd0,
					FLOP 	= 3'd1,
					TURN 	= 3'd2,
					RIVER = 3'd3,
					SHOW 	= 3'd4;
	
	// menuOFF and menuDepth register
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			menuOFF <= 4'b0000; // Everything is on
			menuDepth <= 2'b00;
		end
		else if(reset_menu) // Turn everything back on
		begin
			menuOFF <= 4'b0000;
			menuDepth <= 2'b00;
		end
		else if(ld_menu) // Set which menu options are off and the depth of menu
		begin
			menuOFF <= menuDATA;
			menuDepth <= depthDATA;
		end
	end
	
	// Counter for cursorID
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			cursorID <= 2'b0;
		else if(reset_cursor) // Reset to first option
			cursorID <= 2'b0;
		else if(set_cursor) // Make sure current cursor value is valid
		begin
			if(!menuDATA[cursorID])
				cursorID <= cursorID;
			else if(!menuDATA[cursorID+1])
				cursorID <= cursorID+1;
			else if(!menuDATA[cursorID+2])
				cursorID <= cursorID+2;
			else
				cursorID <= cursorID+3;
		end
		else if(inc_left) // Move cursor left
		begin
			// Handling of when some options are turned off
			if(!menuOFF[cursorID-1])
				cursorID <= cursorID-1;
			else if(!menuOFF[cursorID-2])
				cursorID <= cursorID-2;
			else if(!menuOFF[cursorID-3])
				cursorID <= cursorID-3;
			else 
				cursorID <= cursorID;
		end
		else if(inc_right) // Move cursor right
		begin
			// Handling of when some options are turned off
			if(!menuOFF[cursorID+1])
				cursorID <= cursorID+1;
			else if(!menuOFF[cursorID+2])
				cursorID <= cursorID+2;
			else if(!menuOFF[cursorID+3])
				cursorID <= cursorID+3;
			else 
				cursorID <= cursorID;
		end
	end
	
	// faceup mux
	always @(*)
	begin
		case(game_state)
			DEAL:
				faceup = 9'b000001100;
			FLOP:
				faceup = 9'b001111100;
			TURN:
				faceup = 9'b011111100;
			RIVER:
				faceup = 9'b111111100;
			SHOW:
				faceup = 9'b111111111;
			default faceup = 9'b000000000;
		endcase
	end
endmodule
