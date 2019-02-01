// Main control for the whole interface
module control(
	input clock,resetn,anti_freeze,
	input go,left,right, // Buttons
	output ld_xy,ld_colour,ld_pos,
	output draw_pixel,
	output[8:0] dx,dy,x,y,
	output[8:0] colour,
	output[9:0] LEDR
	); 
	
	// Current game states
	localparam 	DEAL 	= 3'd0,
					FLOP 	= 3'd1,
					TURN 	= 3'd2,
					RIVER = 3'd3,
					SHOW 	= 3'd4;
	
	// Values of blinds
	localparam	B_BLIND	= 15'd200,
					S_BLIND	= 15'd100;
	
	// Keeps track of state
	reg[5:0] current_state,next_state;
	
	// Internal controls
	// Money management
	reg add_pot,add_bet,pbet,reset_money;
	reg set_blind,flip_blind,split_pot;
	reg[14:0] bet_value;
	// AI
	reg go_think;
	// Cards
	reg go_deal,ld_cards;
	reg[53:0] cards;
	// Drawing FSMs
	reg go_screen,go_money,go_action,go_gameover;
	// Menu
	reg reset_menu,ld_menu;
	reg[1:0] depthDATA;
	reg[3:0] menuDATA;
	// Cursor
	reg reset_cursor,set_cursor,inc_left,inc_right;
	// Game state
	reg reset_game_state,inc_game_state;
	reg[2:0] game_state;
	
	// Assigning state variables
	localparam 	S_STARTUP		= 6'd0,
					S_STARTUP_WAIT = 6'd1,
					S_RESET 			= 6'd2,
					S_DEAL_GO		= 6'd3,
					S_DEAL_CARDS	= 6'd4,
					S_DRAW_S_GO 	= 6'd5,
					S_DRAW_SCREEN 	= 6'd6,
					S_DRAW_M_GO		= 6'd7,
					S_DRAW_MONEY	= 6'd8,
					S_OPP_ACTION	= 6'd9,
					S_DRAW_ACTION	= 6'd10,
					S_INPUT 			= 6'd11,
					S_INPUT_WAIT	= 6'd12,
					S_LEFT_WAIT		= 6'd13,
					S_CURSOR_LEFT	= 6'd14,
					S_RIGHT_WAIT	= 6'd15,
					S_CURSOR_RIGHT = 6'd16,
					S_DO_ACTION 	= 6'd17,
					S_NEXT_STATE 	= 6'd18,
					S_POT_SPLIT 	= 6'd19,
					S_DRAW_GOVER	= 6'd20;
	
	// Register for all of the cards
	wire deal_done;
	wire[53:0] generated;
	
	// Generates all of the cards
	deal dealer(
		.clk(clock),.rst_n(resetn),
		.go(go_deal),.done(deal_done),
		.cards(generated)
	);
	
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			cards <= {6'b001110,6'b001110,6'b001110,6'b001110,6'b001110,6'b001110,6'b001110,6'b001110,6'b001110};
		else if(ld_cards) // Deal the cards
			cards <= generated;
	end
	
	// Counter for game state
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			game_state <= DEAL;
		else if(reset_game_state) // Reset
			game_state <= DEAL;
		else if(inc_game_state) // Go to next game state
			game_state <= game_state+1;
	end
	
	// Instantiating the modules for determining the winner
	// and required wires
	wire[41:0] sorted_negreanu,sorted_player;
	wire[23:0] negreanu,player;
	reg[1:0] winID;
	reg ld_winID,folded_player;
	reg set_folded_negreanu,folded_negreanu;
	
	// folded_negreaqnu is a register
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			folded_negreanu <= 1'b0;
		else if(reset_game_state)
			folded_negreanu <= 1'b0;
		else if(set_folded_negreanu)
			folded_negreanu <= 1'b1;
	end
	
	// Sort to feed into wincheck
	sort sortNegreanu(.clk(clock),.card_in({cards[53:24],cards[11:0]}),.card_out(sorted_negreanu));
	sort sortPlayer(.clk(clock),.card_in({cards[53:24],cards[23:12]}),.card_out(sorted_player));
	
	// Finds win conditions for players
	winner danielNegreanu(.cards(sorted_negreanu),.win(negreanu));
	winner extraordinaire(.cards(sorted_player),.win(player));
	
	//assign negreanu = {4'b0000,sorted_negreanu[39:36],sorted_negreanu[33:30],sorted_negreanu[27:24],sorted_negreanu[21:18],sorted_negreanu[15:12]};
	//assign player = {4'b0000,sorted_player[39:36],sorted_player[33:30],sorted_player[27:24],sorted_player[21:18],sorted_player[15:12]};
	
	// Logic for determining the winner
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			winID <= 2'd0;
		else if(folded_negreanu) // Negreanu folds
			winID <= 2'd2; // Player win
		else if(folded_player) // Player folds
			winID <= 2'd1; // Negreanu win
		else if(ld_winID) // Winner based on the table
		begin
			if(negreanu==player) // Tie, split pot
				winID <= 2'd0;
			else if(negreanu>player) // Daniel Negreanu wins
				winID <= 2'd1;
			else // Player wins
				winID <= 2'd2;
		end
	end
	
	// Instantiating module for money and output wires
	// and register for big blind
	wire[14:0] money_player,money_negreanu,pot,bet_player,bet_negreanu;
	reg BBlind;
	
	// Big blind register
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
			BBlind <= 1'b0; // Player is BB when BBlind = 1
		else if(flip_blind) // Inverts BB
			BBlind <= !BBlind;
	end
	
	// Money management module
	moneyManager mM(
		.clock(clock),.resetn(resetn),.reset_money(reset_money),
		.add_pot(add_pot),.add_bet(add_bet),.pbet(pbet),
		.BBlind(BBlind),.set_blind(set_blind),
		.split_pot(split_pot),.winID(winID),.value(bet_value),
		.money_player(money_player),.money_negreanu(money_negreanu),
		.pot(pot),.bet_player(bet_player),.bet_negreanu(bet_negreanu)
	);
	
	// AI Module
	wire[2:0] sug_act;
	reg ld_sug_act;
	reg[2:0] suggested_action;
	
	computerAction danielNegreanuAct(
		.clk(clock),
		.playermoney(money_player),.cpumoney(money_negreanu),
		.playerBet(bet_player),.computerBet(bet_negreanu),
		.cpucards(cards[11:0]),.communitycards(cards[53:24]),.stage(game_state),
		.action(sug_act)
	);
	
	always @(posedge clock)
	begin
		if(!resetn)
			suggested_action <= 3'd0;
		else if(ld_sug_act)
			suggested_action <= sug_act;
	end
	
	// Register for storing whether the opponent/player has to make a move
	reg opp_toplay,player_toplay;
	reg reset_toplay;
	reg opp_off,player_off,opp_on,player_on;
	
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			opp_toplay <= 1'b1;
			player_toplay <= 1'b1;
		end
		else if(reset_toplay) // Turn toplay back on
		begin
			opp_toplay <= 1'b1;
			player_toplay <= 1'b1;
		end
		else
		begin
			// Opponent to play register
			if(opp_off)
				opp_toplay <= 1'b0;
			else if(opp_on)
				opp_toplay <= 1'b1;
			
			// Player to play register
			if(player_off)
				player_toplay <= 1'b0;
			else if(player_on)
				player_toplay <= 1'b1;
		end
	end
	
	//assign LEDR[4:0] = current_state[4:0];
	//assign LEDR[9] = player_toplay;
	//assign LEDR[8] = opp_toplay;
	//assign LEDR[7:5] = suggested_action;
	assign LEDR[9:0] = 10'b0;
	
	// Instantiating the drawing FSMs
	// and the registers required as inputs
	wire[1:0] cursorID; // Contains position of cursor
	wire[8:0] faceup; // Decides which cards should be face up
	wire[1:0] menuDepth; // Decides which menu to pull up
	wire[3:0] menuOFF; // Decides which menu options should be turned on
	wire draw_done_s,draw_done_m,draw_done_a,draw_done_g;
	
	drawFSMs dFSM(
		.clock(clock),.resetn(resetn),
		.go_screen(go_screen),.go_money(go_money),
		.go_action(go_action),.go_gameover(go_gameover),
		.current_state(current_state),
		
		.depthDATA(depthDATA),.menuDATA(menuDATA),.game_state(game_state),
		.reset_menu(reset_menu),.reset_cursor(reset_cursor),.set_cursor(set_cursor),
		.ld_menu(ld_menu),.inc_left(inc_left),.inc_right(inc_right),
		
		.cards(cards),.winID(winID),
		
		.money_negreanu(money_negreanu),.money_player(money_player),
		.pot(pot),.bet_negreanu(bet_negreanu),.bet_player(bet_player),
		
		.suggested_action(suggested_action),
		
		.faceup(faceup),.cursorID(cursorID),
		.menuDepth(menuDepth),.menuOFF(menuOFF),
		
		.ld_xy(ld_xy),.ld_pos(ld_pos),.ld_colour(ld_colour),
		.draw_pixel(draw_pixel),
		.x(x),.y(y),.dx(dx),.dy(dy),
		.colour(colour),
		.draw_done_s(draw_done_s),.draw_done_m(draw_done_m),
		.draw_done_a(draw_done_a),.draw_done_g(draw_done_g)
	);
	
	// State table
	always @(*)
	begin
		case(current_state)
			S_STARTUP: // Initial startup
				next_state = go ? S_STARTUP_WAIT:S_STARTUP;
			S_STARTUP_WAIT: // Wait for initial go signal to be let go
				next_state = go ? S_STARTUP_WAIT:S_RESET;
			S_RESET: // Resets game state
				next_state = (money_player==0 | money_negreanu==0) ? S_DRAW_GOVER:S_DEAL_GO;
			S_DEAL_GO: // Starts the deal
				next_state = S_DEAL_CARDS;
			S_DEAL_CARDS: // Deals the cards
				next_state = deal_done ? S_DRAW_S_GO:S_DEAL_CARDS;
			S_DRAW_S_GO: // Starts the drawScreen FSM
				next_state = S_DRAW_SCREEN;
			S_DRAW_SCREEN: // Draw the current screen
				next_state = (draw_done_s | anti_freeze) ? S_DRAW_M_GO:S_DRAW_SCREEN;
			S_DRAW_M_GO: // Starts the drawMoney FSM
				next_state = S_DRAW_MONEY;
			S_DRAW_MONEY: // Draw all the money values
			begin
				if(draw_done_m | anti_freeze)
				begin
					if(game_state==SHOW)
						next_state = S_INPUT;
					else if(game_state==DEAL)
					begin
						if(BBlind)
							next_state = opp_toplay ? S_OPP_ACTION:S_INPUT;
						else
							next_state = player_toplay ? S_INPUT:S_OPP_ACTION;
					end
					else
					begin
						if(BBlind)
							next_state = player_toplay ? S_INPUT:S_OPP_ACTION;
						else
							next_state = opp_toplay ? S_OPP_ACTION:S_INPUT;
					end
				end
				else 
					next_state = S_DRAW_MONEY;
			end
			S_OPP_ACTION: // Perform AI action
				next_state = S_DRAW_ACTION;
			S_DRAW_ACTION: // Draws the opponent's action
			begin
				if(draw_done_a | anti_freeze)
				begin
					if(folded_negreanu)
						next_state = S_POT_SPLIT;
					else
						next_state = player_toplay ? S_DRAW_S_GO:S_NEXT_STATE;
				end
				else
					next_state = S_DRAW_ACTION;
			end
			S_INPUT: // Loop until user input
			begin
				if(go)
					next_state = S_INPUT_WAIT;
				else if(left)
					next_state = S_LEFT_WAIT;
				else if(right)
					next_state = S_RIGHT_WAIT;
				else 
					next_state = S_INPUT;
			end
			S_INPUT_WAIT: // Wait for user's select input
			begin
				if(go)
					next_state = S_INPUT_WAIT;
				else
					next_state = (game_state==SHOW) ? S_POT_SPLIT:S_DO_ACTION;
			end
			S_LEFT_WAIT: // Wait for left
				next_state = left ? S_LEFT_WAIT:S_CURSOR_LEFT;
			S_CURSOR_LEFT: // Move cursor left
				next_state = S_DRAW_S_GO;
			S_RIGHT_WAIT: // Wait for right
				next_state = right ? S_RIGHT_WAIT:S_CURSOR_RIGHT;
			S_CURSOR_RIGHT: // Move cursor right
				next_state = S_DRAW_S_GO;
			S_DO_ACTION: // Do whatever action user has selected
			begin
				if(folded_player)
					next_state = S_POT_SPLIT;
				else
					next_state = ((!player_toplay | player_off) & (!opp_toplay | opp_off) & !opp_on) ? S_NEXT_STATE:S_DRAW_S_GO;
			end
			S_NEXT_STATE: // Increment game_state
				next_state = S_DRAW_S_GO;
			S_POT_SPLIT: // Wait for show round
				next_state = S_RESET;
			S_DRAW_GOVER: // Show winner
				next_state = (draw_done_g | anti_freeze) ? S_STARTUP:S_DRAW_GOVER;
			default: next_state = S_STARTUP;
		endcase
	end
	
	// Changing data control signals
	always @(*)
	begin
		// Internal controls
		add_pot = 0; add_bet = 0; pbet = 0; bet_value = 15'd0;
		set_blind = 0; flip_blind = 0; split_pot = 0; reset_money = 0;
		go_screen = 0; go_money = 0; go_action = 0; go_gameover = 0;
		go_deal = 0; ld_cards = 0; ld_sug_act = 0;
		reset_menu = 0; ld_menu = 0;
		menuDATA = 4'b0000; depthDATA = 2'd0;
		reset_game_state = 0; inc_game_state = 0;
		reset_cursor = 0; inc_left = 0; inc_right = 0; set_cursor = 0;
		reset_toplay = 0;
		opp_off = 0; player_off = 0; opp_on = 0; player_on = 0;
		ld_winID = 0; folded_player = 0; set_folded_negreanu = 0;
		
		case(current_state)
			S_STARTUP: // Initial startup of game
			begin
				reset_money = 1;
			end
			S_RESET: // Resets game state
			begin
				flip_blind = 1;
				reset_game_state = 1;
				reset_cursor = 1;
				reset_menu = 1;
				reset_toplay = 1;
				
				go_gameover = (money_player==0 | money_negreanu==0); // Start drawGameover FSM
			end
			S_DEAL_GO: // Starts the deal
			begin
				set_blind = 1;
				go_deal = 1;
			end
			S_DEAL_CARDS:
			begin // Deals the cards
				ld_cards = 1;
			end
			S_DRAW_S_GO: // Starts the drawScreen FSM, also sets menu options
			begin
				go_screen = 1;
				ld_winID = 1; // Determine winner based on table cards
				set_cursor = 1;
				
				if(game_state==SHOW) // Display only NEXT in menu
				begin
					ld_menu = 1;
					menuDATA = 4'b1110;
					depthDATA = 2'd2;
				end
				else if(menuDepth==2'd0) // Main selection screen
				begin
					ld_menu = 1;
					depthDATA = 2'd0; // Stay here just change up active options
					menuDATA[3] = 1'b0; // Fold
					menuDATA[2] = (money_player==0 | money_negreanu==0); // Bet/Raise
					menuDATA[1] = (bet_player>=bet_negreanu); // Call
					menuDATA[0] = (bet_player<bet_negreanu); // Check
				end
				else if(menuDepth==2'd1) // Make sure cursor doesn't start on an unavailable option
					menuDATA = menuOFF;
			end
			S_DRAW_M_GO: // Starts the drawMoney FSM
			begin
				go_money = 1;
			end
			S_OPP_ACTION: // Perform AI action and starts drawAction FSM
			begin
				case(sug_act)
					1: // Call
					begin
						add_bet = 1;
						pbet = 0;
						bet_value = (bet_player-bet_negreanu<money_negreanu) ? (bet_player-bet_negreanu):money_negreanu;
					end
					2: // 2BB
					begin
						add_bet = 1;
						pbet = 0;
						bet_value = (2*B_BLIND-bet_negreanu);
						player_on = 1; // Player must take a turn to respond
					end
					3: // 4BB
					begin
						add_bet = 1;
						pbet = 0;
						bet_value = (4*B_BLIND-bet_negreanu);
						player_on = 1; // Player must take a turn to respond
					end
					4: // 6BB
					begin
						add_bet = 1;
						pbet = 0;
						bet_value = (6*B_BLIND-bet_negreanu);
						player_on = 1; // Player must take a turn to respond
					end
					5: // All in
					begin
						add_bet = 1;
						pbet = 0;
						// All in is capped at player's all in
						if(money_negreanu+bet_negreanu > money_player+bet_player)
							bet_value = money_player+bet_player-bet_negreanu;
						else
							bet_value = money_negreanu;
						player_on = 1; // Player must take a turn to respond
					end
					6: // Fold
						set_folded_negreanu = 1;
				endcase
				
				ld_sug_act = 1; // Store action taken for drawing
				go_action = 1; // Start drawAction FSM
				opp_off = 1; // Signify opponent has taken his turn
			end
			S_CURSOR_LEFT: // Move cursor left
			begin
				inc_left = 1;
			end
			S_CURSOR_RIGHT: // Move cursor right
			begin
				inc_right = 1;
			end
			S_DO_ACTION: // Do whatever action user has selected
			begin
				case(menuDepth)
					0: // Check, call, bet/raise, fold
					begin
						case(cursorID)
							0: // Check
							begin
								player_off = 1; // Player has taken a turn
							end
							1: // Call
							begin
								reset_cursor = 1;
								add_bet = 1;
								pbet = 1;
								bet_value = (bet_negreanu-bet_player);
								player_off = 1; // Player has taken a turn
							end
							2: // Bet/raise
							begin
								reset_cursor = 1;
								ld_menu = 1;
								depthDATA = 2'd1;
								// {ALL IN, 6BB, 4BB, 2BB}
								menuDATA[3] = 1'b0;
								menuDATA[2] = 	money_player<(6*B_BLIND-bet_player) | money_negreanu<(6*B_BLIND-bet_negreanu) |
													bet_player>=6*B_BLIND | bet_negreanu>=6*B_BLIND;
								menuDATA[1] = 	money_player<(4*B_BLIND-bet_player) | money_negreanu<(4*B_BLIND-bet_negreanu) |
													bet_player>=4*B_BLIND | bet_negreanu>=4*B_BLIND;
								menuDATA[0] = 	money_player<(2*B_BLIND-bet_player) | money_negreanu<(2*B_BLIND-bet_negreanu) |
													bet_player>=2*B_BLIND | bet_negreanu>=2*B_BLIND;
							end
							3: // Fold
							begin
								folded_player = 1;
							end
						endcase
					end
					1: // 2BB, 4BB, 6BB, all in
					begin
						// Figure out money management
						case(cursorID)
							0: // 2BB
								bet_value = (2*B_BLIND-bet_player);
							1: // 4BB
								bet_value = (4*B_BLIND-bet_player);
							2: // 6BB
								bet_value = (6*B_BLIND-bet_player);
							3: // ALL IN
							begin
								// All in is capped at opponent's all in
								if(money_negreanu+bet_negreanu < money_player+bet_player)
									bet_value = money_negreanu+bet_negreanu-bet_player;
								else
									bet_value = money_player;
							end
						endcase
						
						reset_menu = 1;
						reset_cursor = 1;
						
						player_off = 1; // Player has taken a turn
						opp_on = 1; // Opponent must take a turn to respond
						add_bet = 1;
						pbet = 1;
					end
				endcase
			end
			S_NEXT_STATE: // Increment game_state
			begin
				reset_cursor = 1;
				reset_toplay = 1;
				inc_game_state = 1;
				add_pot = 1;
				reset_menu = 1;
			end
			S_POT_SPLIT: // Handle the pot distribution
			begin
				split_pot = 1;
			end
		endcase
	end
	
	// Register for current state
	always @(posedge clock)
	begin
		if(!resetn) // Reset to value input, active low
			current_state <= S_STARTUP;
		else // Load next state
			current_state <= next_state;
	end
endmodule
