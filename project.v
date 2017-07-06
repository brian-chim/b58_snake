module game(SW, KEY, CLOCK_50, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
            VGA_CLK, VGA_HS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B);
  // Two KEYs will be used. KEY[3] will be our reset button and KEY[2] will be our start button
  input [3:2] KEY;
  input CLOCK_50;
  input [17:0] SW;  
 
  // HEX displays to keep track of things like time, highscore, and in-game score  output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
  
  // Outputs for the VGA adapter  output VGA_CLK;
  output VGA_HS;
  output VGA_BLANK_N; 
  output VGA_SYNC_N;
  output [9:0] VGA_R;
  output [9:0] VGA_G; 
  output [9:0] VGA_B;
  // Wires will be used to carry output signals to the hex displays
  wire [6:0] hex7Seg, hex6Seg, hex5Seg, hex4Seg, hex3Seg, hex2Seg, hex1Seg, hex0Seg;
  
  // Declaration and assignment for our reset, start and game mode button  wire reset_n, start, game_mode;
  assign reset_n = KEY[3];
  assign start = KEY[2];
  assign game_mode = SW[17];  
  // Wires to carry the x and y values as well as the colour
  wire [7:0] x;  wire [6:0] y;
  wire [2:0] colour;
  
//   // ------------------------------------------------------------
  //   // Let Sw[17] be the switch to control game select
//   // output reg stuff for the always statement

            //   always(*)
//   begin
//    if(SW[17] == 1)
//       // call Tron
//     else
//       // call Snake
//   end
//  // ------------------------------------------------------------

  vga_adapter VGA(.resetn(reset_n),
                  .clock(CLOCK_50),
	      .colour(colour),
	      .x(x),
	      .y(y),	     
              .plot(start),
	      .VGA_R(VGA_R),
	      .VGA_G(VGA_G),
	      .VGA_B(VGA_B),
	      .VGA_HS(VGA_HS),
	      .VGA_VS(VGA_VS),
	      .VGA_BLANK(VGA_BLANK_N),
	      .VGA_SYNC(VGA_SYNC_N),
	      .VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif"
  
  snake_control snake_c(.start(start),
                  .reset(reset_n), 
                  .clk(CLOCK_50), 
                  .game_mode(game_mode), 
                  .player_control_x(SW[1]),
	          .player_control_y(SW[0]),
                  .highscore_HEX6(hex6Seg),
                  .highscore_HEX7(hex7Seg), 
                  .eaten_objects_HEX4(hex4Seg),
                  .eaten_objects_HEX5(hex5Seg), 
                  .time_HEX0(hex0Seg),
                  .time_HEX1(hex1Seg), 
                  .time_HEX2(hex2Seg),
                  .time_HEX3(hex3Seg),
	          .x_load(),
	          .y_load());
    
  snake_datapath snake_d();
            
  tron_control tron_c(.start(start),
                 .reset(reset_n), 
                 .clk(CLOCK_50),
                 .game_mode(game_mode),
                 .player1_control_left(SW[1]),
        	 .player1_control_right(SW[0]),
                 .player_2_control_left(SW[7]),
		 .player_2_control_right(SW[6]),
                 .player_1_HEX6(hex6Seg),
                 .player_1_HEX7(hex7Seg), 
                 .player_2_HEX4(hex4Seg), 
                 .player_2_HEX5(hex5Seg),
                 .time_HEX0(hex0Seg), 
                 .time_HEX1(hex1Seg), 
                 .time_HEX2(hex2Seg), 
                 .time_HEX3(hex3Seg)
		 .x_p1_load(),
		 .y_p1_load(),
		 .x_p2_load(),
		 .y_p2_load());
	
  tron_datapath tron_d();
  
  hex_decoder hex_0(.hex_digit(hex0Seg), .segments(HEX0));
  hex_decoder hex_1(.hex_digit(hex1Seg), .segments(HEX1));
  hex_decoder hex_2(.hex_digit(hex2Seg), .segments(HEX2));
  hex_decoder hex_3(.hex_digit(hex3Seg), .segments(HEX3));
  hex_decoder hex_4(.hex_digit(hex4Seg), .segments(HEX4));
  hex_decoder hex_5(.hex_digit(hex5Seg), .segments(HEX5));
  hex_decoder hex_6(.hex_digit(hex6Seg), .segments(HEX6));
  hex_decoder hex_7(.hex_digit(hex7Seg), .segments(HEX7));
endmodule


module snake_control(start, 
             reset, 
             clk,
             game_mode,
             player_control_x,
	     player_control_y,
             highscore_HEX6,
             highscore_HEX7,
             eaten_objects_HEX4,
             eaten_objects_HEX5, 
             time_HEX0, 
             time_HEX1,
             time_HEX2,
             time_HEX3,
	     x_load,
	     y_load);
  input start;
  input reset;
  input clk;
  input game_mode;
  input [1:0] player_controls;
  output [3:0] highscore_HEX6, highscore_HEX7, eaten_objects_HEX4, eaten_objects_HEX5, time_HEX0, time_HEX1, time_HEX2, time_HEX3;
            
endmodule

module snake_datapath();
endmodule

module tron_control(start,
            reset, 
            clk, 
            game_mode,
            player_1_control_left,
	    player_1_control_right,
            player_2_control_left,
	    player_2_control_right,
            player_1_HEX6,
            player_1_HEX7,
            player_2_HEX4,
            player_2_HEX5, 
            time_HEX0, 
            time_HEX1,
            time_HEX2, 
            time_HEX3,
	    x_p1_load,
	    y_p1_load,
	    x_p2_load,
	    y_p2_load);
  input start;
  input reset;
  input clk;
  input game_mode;
  input player_1_control_left;
  input player1_control_right;
  input player_2_control_left;
  input player_2_control_right;
  input [1:0] player_2_controls;
  output [3:0] highscore_HEX6, highscore_HEX7, eaten_objects_HEX4, eaten_objects_HEX5, time_HEX0, time_HEX1, time_HEX2, time_HEX3;
endmodule

module tron_datapath();
endmodule
