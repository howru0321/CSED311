// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
wire is_halted;

wire [31:0] next_pc;
wire [31:0] current_pc;

wire [31:0] tempPc1;
wire [31:0] tempPc2;
wire [31:0] tempPc;

wire [31:0] dout;

wire [31:0] rf17;
wire [31:0] rs1_dout;
wire [31:0] rs2_dout;
wire [31:0] writeData;
wire [31:0] memOrALU;

wire[31:0] mem_dout;

wire [31:0] imm;

wire[31:0] alu_in_2;
wire [4:0] alu_op;
wire alu_bcond;
wire [31:0]alu_result;

//for alu
  
//constant for pc_plus_4


wire wr_en;
wire is_jal;
wire is_jalr;
wire branch;
wire mem_read;
wire mem_to_reg;
wire mem_write;
wire alu_src;
wire write_enable;
wire pc_to_reg;
wire is_ecall;
wire pc_src_1;

  /***** Register declarations *****/


assign pc_src_1 = (branch&alu_bcond) | is_jal;

assign is_halted = is_ecall & (rf17==10);


  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),
    .clk(clk), 
    .next_pc(next_pc),
    .current_pc(current_pc) 
  );
  
  adder pc_plus_4(
    .in1(current_pc),
    .in2(4),
    .result(tempPc1) 
  );

adder pc_plus_Imm(
.in1(current_pc),
.in2(imm),
.result(tempPc2)
);

  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset), 
    .clk(clk), 
    .addr(current_pc), 
    .dout(dout)  
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),
    .clk (clk), 
    .rs1 (dout[19:15]),  
    .rs2 (dout[24:20]), 
    .rd (dout[11:7]),
    .rd_din (writeData), 
    .write_enable (write_enable),
    .rs1_dout (rs1_dout),
    .rs2_dout (rs2_dout),
    .rf17 (rf17)
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .reset(reset),
    .opcode(dout[6:0]),
    .rf17(rf17),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .branch(branch),
    .mem_read(mem_read),
    .mem_to_reg(mem_to_reg),
    .mem_write(mem_write),
    .alu_src(alu_src),
    .write_enable(write_enable),
    .pc_to_reg(pc_to_reg),
    .is_ecall(is_ecall)
  );


  mux data_to_write_mux(
  .in1(memOrALU),
  .in2(tempPc1),
  .signal(pc_to_reg),
  .result(writeData)
);

  mux mem_read_data_mux(
  .in1(alu_result),
  .in2(mem_dout),
  .signal(mem_to_reg),
  .result(memOrALU)
);

  mux from_pc_src1(
  .in1(tempPc1),
  .in2(tempPc2),
  .signal(pc_src_1),
  .result(tempPc)
);

  mux from_pc_src2(
  .in1(tempPc),
  .in2(alu_result),
  .signal(is_jalr),
  .result(next_pc)
);

  mux rs2_orI(
  .in1(rs2_dout),
  .in2(imm),
  .signal(alu_src),
  .result(alu_in_2)
);


  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(dout),
    .imm_gen_out(imm)
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(dout),
    .alu_op(alu_op)
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(alu_op),
    .alu_in_1(rs1_dout),  
    .alu_in_2(alu_in_2),
    .alu_result(alu_result),
    .alu_bcond(alu_bcond)
  );

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),
    .clk (clk),
    .addr (alu_result),
    .din (rs2_dout),
    .mem_read (mem_read),
    .mem_write (mem_write),
    .dout (mem_dout)
  );
endmodule
