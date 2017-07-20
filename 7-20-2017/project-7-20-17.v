// UPDATED 07/20/2017 @00:03 by Brian

module tron (
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
    HEX3
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
    output [6:0] HEX0, HEX1, HEX2, HEX3;
    wire resetn;
    assign resetn = KEY[0];

   // wires for x,y, colour outputs for the two trons
   wire [7:0] t1x, t2x, x;
   wire [6:0] t1y, t2y, y;
   wire [2:0] colourSnakeA, colourSnakeB, colour;
   wire [1:0] xposoff1, yposoff1, xposoff2, yposoff2;

   wire switch;
   wire writeEn;
   wire clk_out_fast;
   wire clk_out_slow;

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
        .colour(colourSnakeA),
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

    // instansiates the datapath module for second tron
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
        .plot(writeEn));

    // Instansiate FSM control module for second tron
    tron_control c2(
        .clk(CLOCK_50),
		    .SW(SW[12:9]),
        .go(!KEY[2]),
        .resetn(KEY[3]),
        .xOffset(xposoff2),
        .yOffset(yposoff2),
        .plot(writeEn));

    // instantiates the timecount module
   timeCount count(
       .SW(1'b1),
       .CLOCK_50(CLOCK_50),
       .HEX0(HEX0),
       .HEX1(HEX1),
       .HEX2(HEX2),
       .HEX3(HEX3));

   // draw both snakes
   always @posedge(CLOCK_50) begin
      if (switch == 1'b0)
        assign x = t1x;
        assign y = t1y;
        assign colour = colourSnakeA;
      else
        assign x = t2x;
        assign y = t2y;
        assign colour = colourSnakeB;
      assign switch = ~switch;

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
		y_coordinate = 7'd25;
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
