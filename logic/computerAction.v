module computerAction (input clk, input[14:0] playermoney, cpumoney,playerBet,computerBet, input wire[11:0] cpucards, input[29:0] communitycards, input[2:0] stage,output reg[2:0] action);
	//Stages 
	//000 - deal
	//001 - flop
	//010 - turn
	//011 - river
	//Bets- 2,4,6 BB, all in
	//Suggested Actions
	//000 - check 
	//001 - call
	//010 - raise 2BB
	//011 - raise 4BB
	//100 - raise 6BB
	//101 - All In
	//110 - Fold
	reg[41:0] cards;
	wire[23:0] cond;
	reg[9:0] address;
	reg suited,utg,limp,bet,reraise;
	wire[2:0] pf;
	wire canCheck, canCall, can2BB, can4BB, can6BB;
	assign canCheck = (playerBet == computerBet)? 1:0;
	assign canCall = (playerBet - computerBet < cpumoney && playerBet - computerBet != 0)? 1:0;
	assign can2BB = (playerBet < 2*BB && cpumoney > 2*BB && playermoney != 0)? 1:0;
	assign can4BB = (playerBet < 4*BB && cpumoney > 4*BB && playermoney != 0)? 1:0;
	assign can6BB = (playerBet < 6*BB && cpumoney > 6*BB && playermoney != 0)? 1:0;
	localparam check = 0, call = 1, raise2BB = 2, raise4BB = 3, raise6BB = 4, allin = 5, fold = 6, SB = 100, BB = 200;
	localparam two = 4'b0010,three = 4'b0011,four = 4'b0100,five = 4'b0101,
				  six = 4'b0110,seven = 4'b0111,eight = 4'b1000,nine = 4'b1001,
				  ten = 4'b1010,J = 4'b1011,Q = 4'b1100,K = 4'b1101,A = 4'b1110,
				  C = 2'b00,H = 2'b01,S = 2'b10,D =2'b11, 
				  straightflush = 4'b1000, fourofakind = 4'b0111, fullhouse = 4'b0110,
				  flush = 4'b0101, straight = 4'b0100, triple = 4'b0011, twopair = 4'b0010,
				  pair = 4'b0001, highcard = 4'b0000;
				  
	preflop pre(
		.clock(clk),
		.address(address),
		.q(pf)
	);
	
	odds o(cards,cond);
	
	reg[5:0] high,low;
	//Find high card
	always @ (*)
		begin
			//set high and low card
			if(cpucards[3:0] > cpucards[9:6])
				begin
					high = cpucards[5:0];
					low = cpucards[11:6];
				end
			else
				begin
					low = cpucards[5:0];
					high = cpucards[11:6];
				end
			//set suited flag
			if(cpucards[5:4] == cpucards[11:10])
					suited = 1;
			else
				suited = 0;
			//set position flag, utg = under the gun, limp = opponent called, bet = opponent bet, reraise = opponent reraised
			if(computerBet == SB)
				begin
					utg = 1;
					limp = 0;
					bet = 0;
					reraise = 0;
				end
			else if(playerBet == BB && computerBet == BB)
				begin
					utg = 0;
					limp = 1;
					bet = 0;
					reraise = 0;
				end
			else if(playerBet > BB && computerBet == BB)
				begin
					utg = 0;
					limp = 0;
					bet = 1;
					reraise = 0;
				end
			else if(playerBet > computerBet)
				begin
					utg = 0;
					limp = 0;
					bet = 0;
					reraise = 1;
				end
			else 
				begin
					utg = 0;
					limp = 0;
					bet = 0;
					reraise = 0;
				end
				
			//set address to be called
			address = utg*0+limp*182 + bet*364 + reraise*546 + 91*suited + low-2 + ((high-2)*(high-1)/2);
			
		end
		/*
			checks
			if(can6BB)
				action = raise6BB;
			else if(can4BB)
				action = raise4BB;
			else if (can2BB)
				action = raise2BB;
			else if (canCall)
				action = call;
			else if (canCheck)
				action = check;
			else
				action = fold;
			
		*/
	
	always @ (*)
		begin
			case(stage)
			//pre-flop
			3'b000:begin
						cards = 42'b0;
						if(pf == raise4BB)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
						else if(pf == call)
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
						else if (pf == check)
							if (canCheck)
									action = check;
								else
									action = fold;
						else
							action = fold;
					 end
			//flop
			3'b001:begin
						cards = {cpucards,communitycards[17:0]};
						if(cpumoney == 0)
							action = check;
						else if(cond[23:20] >= pair)
						begin
							if(playerBet == 0)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == computerBet)
							begin
								if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 2*BB)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 4*BB)
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 6*BB)
							begin
								if (canCall && cond[23:20] >= twopair)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
						end
						else
						begin
							if(playerBet == 0)
							begin
								if (can2BB && high >= J)
									action = raise2BB;
								else if (canCall && high >= nine) 
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == computerBet)
							begin
								if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 2*BB)
							begin
								if (canCall && high >= nine)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 4*BB)
							begin
								if (canCall && high >= J)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 6*BB)
							begin
								if (canCall && high >= Q)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else
							begin
								if (canCall && high >= K)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
						end
					end
			//turn
			3'b010:begin
						cards = {cpucards,communitycards[23:0]};
						if(cpumoney == 0)
							action = check;
						else if(cond[23:20] >= pair)
						begin
							if(playerBet == 0)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == computerBet)
							begin
								if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 2*BB)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 4*BB)
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 6*BB)
							begin
								if (canCall && cond[23:20] >= twopair)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
						end
						else
						begin
							if(playerBet == 0)
							begin
								if (can2BB && high >= J)
									action = raise2BB;
								else if (canCall && high >= nine) 
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == computerBet)
							begin
								if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 2*BB)
							begin
								if (canCall && high >= nine)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 4*BB)
							begin
								if (canCall && high >= J)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 6*BB)
							begin
								if (canCall && high >= Q)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else
							begin
								if (canCall && high >= K)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
						end
					end
			//river
			3'b011:begin
						cards = {cpucards,communitycards[29:0]};	
						if(cpumoney == 0)
							action = check;
						else if(cond[23:20] >= pair)
						begin
							if(playerBet == 0)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == computerBet)
							begin
								if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 2*BB)
							begin
								if(can4BB)
									action = raise4BB;
								else if (can2BB)
									action = raise2BB;
								else if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 4*BB)
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else if(playerBet == 6*BB)
							begin
								if (canCall && cond[23:20] >= twopair)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
							else
							begin
								if (canCall)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = allin;
							end
						end
						else
						begin
							if(playerBet == 0)
							begin
								if(can4BB && high >= Q)
									action = raise4BB;
								if (can2BB && high >= J)
									action = raise2BB;
								else if (canCall && high >= ten) 
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == computerBet)
							begin
								if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 2*BB)
							begin
								if(can4BB && high >= J)
									action = raise4BB;
								else if (can2BB && high >= ten)
									action = raise2BB;
								else if (canCall && high >= nine)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 4*BB)
							begin
								if (canCall && high >= Q)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else if(playerBet == 6*BB)
							begin
								if (canCall && high >= Q)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
							else
							begin
								if (canCall && high >= K)
									action = call;
								else if (canCheck)
									action = check;
								else
									action = fold;
							end
						end
					end
			default:begin
						action = fold;
						cards = 42'b0;
						end
			endcase
		end
endmodule 