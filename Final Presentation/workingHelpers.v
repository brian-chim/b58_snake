module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule


module rate_divider_fast(enable, clkin, clkout, fast);
	input [0:0] enable;
	input clkin;
	input fast;
	output reg [0:0]clkout;
	reg [24:0] count;

	initial begin
		count = 0;
		clkout = 0;
	end

	always @(posedge clkin) begin
		if (enable == 1'b1) begin
			if (fast) begin
				if (count < 1500000)
					count <= count + 1;
				else begin
					count <= 0;
					clkout <= ~clkout;
				end
			end
			else begin
				if (count < 3000000)
					count <= count + 1;
				else begin
					count <= 0;
					clkout <= ~clkout;
				end
			end
		end
	end
endmodule

module rate_divider_slow(enable, clkin, clkout);
	input [0:0] enable;
	input clkin;
	output reg [0:0]clkout;
	reg [24:0] count;

	initial begin
		count = 0;
		clkout = 0;
	end

	always @(posedge clkin) begin
		if (enable == 1'b1) begin
			if (count < 24999999)
				count <= count + 1;
			else begin
				count <= 0;
				clkout <= ~clkout;
			end
		end
	end
endmodule

module timeCount (SW ,CLOCK_50, HEX0, HEX1, HEX2, HEX3, fast_slow);
	input [0:0] SW;
	input CLOCK_50;
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	output fast_slow;
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
	assign fast_slow = (counter1) % 2;
	hex_decoder myHEX0(counter0, HEX0);
	hex_decoder myHEX1(counter1, HEX1);
	hex_decoder myHEX2(counter2, HEX2);
	hex_decoder myHEX3(counter3, HEX3);
endmodule
