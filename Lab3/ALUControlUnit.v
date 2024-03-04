`include "opcodes.v"
`include "COMMAND.v"

module ALUControlUnit(part_of_inst,alu_op,command);
	input [31:0] part_of_inst;
	input alu_op;
	output reg [4:0] command;

	reg [6:0] opcode;
	reg [2:0] funct3;
	reg is_sub;


	always @(*) begin
		opcode = part_of_inst[6:0];
		funct3 = part_of_inst[14:12];
		
		command=5'b11111;
		
		if(alu_op==1'b0)
		begin
			command=`ALU_ADDER;
		end
	else begin
	   if(opcode==`JAL) begin
	       command=`JAL_JAL;
	   end
	   
	   else if(opcode==`JALR) begin
	       command=`JALR_JALR;
	   end
	   
       else if(opcode==`BRANCH) begin
	       if(funct3 == `FUNCT3_BEQ) begin
	       command = `BRANCH_BEQ;
	       end
	       else if(funct3 == `FUNCT3_BNE) begin
	       command = `BRANCH_BNE;
	       end
	       else if(funct3 == `FUNCT3_BLT) begin
	       command = `BRANCH_BLT;
	       end
	       else if(funct3 == `FUNCT3_BGE) begin
	       command = `BRANCH_BGE;
	       end
	   end
	   
	   else if(opcode==`LOAD) begin
	       command=`LOAD_LW;
	   end
	   
	   else if(opcode==`STORE) begin
	       command=`STORE_SW;
	   end
	   
	   else if(opcode==`ARITHMETIC_IMM) begin
	       if(funct3 == `FUNCT3_ADD) begin
	       command = `ARITHMETIC_IMM_ADDI;
	       end
	       else if(funct3 == `FUNCT3_XOR) begin
	       command = `ARITHMETIC_IMM_XORI;
	       end
	       else if(funct3 == `FUNCT3_OR) begin
	       command = `ARITHMETIC_IMM_ORI;
	       end
	       else if(funct3 == `FUNCT3_AND) begin
	       command = `ARITHMETIC_IMM_ANDI;
	       end
	       else if(funct3 == `FUNCT3_SLL) begin
	       command = `ARITHMETIC_IMM_SLLI;
	       end
	       else if(funct3 == `FUNCT3_SRL) begin
	       command = `ARITHMETIC_IMM_SRLI;
	       end
	   end
	       
	   else if(opcode==`ARITHMETIC) begin
	       is_sub = part_of_inst[30];
	       
	       if(funct3 == `FUNCT3_ADD && is_sub == 0) begin
	       command = `ARITHMETIC_ADD;
	       end
	       else if(funct3 == `FUNCT3_SUB && is_sub == 1) begin
	       command = `ARITHMETIC_SUB;
	       end
	       else if(funct3 == `FUNCT3_SLL) begin
	       command = `ARITHMETIC_SLL;
	       end
	       else if(funct3 == `FUNCT3_XOR) begin
	       command = `ARITHMETIC_XOR;
	       end
	       else if(funct3 == `FUNCT3_SRL) begin
	       command = `ARITHMETIC_SRL;
	       end
	       else if(funct3 == `FUNCT3_OR) begin
	       command = `ARITHMETIC_OR;
	       end
	       else if(funct3 == `FUNCT3_AND) begin
	       command = `ARITHMETIC_AND;
	       end
	   end
		
		else if(opcode==`ECALL) begin
		command = `ECALL_ECALL;
		end
	end
	end
endmodule