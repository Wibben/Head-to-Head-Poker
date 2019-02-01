// Money management module
module moneyManager(
	input clock,resetn,reset_money,
	input add_pot,add_bet,pbet, // pbet = 1, player bet
	input BBlind,set_blind, // BB = 1, player big blind
	input split_pot,
	input[1:0] winID,
	input[14:0] value,
	output reg[14:0] money_player,money_negreanu,pot,bet_player,bet_negreanu
	);
	
	// Values of blinds
	localparam	B_BLIND	= 15'd200,
					S_BLIND	= 15'd100;
	
	// Registers for the money
	always @(posedge clock)
	begin
		if(!resetn) // Active low reset
		begin
			money_player <= 15'd10000;
			money_negreanu <= 15'd10000;
			pot <= 15'd00000;
			bet_player <= 15'd0;
			bet_negreanu <= 15'd0;
		end
		else if(reset_money)
		begin
			money_player <= 15'd10000;
			money_negreanu <= 15'd10000;
			pot <= 15'd0;
			bet_player <= 15'd0;
			bet_negreanu <= 15'd0;
		end
		else
		begin
			// Set the blinds
			if(set_blind)
			begin
				if(BBlind) // Player is BB
				begin
					bet_player <= (B_BLIND<=money_player) ? B_BLIND:money_player;
					bet_negreanu <= S_BLIND;
					money_player <= (B_BLIND<=money_player) ? (money_player-B_BLIND):15'd0;
					money_negreanu <= money_negreanu-S_BLIND;
				end
				else // Negreanu is BB
				begin
					bet_player <= S_BLIND;
					bet_negreanu <= (B_BLIND<=money_negreanu) ? B_BLIND:money_negreanu;
					money_player <= money_player-S_BLIND;
					money_negreanu <= (B_BLIND<=money_negreanu) ? (money_negreanu-B_BLIND):15'd0;
				end
			end
			// Add to either player or negreanu bet
			// and take away equivalent amount from money
			else if(add_bet) 
			begin
				if(pbet)
				begin
					bet_player <= bet_player+value;
					money_player <= money_player-value;
				end
				else
				begin
					bet_negreanu <= bet_negreanu+value;
					money_negreanu <= money_negreanu-value;
				end
			end
			// Put the bets into pot, set bets to 0
			else if(add_pot)
			begin
				pot <= pot+bet_player+bet_negreanu;
				bet_player <= 15'd0;
				bet_negreanu <= 15'd0;
			end
			// Split the pot accordingly (no side pot for now)
			else if(split_pot)
			begin
				pot <= 15'd0; // Pot will become 0
				bet_player <= 15'd0;
				bet_negreanu <= 15'd0;
				if(winID==1) // Negreanu wins
					money_negreanu <= money_negreanu+pot+bet_player+bet_negreanu;
				else if(winID==2) // Player wins
					money_player <= money_player+pot+bet_player+bet_negreanu;
				else // Split the pot
				begin
					money_negreanu <= money_negreanu+(pot+bet_player+bet_negreanu)/15'd2;
					money_player <= money_player+(pot+bet_player+bet_negreanu)/15'd2;
				end
			end
		end
	end
endmodule
