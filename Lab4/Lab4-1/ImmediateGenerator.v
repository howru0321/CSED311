`include "opcodes.v"
module ImmediateGenerator(
    input [31:0] inst,  // input
    output reg [31:0] imm_gen_out  // output
  );

reg [6:0] opcode;

  //according to instruction type

  always @(*) begin
     opcode = inst[6:0];
     
     if(opcode==`ARITHMETIC_IMM || opcode==`LOAD) begin // I-Type Instruction
       imm_gen_out=$signed({inst[31:20]});
     end
     
    else if(opcode==`STORE) begin // S-Type Instruction
        imm_gen_out=$signed({inst[31:25],inst[11:8],inst[7]});
    end
    
    else if(opcode==`BRANCH) begin // B-Type Instruction
        imm_gen_out=$signed({inst[31],inst[7],inst[30:25],inst[11:8],1'b0});
    end
 
    else if(opcode==`JAL) begin // U-Type Instruction
        imm_gen_out=$signed({inst[31],inst[19:12],inst[20],inst[30:21],1'b0});
    end
 
    else if(opcode==`JALR) begin // UJ-Type Instruction
        imm_gen_out=$signed(inst[31:20]);
    end

  end

endmodule