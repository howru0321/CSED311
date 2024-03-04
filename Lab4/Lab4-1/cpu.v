// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module CPU(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted); // Whehther to finish simulation
  /***** Wire declarations *****/
  wire [31:0] next_pc;
  wire [31:0] current_pc;

  wire [31:0] im_out;


  wire mem_read;
  wire mem_to_reg;
  wire mem_write;
  wire alu_src;
  wire reg_write;
  wire is_ecall;
  

  wire is_jal;
  wire is_jalr;
  wire branch;
  wire pc_to_reg;
  
  

  wire [31:0] imm_gen_out;


  wire [31:0] rs1_dout;
  wire [31:0] rs2_dout;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [31:0] rd_din;

  wire [6:0] alu_op;
  wire [4:0] func_code;
  wire [31:0] alu_in_1;
  wire [31:0] alu_in_2;
  wire [31:0] alu_result;
  wire alu_bcond;

  wire [31:0] dm_out;

  wire ID_EX_is_halted_temp;

  wire is_hazard;



  // for Forwarding
  wire [1:0] forward_A;
  wire [1:0] forward_B;
  wire [31:0] forWard_B_out;

  wire [1:0]mux_rs1_dout;
  wire mux_rs2_dout;

  wire [31:0] f_rs1_dout;
  wire [31:0] f_rs2_dout;

  
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [6:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_inst;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_halted;

  // For Forwarding
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  // reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg EX_MEM_is_halted;



  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;

  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;



  // assign
  assign rs2 = IF_ID_inst[24:20];
  assign rd = MEM_WB_rd;
  


  assign ID_EX_is_halted_temp = is_ecall & (f_rs1_dout==10)&(rs1==17);
  assign is_halted = MEM_WB_is_halted;


  mux2to1 mux_is_call(
    .in1(IF_ID_inst[19:15]),
    .in2(5'b10001),
    .signal(is_ecall),
    .result(rs1)
  );

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),  
    .PCWrite(!is_hazard),       // input
    .next_pc(current_pc+4),     // input
    .current_pc(current_pc)   // output
  );
  
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(im_out)     // output
  );

  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <=0;
    end
    else if(!is_hazard) begin
      IF_ID_inst<=im_out;
    end
  end

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout)      // output
  );


  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),
    .is_jal(is_jal),
    .is_jalr(is_jalr),
    .branch(branch),
    .mem_read(mem_read),
    .mem_to_reg(mem_to_reg),
    .mem_write(mem_write),
    .alu_src(alu_src),
    .write_enable(reg_write),
    .pc_to_reg(pc_to_reg),
    .is_ecall(is_ecall),
    .alu_op(alu_op)
  );

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .inst(IF_ID_inst),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset|is_hazard) begin
      ID_EX_alu_op<=0;         // will be used in EX stage
      ID_EX_alu_src<=0;        // will be used in EX stage
      ID_EX_mem_write<=0;      // will be used in MEM stage
      ID_EX_mem_read<=0;       // will be used in MEM stage
      ID_EX_mem_to_reg<=0;     // will be used in WB stage
      ID_EX_reg_write<=0;      // will be used in WB stage
      // From others
      ID_EX_rs1_data<=0;
      ID_EX_rs2_data<=0;
      ID_EX_imm<=0;
      ID_EX_inst<=0;
      ID_EX_rd<=0;
      ID_EX_is_halted<=0;
      ID_EX_rs1<=0;
      ID_EX_rs2<=0;
    end
    else begin
      // From the control unit
      ID_EX_alu_op<=alu_op;         // will be used in EX stage
      ID_EX_alu_src<=alu_src;        // will be used in EX stage
      ID_EX_mem_write<=mem_write;      // will be used in MEM stage
      ID_EX_mem_read<=mem_read;       // will be used in MEM stage
      ID_EX_mem_to_reg<=mem_to_reg;     // will be used in WB stage
      ID_EX_reg_write<=reg_write;      // will be used in WB stage
      // From others
      ID_EX_rs1_data<=f_rs1_dout;
      ID_EX_rs2_data<=f_rs2_dout;
      ID_EX_imm<=imm_gen_out;
      ID_EX_inst<=IF_ID_inst;
      ID_EX_rd<=IF_ID_inst[11:7];
      ID_EX_is_halted<=ID_EX_is_halted_temp;
      ID_EX_rs1<=rs1;
      ID_EX_rs2<=rs2;
    end
  end

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_inst),  // input
    .opcode(ID_EX_alu_op),
    .alu_op(func_code)         // output
  );

  // ---------- ALU ----------
  ALU alu (
    .alu_op(func_code),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)    // output
  );

  mux2to1 mux_ID_EX_alu_src(
    .in1(forWard_B_out),
    .in2(ID_EX_imm),
    .signal(ID_EX_alu_src),
    .result(alu_in_2)
  );

  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write<=0;
      EX_MEM_mem_read<=0;
      EX_MEM_mem_to_reg<=0;
      EX_MEM_reg_write<=0;

      EX_MEM_alu_out<=0;
      EX_MEM_dmem_data<=0;
      EX_MEM_rd<=0;
      EX_MEM_is_halted<=0;
    end
    else begin
      EX_MEM_mem_write<=ID_EX_mem_write;
      EX_MEM_mem_read<=ID_EX_mem_read;
      EX_MEM_mem_to_reg<=ID_EX_mem_to_reg;
      EX_MEM_reg_write<=ID_EX_reg_write;

      EX_MEM_alu_out<=alu_result;
      EX_MEM_dmem_data<=forWard_B_out;
      EX_MEM_rd<=ID_EX_rd;
      EX_MEM_is_halted<=ID_EX_is_halted;

    end
  end

  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (dm_out)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg<=0;
      MEM_WB_reg_write<=0;
      MEM_WB_mem_to_reg_src_1<=0;
      MEM_WB_mem_to_reg_src_2<=0;
      MEM_WB_is_halted<=0;
      MEM_WB_rd<=0;
    end
    else begin
      MEM_WB_mem_to_reg<=EX_MEM_mem_to_reg;
      MEM_WB_reg_write<=EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1<=dm_out;
      MEM_WB_mem_to_reg_src_2<=EX_MEM_alu_out;
      MEM_WB_is_halted<=EX_MEM_is_halted;
      MEM_WB_rd<=EX_MEM_rd;

    end
  end

    mux2to1 mux_MEM_WB_mem_to_reg(
    .in1(MEM_WB_mem_to_reg_src_2),
    .in2(MEM_WB_mem_to_reg_src_1),
    .signal(MEM_WB_mem_to_reg),
    .result(rd_din)
  );

