`timescale 1ns / 1ns

// Top level module
module poker
	(
		CLOCK_50,				//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,						// On Board Keys
		LEDR,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   				//	VGA Clock
		VGA_HS,					//	VGA H_SYNC
		VGA_VS,					//	VGA V_SYNC
		VGA_BLANK_N,			//	VGA BLANK
		VGA_SYNC_N,				//	VGA SYNC
		VGA_R,   				//	VGA Red[9:0]
		VGA_G,	 				//	VGA Green[9:0]
		VGA_B,  					//	VGA Blue[9:0]
		// Keyboard
		PS2_CLK,
		PS2_DAT
	);

	input			CLOCK_50;				//	50 MHz
	input	[5:0]	KEY;
	// Declare your inputs and outputs here
	output [9:0] LEDR;
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[7:0] Changed from 10 to 8-bit DAC
	output	[7:0]	VGA_G;	 				//	VGA Green[7:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[7:0]
	// Keyboard
	inout PS2_CLK;
	inout PS2_DAT;
	
	// RESET - Active low
	wire resetn;
	assign resetn = KEY[0]; // Active low, so don't invert
	
	// Instantiate keyboard FSM
	wire key_go,key_left,key_right;
	
	keyboard key(
		.clock(CLOCK_50),.resetn(resetn),
		.PS2_CLK(PS2_CLK),.PS2_DAT(PS2_DAT),
		.go(key_go),.left(key_left),.right(key_right)
	);
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [8:0] colour; // 4 bit colour
	wire [8:0] x,y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 3;
		defparam VGA.BACKGROUND_IMAGE = "./resources/sprites/bg.hex";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn
	// for the VGA controller, in addition to any other functionality your design may require.
	
	// Input wires
	wire go,left,right;
	wire anti_freeze;
	
	// Control wires
	wire ld_xy,ld_pos,ld_colour;
	wire draw_pixel;
	wire[8:0] dx,dy;
	wire[8:0] X_IN,Y_IN;
	wire[8:0] COLOUR_DATA;
	
	assign go = ~KEY[3] | key_go; // Space - 8'h29
	assign left = ~KEY[2] | key_left; // Left - 8'h6B
	assign right = ~KEY[1] | key_right; // Right - 8'h74
	assign anti_freeze = ~KEY[5];
	
	// Control module
	control con(
		.clock(CLOCK_50),.resetn(resetn),.anti_freeze(anti_freeze),
		.go(go),.left(left),.right(right),
		.ld_xy(ld_xy),.ld_pos(ld_pos),.ld_colour(ld_colour),
		.draw_pixel(draw_pixel),
		.x(X_IN),.y(Y_IN),.dx(dx),.dy(dy),
		.colour(COLOUR_DATA),.LEDR(LEDR)
	);
	
	// Controls plotting on VGA
	assign writeEn = draw_pixel;
	
	// Datapath module
	datapath dat(
		.clock(CLOCK_50),.resetn(resetn),
		.X_IN(X_IN),.Y_IN(Y_IN),
		.COLOUR_DATA(COLOUR_DATA),
		.ld_xy(ld_xy),.ld_colour(ld_colour),.ld_pos(ld_pos),
		.dx(dx),.dy(dy),
		.xpos(x),.ypos(y),.colour(colour)
	);
endmodule
