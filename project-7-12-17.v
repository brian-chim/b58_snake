// BASED UPON STARTER CODE CREATED BY SOMebody onCE TOLD ME
// UPDATED 07/05/2017
// Part 2 skeleton

module game
    (
        CLOCK_50,                        //    On Board 50 MHz
        // Your inputs and outputs here
        KEY,
        SW,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                           //    VGA Clock
        VGA_HS,                            //    VGA H_SYNC
        VGA_VS,                            //    VGA V_SYNC
        VGA_BLANK_N,                        //    VGA BLANK
        VGA_SYNC_N,                        //    VGA SYNC
        VGA_R,                           //    VGA Red[9:0]
        VGA_G,                             //    VGA Green[9:0]
        VGA_B                           //    VGA Blue[9:0]
    );

    input            CLOCK_50;                //    50 MHz
    input   [17:0]   SW;
    input   [3:0]   KEY;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output            VGA_CLK;                   //    VGA Clock
    output            VGA_HS;                    //    VGA H_SYNC
    output            VGA_VS;                    //    VGA V_SYNC
    output            VGA_BLANK_N;                //    VGA BLANK
    output            VGA_SYNC_N;                //    VGA SYNC
    output    [9:0]    VGA_R;                   //    VGA Red[9:0]
    output    [9:0]    VGA_G;                     //    VGA Green[9:0]
    output    [9:0]    VGA_B;                   //    VGA Blue[9:0]

   wire resetn;
   assign resetn = KEY[0];

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
   wire [2:0] colourSnakeA, colourSnakeB;
	 assign colourSnakeA = 3'b001;
   assign colourSnakeB = 3'b100;
   wire [7:0] x;
   wire [6:0] y;
   wire writeEn;
   wire clk_out;
   reg coord [7:0][0:6];
   rate_divider one_sec(SW[17], CLOCK_50, clk_out);


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
        defparam VGA.BACKGROUND_IMAGE = "black.mif";

    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.
  // Instansiate datapathxin
      wire [1:0] xposoff, yposoff;
    tron_datapath d0(.clk(clk_out),
                .coordsX(x),
                .coordsY(y),
                .xOffset(xposoff),
                .yOffset(yposoff),
                .resetn(SW[9]);
    // Instansiate FSM control
    tron_control c0(.clk(CLOCK_50),
					.KEY(KEY[3:0]),
               .go(!SW[8]),
               .resetn(SW[9]),
               .coord(coord[x][y]),
               .xOffset(xposoff),
               .yOffset(yposoff),
               .plot(writeEn)
					);
    coord[x][y] <= 1'b1;

endmodule

module tron_datapath(
	input clk,
   output [7:0] coordsX,
	output [6:0] coordsY,
   input [1:0] xOffset,
   input  [1:0] yOffset,
   input resetn;
    );
    reg [7:0] y_coordinate;
	 reg [7:0] x_coordinate;

	 initial begin
		x_coordinate <= coordsX + 8'd25;
		y_coordinate <= coordsY + 7'd25;
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


    // set color
endmodule

module tron_control(             // THIS IS THE FSM AND ALSO GIVES X,Y OFFSETS
    input clk,
    input resetn,
	 input [3:0] KEY,
    input go,
    input resetn,
    output reg [1:0] xOffset,
    output reg [1:0] yOffset,
    output plot);

    reg [2:0] current_state, next_state;
    localparam  down = 3'b000,
                right      = 3'b001,
                up      = 3'b010,
                left      = 3'b011;
                dead    = 3'b100;

    always@(posedge clk)
    begin: state_table
        case (current_state)
            up: if(KEY[3])
                  next_state = left;
                else if(KEY[0])
                  next_state = right;
                else
                  next_state = up;
				    right: if(KEY[2])
							        next_state = up;
                   else if(KEY[1])
                      next_state = down;
                   else
                      next_state = right;
            down: if(KEY[3])
                    next_state = left;
                  else if(KEY[0])
                    next_state = right;
                  else
                    next_state = down;
            left: if(KEY[2])
                    next_state = up;
                  else if(KEY[1])
                    next_state = down;
                  else
                    next_state = left;
            dead: next_state = dead;
            default: next_state = dead;
        endcase
    end

    // plot
    if(coord[x][y] == 1'b0)
      assign plot = 1;
    else
      begin
        assign plot = 0;
        next_state = dead;
      end

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
    always@(posedge clk)
    begin: state_FFs
        if(!resetn) // restart the direction if resetn is on
            current_state <= down;
        else
            current_state <= next_state;
    end
endmodule

module death(

  )
