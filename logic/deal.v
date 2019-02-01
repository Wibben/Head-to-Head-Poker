// Generates the cards on the table
module deal (
	input clk, rst_n,go,
	output done,
	output reg[53:0] cards
	);	
	//cards, 6 bits, first two bits are suit, last four bits are rank c1 : SSRRRR
	//Suits: 11->diamonds 10->spades 01->hearts 00->clubs
	//Ranks: 1110->Ace 1101->King 1100->Queen 1011->Jack 1010->ten ...
	//9 cards in register to store: first 5 cards are community cards, next 2 cards are player cards, next 2 cards are computer cards
	//randbit from generator
	wire randbit;
	// seed from counter, initiate seed value when game starts
	wire[15:0] seed;
	//temporary register to hold card being generator
	reg[5:0] card;
	//counter to see if 6 new bits were generated
	reg[2:0] bits;
	
	
	// For whether to enable or not
	reg enable;
	always @(posedge clk)
	begin
		if(!rst_n) // Active low reset
			enable <= 1'b0;
		else if(go) // Start the generator
			enable <= 1'b1;
		else if(done) // Stop the generator
			enable <= 1'b0;
	end
	
	//Current set up for seed might be risky, might need to store seed value and keep going off that to avoid playing same hand twice
	
	//set seed from random start time, counter
	counter C1(.clk(clk),.rst_n(rst_n),.q(seed));
	//random bit generator
	generatebit G1(
		.clk(clk),.rst_n(rst_n),.go(go),
		.seed(seed),.dataout(randbit)
	);

	always@(posedge clk or negedge rst_n)
		begin
			if(~rst_n)
				begin
					cards <= 54'b0;
					card	<= 6'b0;
					bits  <= 3'b0;
				end
			else if(go) // Start of generator, reset
			begin
				cards <= 54'b0;
				card	<= 6'b0;
				bits  <= 3'b0;
			end
			else if(enable)
			begin
				if(bits < 6)
					begin
						card <= {card[4:0],randbit};
						bits <= bits + 1'b1;
					end
				else if(bits == 6)
					begin
						//check if card has a valid rank
						if(card[3:0] < 2 || card[3:0] == 15)
							bits <= bits - 1'b1;
						else
							begin
								//check if card is already taken
								if(cards[53:48] == 0)
									cards[53:48] <= card[5:0];
								else if(cards[47:42] == 0)
									if(card[5:0] != cards[53:48])
										cards[47:42] <= card[5:0];
									else
										bits <= bits - 1'b1;
								else if(cards[41:36] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42])
										cards[41:36] <= card[5:0];
									else
										bits <= bits - 1'b1;
								else if(cards[35:30] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42] && card[5:0] != cards[41:36])
										cards[35:30] <= card[5:0];
									else
										bits <= bits - 1'b1;
								else if(cards[29:24] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42] && card[5:0] != cards[41:36] && 
										card[5:0] != cards[35:30])
										cards[29:24] <= card[5:0];
									else
										bits <= bits - 1'b1;
								else if(cards[23:18] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42] && card[5:0] != cards[41:36] && 
										card[5:0] != cards[35:30] && card[5:0] != cards[29:24])
										cards[23:18] <= card[5:0];
									else
										bits <= bits - 1'b1;
								else if(cards[17:12] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42] && card[5:0] != cards[41:36] && 
										card[5:0] != cards[35:30] && card[5:0] != cards[29:24] && card[5:0] != cards[23:18])
										cards[17:12] <= card[5:0];
									else
										bits <= bits - 1'b1;
								else if(cards[11:6] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42] && card[5:0] != cards[41:36] && 
										card[5:0] != cards[35:30] && card[5:0] != cards[29:24] && card[5:0] != cards[23:18] &&
										card[5:0] != cards[17:12])
										cards[11:6] <= card[5:0];
									else
										bits <= bits - 1'b1;			
								else if(cards[5:0] == 0)
									if(card[5:0] != cards[53:48] && card[5:0] != cards[47:42] && card[5:0] != cards[41:36] && 
										card[5:0] != cards[35:30] && card[5:0] != cards[29:24] && card[5:0] != cards[23:18] &&
										card[5:0] != cards[17:12] && card[5:0] != cards[11:6])
										cards[5:0] <= card[5:0];
									else
										bits <= bits - 1'b1;
								//reset cards and bits after card is stored
								card <= 6'b000000;
								bits <= 3'b000;
							end
					end
			end
		end
		
		// Set up done signal
		assign done = (cards[5:0]!=0);
endmodule

//RNG
module generatebit (input clk,rst_n,go, input[15:0] seed, output dataout);
	reg[15:0] data;
	//taps in LFSR
	wire feedback = data[15] ^ data[14] ^ data[12] ^ data[3];
	//generate random bit, seed determines start of sequence
	always @(posedge clk or negedge rst_n)
		begin
		if (~rst_n) 
			data <= 16'b0000000000000000;
		else if(go)
			data <= seed;
		else
			data <= {data[14:0],feedback} ;
	end
	//output newest generate bit
	assign dataout = data[0];
endmodule 

module counter(input clk,rst_n,output reg[15:0] q);
	//time counter, set rst_n to seed value you want to test
	always @(posedge clk)
		begin
			if(~rst_n)
				q <= 16'b0000000000000000;
			else if (q == 16'b1111111111111111)
				q <= 16'b0000000000000001;
			else
				q <= q + 1'b1;
		end
endmodule 
