// UPDATED 07/21/2017 2:47 by Mason
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
	  output [1:0]LEDR;
    wire resetn;
    assign resetn = KEY[0];

   // wires for x,y, colour outputs for the two trons
   reg dead;
   reg [7:0] xhold [0:1];
   reg [6:0] yhold [0:1];
   wire [7:0] t1x, t2x;
	 reg [7:0] x;
	 reg [6:0] y;
	 reg [2:0] colour;
   wire [6:0] t1y, t2y;
   wire [2:0] colourSnakeA, colourSnakeB;
   wire [1:0] xposoff1, yposoff1, xposoff2, yposoff2;

   reg [0:0] switch;
   wire writeEn1;
	wire writeEn2;
	reg writeEn;
   wire clk_out_fast;
   wire clk_out_slow;
	wire clk_out_half;

   // create a fast counter
   rate_divider_fast fast_clk(
        .enable(SW[17]),
        .clkin(CLOCK_50),
        .clkout(clk_out_fast));

   // reg  [1:0] cord [7:0][6:0]; - ignore as this was supposed to be used for collision

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

/* ignore this for now, supposed to be used for collision detection later
	always@(posedge CLOCK_50) begin
        // initializes the position that we start at in the game board
			cord[x][y] = 1;
		end
*/
    // instansiates the datapath module for first tron
    tron_datapath_1 d1(
        .clk(clk_out_fast),
        .coordsX(t1x),
        .coordsY(t1y),
        .xOffset(xposoff1),
        .yOffset(yposoff1),
        .resetn(KEY[3]),
        .colour_out(colourSnakeA));

    // instansiates the datapath modub00le for second tron
    tron_datapath_2 d2(
        .clk(clk_out_fast),
        .coordsX(t2x),
        .coordsY(t2y),
        .xOffset(xposoff2),
        .yOffset(yposoff2),
        .resetn(KEY[3]),
        .colour_out(colourSnakeB));

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
       .SW(1'b1),
       .CLOCK_50(CLOCK_50),
       .HEX0(HEX0),
       .HEX1(HEX1),
       .HEX2(HEX2),
       .HEX3(HEX3));

	 rate_divider_half half(
        .enable(SW[17]),
        .clkin(CLOCK_50),
        .clkout(clk_out_half));

   reg board[0:159][0:119];
   integer i;
   initial begin
     for (i=10; i <150; i = i + 1) begin
        board[i][17] <= 1'b1;
        board[i][108] <= 1'b1;
     end
     for (i=17; i <109; i = i + 1) begin
        board[10][i] <= 1'b1;
        board[149][i] <= 1'b1;
     end
	  x <= 1;
	  y <= 1;
   end


   // draw both snakes
   always @(posedge clk_out_half) begin

		if (switch == 1'b0) begin
			  x <= t1x;
			  y <= t1y;
			  colour <= colourSnakeA;
			  switch <= switch + 1;
        if (board[x][y] == 1'b1 && (xhold[0] != x || yhold[0] != y)) begin
          dead <= 1'b1;
          writeEn <= 0;
        end
        else begin
          xhold[0] = x;
          yhold[0] = y;
          board[x][y] <= 1'b1;
          writeEn <= 1;
        end
		end
		else if (switch == 1'b1) begin
			  x <= t2x;
			  y <= t2y;
			  colour <= colourSnakeB;
			  switch <= switch + 1;
        if (board[x][y] == 1'b1 && (xhold[1] != x || yhold[1] != y)) begin
          dead <= 1'b1;
          writeEn <= 0;
        end
        else begin
          xhold[1] = x;
          yhold[1] = y;
          board[x][y] <= 1'b1;
          writeEn <= 1;
        end
		end
	end
  reg [3:0] scoreP1Ones, scoreP2Ones,scoreP1Tens, scoreP2Tens;
  always@(KEY[0]) begin
    if (scoreP1Ones < 10) begin
      scoreP1Ones <= scoreP1Ones + 1;
    end
    else begin
      scoreP1Ones <= 0;
      scoreP1Tens <= scoreP1Tens + 1;
    end
  end

  always@(KEY[1]) begin
    if (scoreP2Ones < 10) begin
      scoreP2Ones <= scoreP2Ones + 1;
    end
    else begin
      scoreP2Ones <= 0;
      scoreP2Tens <= scoreP2Tens + 1;
    end
  end
  hex_decoder hex6(scoreP1Ones, HEX6);
  hex_decoder hex7(scoreP1Tens, HEX7);
  hex_decoder hex6(scoreP2Ones, HEX4);
  hex_decoder hex6(scoreP2Ones, HEX5);
	assign LEDR[0] = writeEn;
	assign LEDR[1] = dead;
endmodule



module tron_datapath_1(
    input clk,
    input [1:0] xOffset,
    input  [1:0] yOffset,
    input resetn,
    output [2:0] colour_out,
    output [7:0] coordsX,
    output [6:0] coordsY);

    reg [7:0] y_coordinate;
	  reg [7:0] x_coordinate;

	initial begin
		x_coordinate = 8'd25;
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
  assign colour_out = 3'b001;
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
