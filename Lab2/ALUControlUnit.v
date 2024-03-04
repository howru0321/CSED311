`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/16 20:03:03
// Design Name: 
// Module Name: ALUControlUnit
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
`include "opcodes.v"
`include "COMMAND.v"

module ALUControlUnit(
    part_of_inst,  // input
    alu_op         // output
    );
    
    input [31:0] part_of_inst;
	output reg [4:0] alu_op;
    
    reg [6:0] opcode;
	reg [2:0] funct3;
	reg is_sub;
	
	always @(*) begin
	   opcode = part_of_inst[6:0];
       funct3 = part_of_inst[14:12];
       
       alu_op=5'b11111;
	
	   if(opcode==`JAL) begin
	       alu_op=`JAL_JAL;
	   end
	   
	   else if(opcode==`JALR) begin
	       alu_op=`JALR_JALR;
	   end
	   
       else if(opcode==`BRANCH) begin
	       if(funct3 == `FUNCT3_BEQ) begin
	       alu_op = `BRANCH_BEQ;
	       end
	       else if(funct3 == `FUNCT3_BNE) begin
	       alu_op = `BRANCH_BNE;
	       end
	       else if(funct3 == `FUNCT3_BLT) begin
	       alu_op = `BRANCH_BLT;
	       end
	       else if(funct3 == `FUNCT3_BGE) begin
	       alu_op = `BRANCH_BGE;
	       end
	   end
	   
	   else if(opcode==`LOAD) begin
	       alu_op=`LOAD_LW;
	   end
	   
	   else if(opcode==`STORE) begin
	       alu_op=`STORE_SW;
	   end
	   
	   else if(opcode==`ARITHMETIC_IMM) begin
	       if(funct3 == `FUNCT3_ADD) begin
	       alu_op = `ARITHMETIC_IMM_ADDI;
	       end
	       else if(funct3 == `FUNCT3_XOR) begin
	       alu_op = `ARITHMETIC_IMM_XORI;
	       end
	       else if(funct3 == `FUNCT3_OR) begin
	       alu_op = `ARITHMETIC_IMM_ORI;
	       end
	       else if(funct3 == `FUNCT3_AND) begin
	       alu_op = `ARITHMETIC_IMM_ANDI;
	       end
	       else if(funct3 == `FUNCT3_SLL) begin
	       alu_op = `ARITHMETIC_IMM_SLLI;
	       end
	       else if(funct3 == `FUNCT3_SRL) begin
	       alu_op = `ARITHMETIC_IMM_SRLI;
	       end
	   end
	       
	   else if(opcode==`ARITHMETIC) begin
	       is_sub = part_of_inst[30];
	       
	       if(funct3 == `FUNCT3_ADD && is_sub == 0) begin
	       alu_op = `ARITHMETIC_ADD;
	       end
	       else if(funct3 == `FUNCT3_SUB && is_sub == 1) begin
	       alu_op = `ARITHMETIC_SUB;
	       end
	       else if(funct3 == `FUNCT3_SLL) begin
	       alu_op = `ARITHMETIC_SLL;
	       end
	       else if(funct3 == `FUNCT3_XOR) begin
	       alu_op = `ARITHMETIC_XOR;
	       end
	       else if(funct3 == `FUNCT3_SRL) begin
	       alu_op = `ARITHMETIC_SRL;
	       end
	       else if(funct3 == `FUNCT3_OR) begin
	       alu_op = `ARITHMETIC_OR;
	       end
	       else if(funct3 == `FUNCT3_AND) begin
	       alu_op = `ARITHMETIC_AND;
	       end
	   end
		
		else if(opcode==`ECALL) begin
		alu_op = `ECALL_ECALL;
		end
		
	end
    
endmodule