//hazard part
  HazardDetectionUnit hdu(
    .rs1(rs1), 
    .rs2(rs2),
    .ID_EX_rd(ID_EX_rd),
    .EX_MEM_rd(EX_MEM_rd),
    .ID_EX_mem_read(ID_EX_mem_read),
    .EX_MEM_mem_read(EX_MEM_mem_read),
    .opcode(ID_EX_inst[6:0]),
    .is_ecall(is_ecall),
    .hazard(is_hazard)
  );

//Forwarding part

  ForwardingUnit fu(
    .ID_EX_rs1(ID_EX_rs1),
    .ID_EX_rs2(ID_EX_rs2),
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .EX_MEM_RegWrite(EX_MEM_reg_write),
    .MEM_WB_RegWrite(MEM_WB_reg_write),
    .ForwardA(forward_A),
    .ForwardB(forward_B)
  );


   mux4to1 mux_forward_A(
    .in1(ID_EX_rs1_data),
    .in2(EX_MEM_alu_out),
    .in3(rd_din),
    .in4(0),
    .signal(forward_A),
    .result(alu_in_1)
  );
  


   mux4to1 mux_forward_B(
    .in1(ID_EX_rs2_data),
    .in2(EX_MEM_alu_out),
    .in3(rd_din),
    .in4(0),
    .signal(forward_B),
    .result(forWard_B_out)
  );

  ForwardingEcallUnit feu(
    .rs1(rs1), 
    .rs2(rs2),
    .fromWBrd(rd),
    .EX_MEM_rd(EX_MEM_rd),
    .is_ecall(is_ecall),
    .mux_rs1_dout(mux_rs1_dout),
    .mux_rs2_dout(mux_rs2_dout)
  );

  mux4to1 mux_mux_rs1_dout(
    .in1(rd_din),
    .in2(rs1_dout),
    .in3(EX_MEM_alu_out),
    .in4(0),
    .signal(mux_rs1_dout),
    .result(f_rs1_dout)
  );
  

  mux2to1 mux_mux_rs2_dout(
    .in1(rd_din),
    .in2(rs2_dout),
    .signal(mux_rs2_dout),
    .result(f_rs2_dout)
  );


  
endmodule