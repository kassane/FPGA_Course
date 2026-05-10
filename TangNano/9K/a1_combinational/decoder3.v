`timescale 1ns/1ps
// 3-to-8 one-hot decoder: output bit [in] is set, all others clear
module decoder3 (
  input  [2:0] in,
  input        en,       // active-high enable; all zeros when en=0
  output [7:0] out
);
  assign out = en ? (8'b1 << in) : 8'b0;
endmodule
