// taken from lab 6 part 2
module RateDivider(enable_out, SW, clk, clear_b);
	input clear_b, clk;
	input [2:0] SW;
	output enable_out;
	reg [27:0] register;
	wire enable = SW[2];
	always @ (posedge clk)
   begin
		if(enable)
			begin
				if (clear_b == 1'b1)
					begin
						if(register == 0)
							begin
								case(SW[1:0])
								2'b00:  register <= 28'b0000000000000000000000000001;    // 50 MHz
								2'b01:  register <= 28'b0010111110101111000010000000;     // 1 Hz
								2'b10:  register <= 28'b0101111101011110000100000000;    // 0.5 Hz
								2'b11:  register <= 28'b1011111010111100001000000000;    // 0.25 Hz
								endcase
							end
						else
							register <= register - 1'b1;
					 end
				else
					register <= 0;     // because resetting would mean you want to restart counter
			end
	end
	assign enable_out = (register == 28'b0000000000000000000000000000) ? 1 : 0; 
endmodule
 
module DisplayCounter(q, enable, clk, clear_b);
    input enable;
    input clear_b, clk;
    output q;
    reg [3:0] q;
    always @(posedge clk)
    begin
        if (clear_b == 1'b0)
            q <= 0;
        else if (enable == 1'b1)
            q <= q + 1'b1;
    end
endmodule

 
module lab4(HEX0, SW, CLOCK_50);
    input [3:0] SW;
    input CLOCK_50;
    output [6:0] HEX0;
    wire enable;
    wire [3:0] display_num;
    hex_display number(.HEX(HEX0), .SW(display_num[3:0]));
    RateDivider myDivider(.enable_out(enable), .SW(SW[2:0]), .clk(CLOCK_50), .clear_b(SW[3]));
    DisplayCounter myDisp(.q(display_num[3:0]), .enable(enable), .clk(CLOCK_50), .clear_b(SW[3]));
endmodule


module seg0Display(seg0out, c3, c2, c1, c0);
	input c3;
   input c2;
   input c1;
   input c0;
   output seg0out;
   assign seg0out = (~c3 & ~c2& ~c1 & c0) | (~c3 & c2 & ~c1 & ~c0) | (c3 & c2 & ~c1 & c0) | (c3 & ~c2 & c1 & c0);
endmodule
 
module seg1Display(seg1out, c3, c2, c1, c0);
   input c3;
   input c2;
	input c1;
	input c0;
	output seg1out;
	assign seg1out = (c2 & c1 & ~c0) | (c3 & c1 & c0) | (c3 & c2 & ~c0) | (~c3 & c2 & ~c1 & c0);
endmodule
 
module seg2Display(seg2out, c3, c2, c1, c0);
	input c3;
	input c2;
	input c1;
	input c0;
	output seg2out;
	assign seg2out = (c3 & c2 & c1) | (c3 & c2 & ~c0) | (~c3 & ~c2 & c1 & ~c0);
endmodule
 
module seg3Display(seg3out, c3, c2, c1, c0);
	input c3;
	input c2;
	input c1;
	input c0;
	output seg3out;
	assign seg3out = (c2 & c1 & c0) | (~c3 & ~c2 & ~c1 & c0) | (~c3 & c2 & ~c1 & ~c0) | (c3 & ~c2 & c1 & ~c0);
endmodule
 
module seg4Display(seg4out, c3, c2, c1, c0);
	input c3;
	input c2;
	input c1;
	input c0;
	output seg4out;
	assign seg4out = (~c3 & c0) | (~c3 & c2 & ~c1) | (~c2 & ~c1 & c0);
endmodule
 
module seg5Display(seg5out, c3, c2, c1, c0);
	input c3;
	input c2;
	input c1;
	input c0;
	output seg5out;
	assign seg5out = (~c3 & ~c2 & c0) | (~c3 & ~c2 & c1) | (~c3 & c1 & c0) | (c3 & c2 & ~c1 & c0);
endmodule
 
module seg6Display(seg6out, c3, c2, c1, c0);
	input c3;
	input c2;
	input c1;
	input c0;
	output seg6out;
	assign seg6out = (~c3 & ~c2 & ~c1) | (~c3 & c2 & c1 & c0) | (c3 & c2 & ~c1 & ~c0);
endmodule
 
module hex_display(HEX, SW);
	input [3:0] SW;
	output [6:0] HEX;
	seg0Display seg0(.seg0out(HEX[0]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
	seg1Display seg1(.seg1out(HEX[1]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
	seg2Display seg2(.seg2out(HEX[2]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
	seg3Display seg3(.seg3out(HEX[3]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
	seg4Display seg4(.seg4out(HEX[4]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
	seg5Display seg5(.seg5out(HEX[5]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
	seg6Display seg6(.seg6out(HEX[6]),.c3(SW[3]),.c2(SW[2]),.c1(SW[1]),.c0(SW[0]));
endmodule
