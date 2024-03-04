`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/03/16 20:02:20
// Design Name: 
// Module Name: ControlUnit
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

module ControlUnit(
    part_of_inst,  // input
    is_jal,        // output
    is_jalr,       // output
    branch,        // output
    mem_read,      // output
    mem_to_reg,    // output
    mem_write,     // output
    alu_src,       // output
    write_enable,     // output
    pc_to_reg,     // output
    is_ecall,       // output (ecall inst)
    alu_op
    );
    
    input [6:0] part_of_inst;
   output reg is_jal;
   output reg is_jalr;
   output reg branch;
   output reg mem_read;
   output reg mem_to_reg;
   output reg mem_write;
   output reg alu_src;
   output reg write_enable;
   output reg pc_to_reg;
   output reg is_ecall;
   output reg [6:0]alu_op;
   
   
   always @(*) begin
   is_jal = 0;
   is_jalr = 0;
   branch = 0;
   mem_read = 0;
   mem_to_reg = 0;
   mem_write = 0;
   alu_src = 0;
   write_enable = 0;
   pc_to_reg = 0;
   is_ecall = 0;
   alu_op = part_of_inst[6:0];
  
   
 
   
   if(part_of_inst==`JAL) begin
      is_jal = 1;
      write_enable=1;
      pc_to_reg=1;
   end
   
   else if(part_of_inst==`JALR) begin
      write_enable = 1; 
      is_jalr = 1;
      alu_src = 1;
      pc_to_reg = 1;
   end
   
   else if(part_of_inst==`BRANCH) begin
      branch = 1;
   end
   
   else if(part_of_inst==`LOAD) begin
      write_enable = 1;
         mem_read = 1;
         mem_to_reg = 1;
         alu_src = 1;
   end
   
   else if(part_of_inst==`STORE) begin
      mem_write = 1;
             alu_src = 1;
   end
   
   else if(part_of_inst==`ARITHMETIC_IMM) begin
      write_enable = 1;
            alu_src = 1;
   end
   
   else if(part_of_inst==`ARITHMETIC) begin
      write_enable = 1;
   end
   
   else if(part_of_inst==`ECALL) begin
      is_ecall = 1;
   end
   
   end
endmodule