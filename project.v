module game(SW, KEY, CLOCK_50, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0) // need to add in all VGA stuff
  input [3:2] KEY;
  input CLOCK_50;
  input [17:0] SW;
  output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
  wire [6:0] hex7Seg, hex6Seg, hex5Seg, hex4Seg, hex3Seg, hex2Seg, hex1Seg, hex0Seg;
  // Let Sw[17] be the switch to control game select
  // output reg stuff for the always statement
  always(*)
  begin
    if(SW[17] == 1)
      // call Tron
    else
      // call Snake
  end
  assign HEX7 = hex7Seg;
  assign HEX6 = hex6Seg;
  assign HEX5 = hex5Seg;
  assign HEX4 = hex4Seg;
  assign HEX3 = hex3Seg;
  assign HEX2 = hex2Seg;
  assign HEX1 = hex1Seg;
  assign HEX0 = hex0seg;
endmodule


module snake(SW, KEY, CLOCK_50, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0)
  input [3:2] KEY;
  input CLOCK_50;
  input [17:0] SW;
  output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
endmodule

module tron(SW, KEY, CLOCK_50, HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0)
  input [3:2] KEY;
  input CLOCK_50;
  input [17:0] SW;
  output [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
endmodule
