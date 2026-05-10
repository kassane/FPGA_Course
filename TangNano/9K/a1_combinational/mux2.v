`timescale 1ns/1ps
// 2:1 multiplexer — selects between a and b based on sel
module mux2 #(parameter WIDTH = 1) (
  input  [WIDTH-1:0] a,    // input when sel=0
  input  [WIDTH-1:0] b,    // input when sel=1
  input              sel,
  output [WIDTH-1:0] y
);
  assign y = sel ? b : a;
endmodule
