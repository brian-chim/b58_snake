// DO NOT USE - PROBABLY DOES NOT WORK AND TAKES ABOUT 3 HOURS TO COMPILE

// MAIN MODULE
module game (
    CLOCK_50,                           //    On Board 50 MHz
    // Your inputs and outputs here
    KEY,
    SW,
    // The ports below are for the VGA output.  Do not change.
    VGA_CLK,                            //    VGA Clock
    VGA_HS,                             //    VGA H_SYNC
    VGA_VS,                             //    VGA V_SYNC
    VGA_BLANK_N,                        //    VGA BLANK
    VGA_SYNC_N,                         //    VGA SYNC
    VGA_R,                              //    VGA Red[9:0]
    VGA_G,                              //    VGA Green[9:0]
    VGA_B,                              //    VGA Blue[9:0]
    HEX0,
    HEX1,
    HEX2,
    HEX3,
	  HEX4,
	  HEX5,
	  HEX6,
	  HEX7,
    LEDR);

    input       CLOCK_50;               //    50 MHz
    input       [17:0] SW;
    input       [3:0] KEY;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX6, HEX5, HEX7;
    output [0:0] LEDR;
    // Declare your inputs and outputs here
    // Do not change the following outputs
    output      VGA_CLK;                //    VGA Clock
    output      VGA_HS;                 //    VGA H_SYNC
    output      VGA_VS;                 //    VGA V_SYNC
    output      VGA_BLANK_N;            //    VGA BLANK
    output      VGA_SYNC_N;             //    VGA SYNC
    output      [9:0] VGA_R;            //    VGA Red[9:0]
    output      [9:0] VGA_G;            //    VGA Green[9:0]
    output      [9:0] VGA_B;            //    VGA Blue[9:0]

    wire resetn;
    assign resetn = KEY[0];

    // The two wires below will hold the x values for the two tron objects (one for each object)
    wire [7:0] t1x, t2x;
	// The two registers below will hold the x and y values for the objects being drawn (to be outputted to the VGA adapter)
	reg [7:0] x;
	reg [6:0] y;
	// This colour register will hold the 3 bit colour value for the objects being drawn (again, to be outputted to the VGA adapter)
	reg [2:0] colour;
	// The two wires below will hold the y values for the two tron objects (one for each object)
    wire [6:0] t1y, t2y;
	// The wires below will carry values for the x and y offsets of the two tron objects
    wire [1:0] xposoff1, yposoff1, xposoff2, yposoff2;
	// The switch register will allow us to cycle between states under our always block (during the time that the two players are not dead or the
	// pause button is off)
    reg [1:0] switch;
	// Write enable will control when objects are being drawn or not  
	reg writeEn;
	// A wire to carry out a fast clock signal to the datapaths of the tron objects being drawn
    wire clk_out_fast;
	// This counter register 
    reg [24:0] counter;
	// The two score registers below will keep track of each player's score
    reg [3:0] p1Score, p2Score;

    // Create a fast counter
    rate_divider_fast fast_clk(
        .enable(SW[17]),
        .clkin(CLOCK_50),
        .clkout(clk_out_fast));


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
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "tron.mif";
    wire reposition;

    // Instantiate a module for the datapath of the first tron object (player 1, colour blue)
    tron_datapath_1 d1(
        .clk(clk_out_fast),
        .coordsX(t1x),
        .coordsY(t1y),
        .xOffset(xposoff1),
        .yOffset(yposoff1),
        .resetn(reposition));
	assign reposition = SW[16] || p1Dead || p2Dead;
	
    // Instantiate a module for the datapath of the second tron object (player 2, colour red)
    tron_datapath_2 d2(
        .clk(clk_out_fast),
        .coordsX(t2x),
        .coordsY(t2y),
        .xOffset(xposoff2),
		.yOffset(yposoff2),
        .resetn(reposition));
	assign defaultDirection = KEY[3] || p1Dead || p2Dead;
	
    // Instansiate FSM control module for player 1
    tron_control c1(
        .clk(CLOCK_50),
		.SW(SW[12:9]), // switches 12 to 9 will control player 1
        .resetn(defaultDirection),
        .xOffset(xposoff1),
        .yOffset(yposoff1));
		
	// CONTROLS FOR P1 - SW[12] = LEFT, SW[11] = DOWN, SW[10] = UP, SW[9] = RIGHT

    // Instansiate FSM control module for player 2
    tron_control c2(
        .clk(CLOCK_50),
		.SW(SW[3:0]), // switches 3 to 0 will control player 2
        .resetn(defaultDirection),
        .xOffset(xposoff2),
        .yOffset(yposoff2));
		
    // CONTROLS FOR P2 - SW[3] = LEFT, SW[2] = DOWN, SW[1] = UP, SW[0] = RIGHT

    // This module will count the gameplay time elapsed
    timeCount count(
       .SW(SW[17]),
       .CLOCK_50(CLOCK_50),
       .HEX0(HEX0),
       .HEX1(HEX1),
       .HEX2(HEX2),
       .HEX3(HEX3));

	integer i,j;
	// The 2 registers below will keep track of whether or not either player has died
	reg p1Dead, p2Dead;
	// The board register will represent the playing field. Each pixel register is stored in a 2-D array
	// and the pixel register will either have a value of 1 or 0. This will help us when we detect border
	// collision
    reg board [0:148][0:117];
    reg [7:0] xHold[0:1];
    reg [6:0] yHold[0:1];
      // Both tron players are alive by default (obviously) and so there dead registers are set to 0 
	  initial begin
		p1Dead = 0;
		p2Dead = 0;
		i = 11;
		j = 18;
		// Set a few pixel registers to be dead zones (in order to account for a few calculation issues)

	  end
	  
	// We will draw each tron player on the positive edge of the 50 MHz clock. 
	// Since the clock speed is very quick, drawing the 2 players on different edges is fine and will
	// look seamless to the human eye
    always @(posedge CLOCK_50) begin
	     // If either player 1 or 2 is in a dead state...
		 if (SW[16] || p1Dead == 1 || p2Dead == 1) begin
		    // We will begin to draw black over the whole screen in order to "reset" the board to its original
			// state
		    writeEn <= 1;
			colour <= 3'b000;
			   
			// If our i and j values have reached the last pixel, then we know we are done drawing the black
			// screen and we can then reset the dead registers back to 0 for both players. We must also
			// set our writeEn back to 0
			if (i == 148 && j == 107) begin
				p1Dead <= 0;
				p2Dead <= 0;
			    i <= 11;
				j <= 18;
				writeEn <= 0;
			end
			// Otherwise, we will continue to increment our i and j values in order to draw the black squares
			// over the playing field. 
			// HOW IT WORKS - we will draw along the x axis first and once we've reached the end, we will increment
			// the value on our y axis by 1 and repeat the process
			else if (i < 148 && j == 107) begin
				i <= i + 1;
				j <= 18;
			end
			else if (j < 107) begin
				j <= j + 1;
			end
			   // our x and y registers will take in the values of i and j respectively
			board[i][j] <= 0;
			x <= i;
			y <= j;
		 end
		 // During the time that both players are alive...
		 if (~SW[16] && p1Dead == 0 && p2Dead == 0) begin
		    // SWITCH STATE 1 -
			if (switch == 2'b00) begin
			    // If we find that player 1 has either collided with the board, with player 2's head, or with any of the boundaries,
				// then player 1 will be dead and their register will be assigned the appropriate value
				if(board[t1x][t1y] != 0 || (t1x == t2x && t1y ==t2y) || t1x == 8'd10 || t1x == 8'd149 || t1y == 7'd17 || t1y == 7'd108) begin
				    p1Dead <= 1;
				end
					
				// Otherwise, we will draw player 1 normally by assigning the appropriate register values for x, y, colour, and writeEn
				// We will also increment our switch register by 1 in order to move on to the next switch state when we hit the next positive
				// edge of our super fast clock
			    else begin
					if (xHold[0] != t1x || yHold[0] != t1y) begin
						xHold[0] <= t1x;
						yHold[0] <= t1y;
						board[t1x][t1y] <= 1;
					end

						x <= t1x;
						y <= t1y;
						colour <= 3'b001;
						writeEn <= 1;
						switch <= switch + 1;
					
				end
			end
				
			// SWITCH STATE 2 -
			else if (switch == 2'b01) begin
			// The check for death for player 2 is the same as player 1. The same goes for when we are drawing player 2 on the board
				if(board[t2x][t2y] != 0 || t2x == 8'd10 || t2x == 8'd149 || t2y == 7'd17 || t2y == 7'd108) begin
					p2Dead <= 1;
				end
				else begin
					if (xHold[1] != t2x || yHold[1] != t2y) begin
						xHold[0] <= t2x;
						yHold[0] <= t2y;
						board[t2x][t2y] <= 1;
					end
					x <= t2x;
					y <= t2y;
					colour <= 3'b100;
					writeEn <= 1;
					switch <= switch + 1;
				end
			end
		else
			writeEn <= 0;
		    // this if block is to reset the switch value
		    if (counter < 5999998)
			    counter <= counter + 1;
	        else begin
				counter <= 0;
				switch <= 0;
			end
	  end
    end
   
	// LEDR[0] will light up when either player 1 or 2 is dead
	assign LEDR[0] = p1Dead || p2Dead;
	scoreKeep player1Score(p2Dead, HEX6);
	scoreKeep player2Score(p1Dead, HEX4);
	scoreKeep player1ScoreH(KEY[2], HEX7); // HONOUR POINTS P1
	scoreKeep player2ScoreH(KEY[1], HEX5); // HONOUR POINTS P2
endmodule

// MODULE FOR KEEPING TRACK OF THE PLAYER'S ACTUAL SCORES AND HONOUR SCORE
module scoreKeep(
		input givePoint,
		output [6:0] hex0,
		output [6:0] hex1);
	
	reg [3:0] ones, tens;
	initial begin
	  ones = 0;
	  tens = 0;
	end
	
	// Every time a player dies, the other person gains a point
	always@(posedge givePoint) begin
		if (ones < 9) begin
			ones <= ones + 1;
		end
		// Once we reach 10, we reset our ones register to 0 and begin counting up the tens
		else begin
			ones <= 0;
			tens <= tens + 1;
		end
	end
	hex_decoder hex6(ones, hex0);
	hex_decoder hex7(tens, hex1);
endmodule

// MODULE FOR PLAYER 1's DATAPATH (MOVEMENT)
module tron_datapath_1(
    input clk,
    input [1:0] xOffset,
    input  [1:0] yOffset,
    input resetn,
    output [7:0] coordsX,
    output [6:0] coordsY);

    reg [7:0] y_coordinate;
	reg [7:0] x_coordinate;

	// Declare the initial position of player 1 on the screen
	initial begin
		x_coordinate = 8'd25;
		y_coordinate = 7'd100;
	end

	// The clock will be based on the positive edge of the fast drawing clock that we have in our top level module (NOT CLOCK_50
    always @(posedge clk) begin
        // setup x and y coordinates to be used
		if (resetn != 1) begin
			// if the x offset is 2'b01, increment x in order to move right
		    if (xOffset == 2'b01)begin
				x_coordinate <= x_coordinate + 1'b1;
		     end
			// if the x offset is 2'b10, decrement x in order to move left
		    else if (xOffset == 2'b10) begin
			    x_coordinate <= x_coordinate - 1'b1;
		    end
			// if the y offset is 2'b01, increment y in order to move down
		    if (yOffset == 2'b01)begin
			    y_coordinate <= y_coordinate + 1'b1;
		    end
			// if the y offset is 2'b01, increment y in order to move up
		    else if (yOffset == 2'b10) begin
			    y_coordinate <= y_coordinate - 1'b1;
		    end
		end
		// x and y coordinates will be set back to their initial states
	   else begin
		    x_coordinate <= 8'd25;
		    y_coordinate <= 7'd100;
	   end
	end
	assign coordsY = y_coordinate;
    assign coordsX = x_coordinate;
endmodule

// MODULE FOR PLAYER 2's DATAPATH (MOVEMENT) - LITERALLY THE SAME BUT WITH DIFFERENT INITIAL STARTING VALUES
module tron_datapath_2(
    input clk,
    output [7:0] coordsX,
	output [6:0] coordsY,
    input [1:0] xOffset,
    input  [1:0] yOffset,
    input resetn);

    reg [7:0] y_coordinate;
	reg [7:0] x_coordinate;

	initial begin
		x_coordinate = 8'd135;
		y_coordinate = 7'd100;
	end

    always @(posedge clk) begin
        // setup x coordinate
		if (resetn != 1) begin
		if (xOffset == 2'b01)begin
			x_coordinate <= x_coordinate + 1'b1;
		end
		else if (xOffset == 2'b10) begin
			x_coordinate <= x_coordinate - 1'b1;
		end
		if (yOffset == 2'b01)begin
			y_coordinate <= y_coordinate + 1'b1;
		end
		else if (yOffset == 2'b10) begin
			y_coordinate <= y_coordinate - 1'b1;
		end
		end
		else begin
			x_coordinate <= 8'd135;
			y_coordinate <= 7'd100;
		end
	end

    assign coordsY = y_coordinate;
    assign coordsX = x_coordinate;
endmodule

// FSM FOR THE TWO TRON PLAYERS
module tron_control(
    input clk,
    input resetn,
	input [3:0] SW,
    output reg [1:0] xOffset,
    output reg [1:0] yOffset);

	// Registers will be used to keep track of what the current and next state are
    reg [2:0] current_state, next_state;
	// The 4 different states that our players can be in (i.e., the directions that they can move in)
    localparam  down = 2'b00,
                right = 2'b01,
                up = 2'b10,
                left = 2'b11;

    // assign what the next_state is on the positive edge of CLOCK_50
    always@(posedge clk)
    begin: state_table
      case (current_state)
		// moving in the up direction
        up: begin: turn_table_1
			       case (SW[3:0])
						 // While we're moving up, we can either move to the left, right, or stay
						 // in the same direction
				         4'b0001: next_state = right;
				         4'b1000: next_state = left;
				         default: next_state = up;
			       endcase
			end
		// moving in the right direction
		right: begin: turn_table_2
				    case (SW[3:0])
						// While we're moving in the right direction, we can either move up, down, or stay right
					     4'b0010: next_state = up;
					     4'b0100: next_state = down;
					     default: next_state = right;
				     endcase
			 end
		// moving in the down direction
		down: begin: turn_table_3
				      case (SW[3:0])
					     // While we're moving in the down direction, we can either move left, right, or stay down
					     4'b0001: next_state = right;
					     4'b1000: next_state = left;
					     default: next_state = down;
			         endcase
            end
		// moving in the left direction
		left: begin: turn_table_4
				      case (SW[3:0])
						 // While we're moving in the left direction, we can either move down, up, or stay left
					     4'b0100: next_state = down;
					     4'b0010: next_state = up;
					     default: next_state = left;
				     endcase
            end
      default: next_state = up;
      endcase
  end
  // Assign offsets
  always@(*)
  begin: make_output
      case(current_state)
	  // x offset set to 0 ensures our movement doesn't change on the x axis
	  // y offset set to 2'b01 ensures we're moving vertically upwards
       up: begin
				        xOffset <= 2'b00;
				        yOffset <= 2'b01;
			        end
	  // x offset set to 2'b01 ensures we're moving to the right horizontally
	  // y offset set to 0 ensures our movement doesn't change on the y axis
	   right: begin
				        xOffset <= 2'b01;
				        yOffset <= 2'b00;
		         end
	   // x offset set to 0 ensures our movement doesn't change on the x axis
	   // y offset set to 2'b10 ensures we're moving vertically downwards
       down: begin
                xOffset <= 2'b00;
                yOffset <= 2'b10;
		         end
		// x offset set to 2'b10 ensures we're moving to the left horizontally
	    // y offset set to 0 ensures our movement doesn't change on the y axis
       left: begin
				        yOffset <= 2'b00;
				        xOffset <= 2'b10;
			       end
      default: begin
			        	xOffset <= 2'b00;
				        yOffset <= 2'b00;
			         end
      endcase
    end

    // Moving on to the next state
    always@(posedge clk)
    begin: state_FFs
		
        if(!resetn) // goto resting if reset
            current_state <= down;
        // Otherwise, proceed to move to the next state
		else
            current_state <= next_state;
    end

endmodule
