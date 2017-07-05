module game(SW, KEY, CLOCK_50, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0
            VGA_CLK, VGA_HS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
  // Two KEYs will be used. KEY[3] will be our reset button and KEY[2] will be our start button
  input [3:2] KEY;
  input CLOCK_50;
  input [17:0] SW;  
  
  // HEX displays to keep track of things like time, highscore, and in-game score
  output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
  
  // Outputs for the VGA adapter
  output VGA_CLK;
  output VGA_HS;
  output VGA_BLANK_N;
  output VGA_SYNC_N;
  output [9:0] VGA_R;
  output [9:0] VGA_G;
  output [9:0] VGA_B;
  
  // Wires will be used to carry output signals to the hex displays
  wire [6:0] hex7Seg, hex6Seg, hex5Seg, hex4Seg, hex3Seg, hex2Seg, hex1Seg, hex0Seg;
  
  // Declaration and assignment for our reset, start and game mode button
  wire reset_n, start, game_mode;
  assign reset_n = KEY[3];
  assign start = KEY[2];
  assign game_mode = SW[17];
  
           
  vga_adapter VGA(.resetn(reset_n),
                  .clock(CLOCK_50),
	      .colour(colour),
	      .x(),
	      .y(),
	      .plot(start),
	      .VGA_R(VGA_R),
	      .VGA_G(VGA_G),
	      .VGA_B(VGA_B),
	      .VGA_HS(VGA_HS),
	      .VGA_VS(VGA_VS),
	      .VGA_BLANK(VGA_BLANK_N),
	      .VGA_SYNC(VGA_SYNC_N),
	      .VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "100x100";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif"
	
  // player_1's moving piece
  datapath tron_p1_datapath(); 
  control tron_p1_control();
  
  // player_2's moving piece
  datapath tron_p2_datapath(); 
  control tron_p2_control();

  
  hex_decoder hex_0(.hex_digit(hex0Seg), .segments(HEX0));
  hex_decoder hex_1(.hex_digit(hex1Seg), .segments(HEX1));
  hex_decoder hex_2(.hex_digit(hex2Seg), .segments(HEX2));
  hex_decoder hex_3(.hex_digit(hex3Seg), .segments(HEX3));
  hex_decoder hex_4(.hex_digit(hex4Seg), .segments(HEX4));
  hex_decoder hex_5(.hex_digit(hex5Seg), .segments(HEX5));
  hex_decoder hex_6(.hex_digit(hex6Seg), .segments(HEX6));
  hex_decoder hex_7(.hex_digit(hex7Seg), .segments(HEX7));
endmodule

module datapath(clk, reset, game_mode, start, ld_x_p1, ld_y_p1, ld_colour_p1, ld_colour_p2, x_out, y_out, colour_out);
endmodule

module control();
endmodule

