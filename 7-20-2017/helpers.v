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


module rate_divider_fast(enable, clkin, clkout);
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
			if (count < 10000000)
				count <= count + 1;
			else begin
				count <= 0;
				clkout <= ~clkout;
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
			if (count < 100000000)
				count <= count + 1;
			else begin
				count <= 0;
				clkout <= ~clkout;
			end
		end
	end
endmodule
