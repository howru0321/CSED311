`include "opcodes.v"


`define IF_1 3'b000
`define IF_2 3'b001
`define ID 3'b010
`define EX_1 3'b011
`define EX_2 3'b100
`define MEM 3'b101
`define WB 3'b110

`define ALU_ADDER 1'b0
`define ALU_ALU 1'b1

`define MUX_A_PC    1'b0
`define MUX_A_REG   1'b1

`define MUX_B_REG 2'b00
`define MUX_B_4 2'b01
`define MUX_B_IMMGEN 2'b10

`define MUX_ALU_ALU 1'b0
`define MUX_ALU_ALUOUT 1'b1



module ControlUnit(
	input clk,
	input reset,
	input [6:0] part_of_inst,
	input alu_bcond,
    output reg pc_write_not_cond,
    output reg pc_write,
    output reg IorD,
    output reg mem_read,
    output reg mem_to_reg,
   output reg mem_write,
    output reg ir_write,
    output reg reg_write,
    output reg pc_source,
    output reg ALU_op,
    output reg [1:0]ALU_SrcB,
    output reg ALU_SrcA,
    output reg is_ecall
	 );
	


reg [2:0]current_state;
reg [2:0]next_state;

reg is_rtype;
reg is_itype;
reg is_load;
reg is_store;
reg is_jal;
reg is_jalr;
reg is_branch;


always@(*)begin
    is_rtype=0;
	is_itype=0;
	is_load=0;
	is_store=0;
	is_jal=0;
	is_jalr=0;
	is_branch=0;
	is_ecall=0;
	
	if(part_of_inst==`JAL) begin
        is_jal = 1;
    end
   
    else if(part_of_inst==`JALR) begin
        is_jalr = 1;
    end
   
    else if(part_of_inst==`BRANCH) begin
        is_branch = 1;
    end
   
    else if(part_of_inst==`LOAD) begin
		is_itype=1;
		is_load=1;
    end
   
   else if(part_of_inst==`STORE) begin
		is_itype=1;
		is_store=1;
   end
   
   else if(part_of_inst==`ARITHMETIC_IMM) begin
        is_itype=1;
   end
   
   else if(part_of_inst==`ARITHMETIC) begin
        is_rtype=1;
   end
   
   else if(part_of_inst==`ECALL) begin
        is_ecall = 1;
   end
	
end

always @(*)begin
mem_read=0;
ir_write=0;
mem_write=0;
mem_to_reg=0;
reg_write=0;
pc_source=0;
pc_write=0;
pc_write_not_cond=0;

    if(current_state==`IF_1) begin
        	mem_read=1;
			IorD=0;
			ir_write=1;
    end
    
    else if(current_state==`IF_2) begin
			if(is_ecall)begin
				ALU_SrcA=`MUX_A_PC;
				ALU_SrcB=`MUX_B_4;
				ALU_op=`ALU_ADDER;
				pc_source=`MUX_ALU_ALU;
				pc_write=1;
			end
			mem_read=1;
			IorD=0;
			ir_write=1;
    end
    
    else if(current_state==`ID) begin
            ALU_SrcA=`MUX_A_PC;
			ALU_SrcB=`MUX_B_4;
			ALU_op=`ALU_ADDER;
    end
    
    else if(current_state==`EX_1) begin
			if(is_itype) begin
				ALU_SrcA = `MUX_A_REG;
				ALU_SrcB = `MUX_B_IMMGEN;
				ALU_op = `ALU_ALU;
			end
			
			else if (is_rtype) begin
				ALU_SrcA = `MUX_A_REG;
				ALU_SrcB = `MUX_B_REG;
				ALU_op = `ALU_ALU;
			end
			
			else if(is_branch) begin
				ALU_SrcA = `MUX_A_REG;
				ALU_SrcB = `MUX_B_REG;
				ALU_op = `ALU_ALU;
				pc_write_not_cond = 1;
				pc_source = `MUX_ALU_ALUOUT;
			end
			
			else if(is_load | is_store) begin
				ALU_SrcA = `MUX_A_REG;
				ALU_SrcB = `MUX_B_IMMGEN;
				ALU_op = `ALU_ADDER;
			end
    end
    
    else if(current_state==`EX_2) begin
			if(is_branch) begin
				ALU_SrcA = `MUX_A_PC;
				ALU_SrcB = `MUX_B_IMMGEN;
				ALU_op = `ALU_ADDER;
				pc_write = 1;
				pc_source = `MUX_ALU_ALU;
			end
    end
    
    else if(current_state==`MEM) begin
			if(is_load)begin
				mem_read = 1;
				IorD = 1;
			end
			else if(is_store)begin
				mem_write = 1;
				IorD = 1;
				ALU_SrcA=`MUX_A_PC;
				ALU_SrcB=`MUX_B_4;
				ALU_op=`ALU_ADDER;
				pc_write=1;
				pc_source=`MUX_ALU_ALU;
			end
    end
    
    else if(current_state==`WB) begin
			reg_write = 1;
			mem_to_reg=0;
			if(is_rtype | is_itype) begin
				if(is_load)begin 
					mem_to_reg = 1;
					IorD = 0;
				end
				ALU_SrcA=`MUX_A_PC;
				ALU_SrcB=`MUX_B_4;
				ALU_op=`ALU_ADDER;
				pc_source=`MUX_ALU_ALU;
				pc_write=1;
			end
			else if(is_jal) begin
				ALU_SrcA = `MUX_A_PC;
				ALU_SrcB = `MUX_B_IMMGEN;
				ALU_op = `ALU_ADDER;
				pc_source = `MUX_ALU_ALU;
				pc_write = 1;
			end
			else if(is_jalr) begin
				ALU_SrcA = `MUX_A_REG;
				ALU_SrcB = `MUX_B_IMMGEN;
				ALU_op = `ALU_ADDER;
				pc_source = `MUX_ALU_ALU;
				pc_write = 1;
			end
    end
end




always @(*) begin

    if(current_state==`IF_1) begin
    	next_state = `IF_2;
    end
    
    else if(current_state==`IF_2) begin
		    if(is_ecall)begin
		        next_state=`IF_1;
		    end
		    else if(is_jal) begin
		        next_state=`EX_1;
		    end
		    else begin
		        next_state=`ID;
		    end
    end
    
    if(current_state==`ID) begin
    	next_state = `EX_1;
    end
    
    if(current_state==`EX_1) begin
			if(is_branch) begin
				if(alu_bcond) begin
				    next_state = `EX_2;
				end
				else begin
				    next_state = `IF_1;
				end
			end
			else begin
			    if(is_store|is_load) begin
			        next_state = `MEM;
			    end
			    else if(is_rtype | is_itype | is_jal | is_jalr) begin
			        next_state = `WB;
			    end
			    else begin
			        next_state = `IF_1;
			    end
			end
    end
    
    if(current_state==`EX_2) begin
    	next_state = `IF_1;
    end
    
    if(current_state==`MEM) begin
			if(is_load) begin
			    next_state = `WB;
			end
			else begin
			    next_state = `IF_1;
			end
    end
    
    if(current_state==`WB) begin
    	next_state = `IF_1;
    end
	end
	
always @(posedge clk)begin
	if(reset)begin
		current_state <= `IF_1;
	end
	else begin
		current_state <= next_state;
	end
end
endmodule