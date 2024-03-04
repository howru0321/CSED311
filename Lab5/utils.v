`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/16 21:44:52
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module mux2to1(

input [31:0] in1, input [31:0] in2, input signal, output [31:0] result 

    );
    
    assign result = (!signal) ? in1 : in2; 
    
endmodule

module mux4to1( // mux expansion by mux2to1

 input [31:0] in1, input [31:0] in2, input [31:0] in3, input [31:0] in4, input [1:0] signal, output [31:0] result 
);
    
  wire[31:0] t1, t2; 

  mux2to1 m1 (in1, in2, signal[0], t1);
  mux2to1 m2 (in3, in4, signal[0], t2);
  mux2to1 m3 (t1, t2, signal[1], result);


endmodule

module adder(

input[31:0] in1, input [31:0] in2, output [31:0] result

    );
    
    assign result = in1 + in2;
    
endmodule