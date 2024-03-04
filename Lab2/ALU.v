`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/16 16:30:07
// Design Name: 
// Module Name: ALU
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
`include "COMMAND.v"

module ALU(
    alu_op,      // input
    alu_in_1,    // input  
    alu_in_2,    // input
    alu_result,  // output
    alu_bcond     // output
    );
    
    input [4:0]alu_op;
	input [31:0] alu_in_1;
	input [31:0] alu_in_2;
	output reg [31:0] alu_result;
	output reg alu_bcond;
	
	always @(*) begin
	   alu_result = 0;
	   alu_bcond = 0;
	   
	   if(alu_op==`JALR_JALR||alu_op==`LOAD_LW||alu_op==`STORE_SW||alu_op==`ARITHMETIC_IMM_ADDI||alu_op==`ARITHMETIC_ADD) begin
	       alu_result = alu_in_1+alu_in_2;
	   end
	   
	   else if(alu_op==`BRANCH_BEQ) begin
	       if(alu_in_1==alu_in_2) begin
	           alu_bcond = 1;
	       end
	       else begin
	           alu_bcond = 0;
	       end
	   end
	   
	   else if(alu_op==`BRANCH_BNE) begin
	       if(alu_in_1!=alu_in_2) begin
	           alu_bcond = 1;
	       end
	       else begin
	           alu_bcond = 0;
	       end
	   end
	   
	   else if(alu_op==`BRANCH_BLT) begin
	       if(alu_in_1<alu_in_2) begin
	           alu_bcond = 1;
	       end
	       else begin
	           alu_bcond = 0;
	       end
	   end
	   
	   else if(alu_op==`BRANCH_BGE) begin
	       if(alu_in_1>=alu_in_2) begin
	           alu_bcond = 1;
	       end
	       else begin
	           alu_bcond = 0;
	       end
	   end
	   
	   else if(alu_op==`ARITHMETIC_IMM_XORI||alu_op==`ARITHMETIC_XOR) begin
	       alu_result = alu_in_1^alu_in_2;
	   end
	   
	   else if(alu_op==`ARITHMETIC_IMM_ORI||alu_op==`ARITHMETIC_OR) begin
	       alu_result = alu_in_1|alu_in_2;
	   end
	   
	   else if(alu_op==`ARITHMETIC_IMM_ANDI||alu_op==`ARITHMETIC_AND) begin
	       alu_result = alu_in_1&alu_in_2;
	   end
	   
	   else if(alu_op==`ARITHMETIC_IMM_SLLI||alu_op==`ARITHMETIC_SLL) begin
	       alu_result = alu_in_1<<alu_in_2;
	   end
	   
	   else if(alu_op==`ARITHMETIC_IMM_SRLI||alu_op==`ARITHMETIC_SRL) begin
	       alu_result = alu_in_1>>alu_in_2;
	   end
	   
	   else if(alu_op==`ARITHMETIC_SUB) begin
	       alu_result = alu_in_1-alu_in_2;
	   end
	end
    
endmodule
