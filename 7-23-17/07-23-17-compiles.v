// UPDATED 07/23z/2017 2:41 by Mason

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
  LEDR
    );

    input       CLOCK_50;               //    50 MHz
    input       [17:0] SW;
    input       [3:0] KEY;

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
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
    output [1:0] LEDR;
    wire resetn;
    assign resetn = KEY[0];

   // wires for x,y, colour outputs for the two trons
	 reg [7:0] xHold [1:0];
    reg [6:0] yHold [1:0];
	 reg [7:0] x;
	 reg [6:0] y;
	 reg [2:0] colour;
    wire [2:0] colourSnakeA, colourSnakeB;
    wire [1:0] xposoff1, yposoff1, xposoff2, yposoff2;
    wire resetGame;
    reg [1:0] switch;
	 reg writeEn;
	 reg p1Dead, p2Dead;
    wire clk_out_fast;
    wire clk_out_slow;
    reg [24:0] counter;
    assign resetGame = SW[17];
    // create a fast counter
    rate_divider_fast fast_clk(
        .enable(resetGame),
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

    // Instansiate FSM control module for first tron
    tron_control c1(
        .clk(CLOCK_50),
		    .SW(SW[3:0]),
        .go(!KEY[2]),
        .resetn(KEY[3]),
        .xOffset(xposoff1),
        .yOffset(yposoff1),
        .plot(writeEn1));

    // Instansiate FSM control module for second tron
    tron_control c2(
        .clk(CLOCK_50),
		    .SW(SW[12:9]),
        .go(!KEY[2]),
        .resetn(KEY[3]),
        .xOffset(xposoff2),
        .yOffset(yposoff2),
        .plot(writeEn2));

    // instantiates the timecount module
   timeCount count(
       .SW(resetGame),
       .CLOCK_50(CLOCK_50),
       .HEX0(HEX0),
       .HEX1(HEX1),
       .HEX2(HEX2),
       .HEX3(HEX3));

   //sets up the boarder (git it?)
   reg board[0:159][0:119];

	reg [7:0] p1x, p2x;
	reg [6:0] p1y, p2y;
	always@(posedge clk_out_fast) begin
	  if (p1Dead != 1 && p2Dead != 1) begin
		  if (switch == 2'b00) begin
			 if (resetn == 1) begin
				if (xposoff1 == 2'b01)begin
				  p1x <= p1x + 1'b1;
				end
				else if (xposoff1 == 2'b10) begin
				  p1x <= p1x - 1'b1;
				end
				if (yposoff1 == 2'b01)begin
				  p1y <= p1y + 1'b1;
				end
				else if (yposoff1 == 2'b10) begin
				  p1y <= p1y  - 1'b1;
				end
			 end
			 else begin
				p1x <= 8'd25;
				p1y <= 7'd25;
			 end
			 if (board[p1x][p1y] == 1 || p1x == 17 || p1x == 108 || p1y == 10 || p1y == 149) begin
				p1Dead <= 1;
			 end
			 else begin
				board[p1x][p1y] <= 1;
			 end
			 if (p1Dead == 0) begin
				 x <= p1x;
				 y <= p1y;
				 colour <= colourSnakeA;
				 writeEn <= 1;
			 end
			 else begin
				writeEn <= 0;
			 end
			 switch <= switch + 1;
		  end
		  else if (switch == 2'b01) begin
			if (resetn == 1) begin
				if (xposoff2 == 2'b01)begin
				  p2x <= p2x + 1'b1;
				end
				else if (xposoff1 == 2'b10) begin
				  p2x <= p2x - 1'b1;
				end
				if (yposoff1 == 2'b01)begin
				  p2y <= p2y + 1'b1;
				end
				else if (yposoff1 == 2'b10) begin
				  p2y <= p2y  - 1'b1;
				end
			 end
			 else begin
				p2x <= 8'd75;
				p2y <= 7'd75;
			 end
			 if (board[p2x][p2y] == 1 || p2x == 17 || p2x == 108 || p2y == 10 || p2y == 149) begin
				p2Dead <= 1;
			 end
			 else begin
				board[p2x][p2y] <= 1;
			 end
			 if (p2Dead == 0) begin
				 x <= p2x;
				 y <= p2y;
				 colour <= colourSnakeB;
				 writeEn <= 1;
			 end
			 else begin
				writeEn <= 0;
			 end
			 switch <= switch + 1;
		  end
	  end
	end
	reg [3:0] scoreP1Ones, scoreP2Ones,scoreP1Tens, scoreP2Tens;
   scoreKeep p1Score(CLOCK_50, KEY[0], HEX6, HEX7, resetGame);
   scoreKeep p2Score(CLOCK_50, KEY[1], HEX4, HEX5, resetGame);
	assign LEDR[0] = writeEn;
endmodule

module scoreKeep(
  input clk,
  input givePoint,
  output [6:0] hex0,
  output [6:0] hex1,
  input resetn);
  reg [3:0] ones, tens;
  always@(posedge clk)
  begin
    if (resetn == 0) begin
      if (givePoint == 1) begin
        if (ones < 10) begin
          ones <= ones + 1;
          end
        else begin
          ones <= 0;
          tens <= tens + 1;
        end
      end
    end
    else begin
        ones <= 0;
        tens <= 0;
    end
  end
  hex_decoder hex6(ones, hex0);
  hex_decoder hex7(tens, hex1);

endmodule

module tron_datapath(
    input clk,
    input [1:0] xOffset,
    input  [1:0] yOffset,
    input resetn,
    input [7:0] initialX,
    input [6:0] initialY,
    output [7:0] coordsX,
    output [6:0] coordsY);

    reg [7:0] y_coordinate;
	  reg [7:0] x_coordinate;

    always @(posedge clk) begin
        // setup x coordinate
    if (resetn == 1) begin
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
      y_coordinate <= initialY;
      x_coordinate <= initialY;
    end
  end
  assign coordsY = y_coordinate;
  assign coordsX = x_coordinate;
endmodule

module tron_datapath_2(
    input clk,
    output [7:0] coordsX,
	  output [6:0] coordsY,
    input [1:0] xOffset,
    input  [1:0] yOffset,
	 output [2:0] colour_out,
    input resetn);

    reg [7:0] y_coordinate;
	  reg [7:0] x_coordinate;

	initial begin
		x_coordinate = 8'd100;
		y_coordinate = 7'd100;
	end

    always @(posedge clk) begin
        // setup x coordinate
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
    assign coordsY = y_coordinate;
    assign coordsX = x_coordinate;
  // assign tron colour
  assign colour_out = 3'b100;
endmodule

module tron_control(// THIS IS THE FSM AND ALSO GIVES X,Y OFFSETS
    input clk,
    input resetn,
	  input [3:0] SW,
    input go,
    output reg [1:0] xOffset,
    output reg [1:0] yOffset,
    output plot);

    reg [2:0] current_state, next_state;
    localparam  down = 2'b00,
                right      = 2'b01,
                up      = 2'b10,
                left      = 2'b11;

    // assign what the next_state is
    always@(posedge clk)
    begin: state_table
      case (current_state)
        up: begin: turn_table_1
			       case (SW[3:0])
				         4'b0001: next_state = right;
				         4'b1000: next_state = left;
				         default: next_state = up;
			       endcase
					  end
			right: begin: turn_table_2
				      case (SW[3:0])
					       4'b0010: next_state = up;
					       4'b0100: next_state = down;
					       default: next_state = right;
				      endcase
			       end
      down: begin: turn_table_3
				      case (SW[3:0])
					         4'b0001: next_state = right;
					         4'b1000: next_state = left;
					         default: next_state = down;
			        endcase
            end
      left: begin: turn_table_4
				      case (SW[3:0])
					         4'b0100: next_state = down;
					         4'b0010: next_state = up;
					         default: next_state = left;
				      endcase
            end
      default: next_state = up;
      endcase
  end

  // plot
  assign plot = 1;
  // assign offset
  always@(*)
  begin: make_output
      case(current_state)
          up: begin
				        xOffset <= 2'b00;
				        yOffset <= 2'b01;
			        end
			right: begin
				        xOffset <= 2'b01;
				        yOffset <= 2'b00;
		         end
       down: begin
                xOffset <= 2'b00;
                yOffset <= 2'b10;
		         end
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

    // next_state advancement
    always@(posedge clk)
    begin: state_FFs
        if(!resetn) // goto resting if reset
            current_state <= down;
        else
            current_state <= next_state;
    end

endmodule
