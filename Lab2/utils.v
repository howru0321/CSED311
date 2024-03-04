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

module adder(

input[31:0] in1, input [31:0] in2, output [31:0] result

    );
    
    assign result = in1 + in2;
    
endmodule

module mux(

input [31:0] in1, input [31:0] in2, input signal, output [31:0] result 

    );
    
    assign result = (!signal) ? in1 : in2; 
    
endmodule