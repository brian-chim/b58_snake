// UPDATED 07/25/2017 16:03 by Mason

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
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX6, HEX5, HEX7;
    output [0:0] LEDR;
    wire resetn;
    assign resetn = KEY[0];

   // wires for x,y, colour outputs for the two trons
   wire [7:0] t1x, t2x;
	reg [7:0] x;
	reg [6:0] y;
	reg [2:0] colour;
   wire [6:0] t1y, t2y;
   wire [2:0] colourSnakeA, colourSnakeB;
   wire [1:0] xposoff1, yposoff1, xposoff2, yposoff2;
   reg [1:0] switch;
   wire writeEn1;
	wire writeEn2;
	reg writeEn;
   wire deader;
   wire clk_out_fast;
   wire clk_out_slow;
   reg [24:0] counter;
   reg [3:0] p1Score, p2Score;

   // create a fast counter
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

    // instansiates the datapath module for first tron
    tron_datapath_1 d1(
        .clk(clk_out_fast),
        .coordsX(t1x),
        .coordsY(t1y),
        .xOffset(xposoff1),
        .yOffset(yposoff1),
        .resetn(reposition),
        .colour_out(colourSnakeA));
	  wire reposition;
	  assign reposition = SW[16] || p1Dead || p2Dead || reset;
    // instansiates the datapath module for second tron
    tron_datapath_2 d2(
        .clk(clk_out_fast),
        .coordsX(t2x),
        .coordsY(t2y),
        .xOffset(xposoff2),
		    .yOffset(yposoff2),
        .resetn(reposition),
        .colour_out(colourSnakeB));

    // Instansiate FSM control module for first tron
    tron_control c1(
        .clk(CLOCK_50),
		    .SW(SW[12:9]),
        .go(!KEY[2]),
        .resetn(KEY[3]),
        .xOffset(xposoff1),
        .yOffset(yposoff1),
        .plot(writeEn1));

    // Instansiate FSM control module for second tron
    tron_control c2(
        .clk(CLOCK_50),
		    .SW(SW[3:0]),
        .go(!KEY[2]),
        .resetn(KEY[3]),
        .xOffset(xposoff2),
        .yOffset(yposoff2),
        .plot(writeEn2));

    // instantiates the timecount module
   timeCount count(
       .SW(SW[17]),
       .CLOCK_50(CLOCK_50),
       .HEX0(HEX0),
       .HEX1(HEX1),
       .HEX2(HEX2),
       .HEX3(HEX3));

   //sets up the boarder (git it?)
	reg reset;
	integer i,j;
	reg p1Dead, p2Dead;
   // draw both snakes
	initial begin
		p1Dead = 0;
		p2Dead = 0;
		i = 11;
		j = 18;
	end
   always @(posedge CLOCK_50) begin
		if (SW[16] || p1Dead == 1 || p2Dead == 1 || reset == 1) begin
			if(p1Dead == 1 || p2Dead == 1) begin
				p1Dead <= 0;
				p2Dead <= 0;
				reset <= 1;
			end
			writeEn <= 1;
			colour <= 3'b000;
			  if (i == 148 && j == 107) begin
					reset <= 0;
					i <= 11;
					j <= 18;
					writeEn <= 0;
			  end
			  else if (i < 148 && j == 107) begin
					i <= i + 1;
					j <= 18;
			  end
			  else if (j < 107) begin
					j <= j + 1;
			  end
			  x <= i;
			  y <= j;
		  end
		else begin
			if (switch == 2'b00) begin
				if(t1x == 8'd10 || t1x == 8'd149 || t1y == 7'd17 || t1y == 7'd108) begin
					p1Dead <= 1;
				end
			else begin
			  x <= t1x;
			  y <= t1y;
			  colour <= colourSnakeA;
			  writeEn <= writeEn1;
			  switch <= switch + 1;
			 end
			end
			else if (switch == 2'b01) begin
			 // check border death
			 if(t2x == 8'd10 || t2x == 8'd149 || t2y == 7'd17 || t2y == 7'd108) begin
				 p2Dead <= 1;
			 end
			 else begin
			  x <= t2x;
			  y <= t2y;
			  colour <= colourSnakeB;
			  writeEn <= writeEn2;
			  switch <= switch + 1;
			 end
			  end
			else
			  writeEn <= 0;
			// this if block is to reset the switch value
			if (counter < 9999998)
				counter <= counter + 1;
			else begin
				counter <= 0;
			  switch <= 0;
			  end
			end
   end
   assign LEDR[0] = p1Dead || p2Dead;
	scoreKeep player1Score(p2Dead, HEX6);
   scoreKeep player2Score(p1Dead, HEX4);
	scoreKeep player1ScoreH(KEY[2], HEX7);
   scoreKeep player2ScoreH(KEY[1], HEX5);
endmodule

module scoreKeep(
  input givePoint,
  output [6:0] hex0,
  output [6:0] hex1);
  reg [3:0] ones, tens;
  initial begin
	ones = 0;
	tens = 0;
  end
  always@(posedge givePoint)
  begin
	if (ones < 9) begin
		 ones <= ones + 1;
		 end
	  else begin
		 ones <= 0;
		 tens <= tens + 1;
	  end
	end
  hex_decoder hex6(ones, hex0);
  hex_decoder hex7(tens, hex1);

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
			x_coordinate <= 8'd25;
			y_coordinate <= 7'd100;
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
