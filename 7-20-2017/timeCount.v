module timeCount (SW ,CLOCK_50, HEX0, HEX1, HEX2, HEX3);
	input [0:0] SW;
	input CLOCK_50;
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	wire [0:0]clk_out;
	reg [3:0] counter0, counter1, counter2, counter3;
	rate_divider_slow myDivider (SW, CLOCK_50, clk_out);

	initial begin
		counter0 = 0;
		counter1 = 0;
		counter2 = 0;
		counter3 = 0;
	end

	always @(posedge clk_out) begin
		if (counter0 < 4'b1001)begin
			counter0 <= counter0 + 1;
		end
		else begin
			counter0 <= 0;
			counter1 <= counter1 + 1;
		end
		if (counter1 == 4'b1001) begin
			counter1 <= 0;
			counter2 <= counter2 + 1;
		end
		if (counter2 == 4'b1001) begin
			counter2 <= 0;
			counter3 <= counter3 + 1;
		end
	end
	hex_decoder myHEX0(counter0, HEX0);
	hex_decoder myHEX1(counter1, HEX1);
	hex_decoder myHEX2(counter2, HEX2);
	hex_decoder myHEX3(counter3, HEX3);
endmodule
