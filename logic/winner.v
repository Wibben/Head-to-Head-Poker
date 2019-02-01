module winner (input[41:0] cards, output reg[23:0] win);
	//Setup parameters
	//ASSUME SORTED, highest card in 41:36
	localparam two = 4'b0010,three = 4'b0011,four = 4'b0100,five = 4'b0101,
				  six = 4'b0110,seven = 4'b0111,eight = 4'b1000,nine = 4'b1001,
				  ten = 4'b1010,J = 4'b1011,Q = 4'b1100,K = 4'b1101,A = 4'b1110,
				  C = 2'b00,H = 2'b01,S = 2'b10,D =2'b11, straightflush = 4'b1000, 
				  fourofakind = 4'b0111, fullhouse = 4'b0110,flush = 4'b0101, straight = 4'b0100, 
				  triple = 4'b0011, twopair = 4'b0010,pair = 4'b0001, highcard = 4'b0000;
	localparam[51:0] rank = {two,three,four,five,six,seven,eight,nine,ten,J,Q,K,A};
	localparam[7:0] suit = {D,S,H,C};
	//flag for found highest hand
	reg found;
	reg[11:0] flushcount;
	reg [1:0] flushsuit;
	reg[51:0] cardinfo;
	//Get cards information
	always @ (*)
		begin:WIN
			//default cardinfo
			cardinfo = 52'b0;
			flushcount = 12'b0;
			//search for each type of card
			cardinfo = (2**(cards[41:40]+4*(14-cards[39:36])))+
						  (2**(cards[35:34]+4*(14-cards[33:30])))+
						  (2**(cards[29:28]+4*(14-cards[27:24])))+
						  (2**(cards[23:22]+4*(14-cards[21:18])))+
						  (2**(cards[17:16]+4*(14-cards[15:12])))+
						  (2**(cards[11:10]+4*(14-cards[9:6])))+
						  (2**(cards[5:4]+4*(14-cards[3:0])));
			//diamonds
			flushcount[11:9] = cardinfo[51]+cardinfo[47]+cardinfo[43]+cardinfo[39]+cardinfo[35]+cardinfo[31]+cardinfo[27]+cardinfo[23]+cardinfo[19]+cardinfo[15]+cardinfo[11]+cardinfo[7]+cardinfo[3];
			//spades
			flushcount[8:6] =  cardinfo[50]+cardinfo[46]+cardinfo[42]+cardinfo[38]+cardinfo[34]+cardinfo[30]+cardinfo[26]+cardinfo[22]+cardinfo[18]+cardinfo[14]+cardinfo[10]+cardinfo[6]+cardinfo[2];
			//hearts
			flushcount[5:3] =  cardinfo[49]+cardinfo[45]+cardinfo[41]+cardinfo[37]+cardinfo[33]+cardinfo[29]+cardinfo[25]+cardinfo[21]+cardinfo[17]+cardinfo[13]+cardinfo[9]+cardinfo[5]+cardinfo[1];
			//clubs
			flushcount[2:0] =  cardinfo[48]+cardinfo[44]+cardinfo[40]+cardinfo[36]+cardinfo[32]+cardinfo[28]+cardinfo[24]+cardinfo[20]+cardinfo[16]+cardinfo[12]+cardinfo[8]+cardinfo[4]+cardinfo[0];
		end
	//Get win conditions
	//set win[23:20] to win condition
	always @ (*)
		begin
			//default win and flag
			win = 24'b0;
			found = 0;
			flushsuit = 2'b0;
			//straight flush, store high card in win[19:16]
			if(!found)
				begin:findstraightflush
					integer sfr,sfs;
					for(sfs =0; sfs<4; sfs = sfs+1)
						begin
							for(sfr=0; sfr<9; sfr =sfr+1)
								begin
									if(cardinfo[4*sfr+sfs] && 
										cardinfo[4*(sfr+1)+sfs] &&	
										cardinfo[4*(sfr+2)+sfs] &&
										cardinfo[4*(sfr+3)+sfs] &&
										cardinfo[4*(sfr+4)+sfs] && !found)
										begin
											//set win condition to straight flush
											win[23:20] = straightflush;
											//set rank
											win[19:16] = rank[4*sfr+:4];
											found = 1;
										end
								end
							//wheel (A->5)
							if(cardinfo[sfs] && 
								cardinfo[4*(9)+sfs] &&	
								cardinfo[4*(10)+sfs] &&
								cardinfo[4*(11)+sfs] &&
								cardinfo[4*(12)+sfs] && !found)
								begin
									//set win condition to straight flush
									win[23:20] = straightflush;
									//set rank
									win[19:16] = rank[4*9+:4];
									found = 1;
								end
						end
				end
			//four of a kind, store quad card in win[19:16]
			if(!found)
				begin:findquad
					integer qu;
					for(qu=0; qu<13; qu = qu+1)
						begin
							//card rank
							if(cardinfo[4*qu+:4] == 15)
								begin
									//set four of a kind to rank, set wincond to four of a kind
									win[19:16] = rank[qu*4+:4];
									win[23:20] = fourofakind;
									found = 1;
								end
						end
				end
			//full house, store triple card in win[19:16]
			if(!found)
				begin:findfullhouse
					integer trip,par;
					for(trip=0; trip<13; trip = trip+1)
						begin
							//find card rank of triple
							if(cardinfo[4*trip]+cardinfo[4*trip+1]+cardinfo[4*trip+2]+cardinfo[4*trip+3] == 3 && !found)
								begin
									//find pair
									for(par = 12; par > -1; par = par - 1)
										begin
											if(cardinfo[4*par]+cardinfo[4*par+1]+cardinfo[4*par+2]+cardinfo[4*par+3] >= 2 && rank[par*4+:4] != rank[trip*4+:4])
												begin
													//set triple to higher rank
													win[19:16] = rank[trip*4+:4];
													//set wincond to fullhouse
													win[23:20] = fullhouse;
													//set found
													found = 1;
												end
										end
								end
						end
				end
			//flush, store five high cards in flush
			if(!found)
				begin:findflush
					integer loadfl;
					if(flushcount[11:9] > 4)
					begin
						//set wincond to flush
						win[23:20] = flush;
						flushsuit = D;
						//set flag to found
						found = 1;
					end
					else if(flushcount[8:6] > 4)
					begin
						//set wincond to flush
						win[23:20] = flush;
						flushsuit = S;
						//set flag to found
						found = 1;
					end
					else if(flushcount[5:3] > 4)
					begin
						//set wincond to flush
						win[23:20] = flush;
						flushsuit = H;
						//set flag to found
						found = 1;
					end
					else if(flushcount[2:0] > 4)
					begin
						//set wincond to flush
						win[23:20] = flush;
						flushsuit = C;
						//set flag to found
						found = 1;
					end
							
					if(found)
					begin
						for(loadfl=0;loadfl<13;loadfl=loadfl+1)
							begin
								if(cardinfo[4*loadfl+flushsuit] == 1)
									begin
										if(win[19:16] == 0)
											begin
												win[19:16] = rank[4*loadfl+:4];
											end
										else if(win[15:12] == 0)
											begin
												win[15:12] = rank[4*loadfl+:4];
											end
										else if(win[11:8] == 0)
											begin
												win[11:8] = rank[4*loadfl+:4];
											end
										else if(win[7:4] == 0)
											begin
												win[7:4] = rank[4*loadfl+:4];
											end
										else if(win[3:0] == 0)
											begin
												win[3:0] = rank[4*loadfl+:4];
											end	
									end
							end
					end
				end
			//check straight, store high card in win[19:16]
			if(!found)
				begin:findstraight
					integer sr;
					//find high card of straight
					for(sr=0; sr<9; sr =sr+1)
								begin
									if((cardinfo[4*sr] || cardinfo[4*sr+1] || cardinfo[4*sr+2] || cardinfo[4*sr+3]) &&
										(cardinfo[4*(sr+1)] || cardinfo[4*(sr+1)+1] || cardinfo[4*(sr+1)+2] || cardinfo[4*(sr+1)+3]) &&
										(cardinfo[4*(sr+2)] || cardinfo[4*(sr+2)+1] || cardinfo[4*(sr+2)+2] || cardinfo[4*(sr+2)+3]) &&
										(cardinfo[4*(sr+3)] || cardinfo[4*(sr+3)+1] || cardinfo[4*(sr+3)+2] || cardinfo[4*(sr+3)+3]) &&
										(cardinfo[4*(sr+4)] || cardinfo[4*(sr+4)+1] || cardinfo[4*(sr+4)+2] || cardinfo[4*(sr+4)+3]) && !found)
										begin
											//set win condition to straight
											win[23:20] = straight;
											//set ranks
											win[19:16] = rank[4*sr+:4];
											found = 1;
										end
								end
					//wheel (A -> 5)
					if((cardinfo[0] || cardinfo[1] || cardinfo[2] || cardinfo[3]) &&
						(cardinfo[4*(9)] || cardinfo[4*(9)+1] || cardinfo[4*(9)+2] || cardinfo[4*(9)+3]) &&
						(cardinfo[4*(10)] || cardinfo[4*(10)+1] || cardinfo[4*(10)+2] || cardinfo[4*(10)+3]) &&
						(cardinfo[4*(11)] || cardinfo[4*(11)+1] || cardinfo[4*(11)+2] || cardinfo[4*(11)+3]) &&
						(cardinfo[4*(12)] || cardinfo[4*(12)+1] || cardinfo[4*(12)+2] || cardinfo[4*(12)+3]) && !found)
								begin
									//set win condition to straight
									win[23:20] = straight;
									//set ranks
									win[19:16] = rank[4*9+:4];
									found = 1;
								end
				end
			//check triple, store card rank in win[19:16]
			if(!found)
				begin:findtriple
					integer tr,i;
					for(tr=0; tr<13; tr = tr+1)
						begin
							//card rank
							if(cardinfo[4*tr]+cardinfo[4*tr+1]+cardinfo[4*tr+2]+cardinfo[4*tr+3] == 3)
								begin
									//set triple to rank, set wincond to triple
									win[19:16] = rank[tr*4+:4];
									win[15:12] = rank[tr*4+:4];
									win[11:8] = rank[tr*4+:4];
									win[23:20] = triple;
									found = 1;
								end
						end
					if(found)
					begin
						//set last two high cards
						for(i=0;i<7;i = i+1)
							begin
								if(cards[36-6*i+:4] != win[19:16])
									begin
										if(win[7:4] == 0)
											begin
												win[7:4] = cards[36-6*i+:4];
											end
										else if(win[3:0] == 0)
											begin
												win[3:0] = cards[36-6*i+:4];
											end
									end
							end
					end
				end	
			//check two pair, store two highest pairs in win[19:4]
			if(!found)
				begin:findtwopair
					integer fpr,spr,j;
					for(fpr=0; fpr<13; fpr = fpr+1)
						begin
							//card rank
							if(cardinfo[4*fpr]+cardinfo[4*fpr+1]+cardinfo[4*fpr+2]+cardinfo[4*fpr+3] == 2 && !found)
								begin
									//find second pair
									for(spr = 0; spr <13; spr = spr + 1)
										begin
											if(cardinfo[4*spr]+cardinfo[4*spr+1]+cardinfo[4*spr+2]+cardinfo[4*spr+3] == 2 && rank[spr*4+:4] != rank[fpr*4+:4] && rank[spr*4+:4] > win[11:8])
												begin
													//set first pair to higher rank
													win[19:16] = rank[fpr*4+:4];
													win[15:12] = rank[fpr*4+:4];
													//set second pair to lower rank
													win[11:8] = rank[spr*4+:4];
													win[7:4] = rank[spr*4+:4];
													//set wincond to twopair
													win[23:20] = twopair;
													//set found
													found = 1;	
												end
										end
								end
						end
					if(found)
					begin
						//set rest of highcards
						for(j=0;j<7;j = j+1)
							begin
								if( cards[36-(6*j)+:4] != win[19:16] && cards[36-(6*j)+:4] != win[11:8])
									begin
										if(win[3:0] == 0)
											begin
												win[3:0] = cards[36-(6*j)+:4];
											end
									end
							end
					end
				end
			//check pair, store highest pair in win[19:16]
			if(!found)
				begin:findpair
					integer pr,k;
					for(pr=0; pr<13; pr = pr+1)
						begin
							//card rank
							if(cardinfo[4*pr]+cardinfo[4*pr+1]+cardinfo[4*pr+2]+cardinfo[4*pr+3] == 2)
								begin
									//set pair to rank, set wincond to pair
									win[19:16] = rank[pr*4+:4];
									win[15:12] = rank[pr*4+:4];
									win[23:20] = pair;
									found = 1;
								end
						end
					if(found)
					begin
					//set 3 high cards
					for(k=0;k<7;k = k+1)
						begin
							if(cards[36-6*k+:4] != win[19:16])
								begin
									if(win[11:8] == 0)
										begin
											win[11:8] = cards[36-6*k+:4];
										end
									else if(win[7:4] == 0)
										begin
											win[7:4] = cards[36-6*k+:4];
										end
									else if(win[3:0] == 0)
										begin
											win[3:0] = cards[36-6*k+:4];
										end
								end
						end
					end
				end
			//store highcards
			if(!found)
				begin:sethighcards
					win[19:16] = cards[39:36];			
					win[15:12] = cards[33:30];					
					win[11:8] = cards[27:24];
					win[7:4] = cards[21:18];
					win[3:0] = cards[15:12];	
				end
		end
endmodule 