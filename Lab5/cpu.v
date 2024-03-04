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
  wire [1:0] forward_A;
  wire [1:0] forward_B;
  wire [31:0] forWard_B_out;
  wire [1:0]mux_rs1_dout;
  wire mux_rs2_dout;
  wire [31:0] f_rs1_dout;
  wire [31:0] f_rs2_dout;
  wire [31:0] pc_4;
  wire [31:0] write_data;
  wire [31:0] pc_imm;
  wire is_flush;
  wire predict_failed;
  wire [31:0] predict_pc;
  wire [4:0] bhsr;
  wire [31:0] pc_4_or_alu_out;
  wire [31:0] pc_4_or_rd_din;
  
  
  
  wire is_ready;
  wire is_output_valid;
  wire is_hit;
  wire is_not_cache_stall;



  
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  reg [31:0] IF_ID_pc_4;
  reg [31:0] IF_ID_pc;
  reg IF_ID_is_flush;
  reg [4:0]IF_ID_bhsr;

  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg [6:0] ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  reg ID_EX_pc_to_reg;
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_inst;
  reg [4:0] ID_EX_rd;
  reg ID_EX_is_halted;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg [31:0] ID_EX_pc_4;
  reg ID_EX_is_jal;
  reg ID_EX_is_jalr;
  reg ID_EX_branch;
  reg [31:0] ID_EX_pc;
  reg [1:0] pc_src;
  reg [4:0] ID_EX_bhsr;
  reg [31:0] correct_pc;


  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  reg EX_MEM_pc_to_reg;
  reg [31:0] EX_MEM_pc_4;
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;
  reg EX_MEM_is_halted;



  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  reg MEM_WB_pc_to_reg;      // in WB stage
  reg [31:0] MEM_WB_pc_4;
  // From others
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;
  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;



  // assign
  assign rs1_from_inst = IF_ID_inst[19:15];
  assign rs2 = IF_ID_inst[24:20];
  assign rd = MEM_WB_rd;
  assign ID_EX_is_halted_temp = is_ecall & (f_rs1_dout==10)&(rs1==17);
  assign is_halted = MEM_WB_is_halted;
  assign is_flush=predict_failed;
  
  
  assign is_not_cache_stall = !((EX_MEM_mem_read|EX_MEM_mem_write)&!(is_ready & is_output_valid & is_hit));


  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),  
    .PCWrite(!is_hazard),       // input
    .next_pc(next_pc),     // input
    .is_not_cache_stall(is_not_cache_stall),
    .current_pc(current_pc)   // output
  );
  
   adder pc_adder(
      .in1(current_pc),
      .in2(4),
      .result(pc_4)
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
      IF_ID_pc_4<=0;
      IF_ID_pc<=0;
      IF_ID_is_flush<=0;
      IF_ID_bhsr<=0;
    end
    else if((!is_hazard)&is_not_cache_stall) begin
      IF_ID_inst<=im_out;
      IF_ID_pc_4<=pc_4;
      IF_ID_pc<=current_pc;
      IF_ID_is_flush<=is_flush;
      IF_ID_bhsr<=bhsr;
    end
  end
  
  mux2to1 mux_is_call(
    .in1(IF_ID_inst[19:15]),
    .in2(5'b10001),
    .signal(is_ecall),
    .result(rs1)
  );
  
   mux2to1 mux_MEM_WB_pc_to_reg(
    .in1(rd_din),
    .in2(MEM_WB_pc_4),
    .signal(MEM_WB_pc_to_reg),
    .result(write_data)
  );

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (rs1),          // input
    .rs2 (rs2),          // input
    .rd (rd),           // input
    .rd_din (write_data),       // input
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
    if (reset|(is_hazard&is_not_cache_stall)|is_flush|IF_ID_is_flush) begin
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
      ID_EX_is_jal<=0;
      ID_EX_is_jalr<=0;
      ID_EX_branch<=0;
      ID_EX_pc_4<=0;
      ID_EX_pc_to_reg<=0;
      ID_EX_pc<=0;
      ID_EX_bhsr<=0;
    end
    else if(is_not_cache_stall)begin
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
      ID_EX_is_jal<=is_jal;
      ID_EX_is_jalr<=is_jalr;
      ID_EX_branch<=branch;
      ID_EX_pc_4<=IF_ID_pc_4;
      ID_EX_pc_to_reg<=pc_to_reg;
      ID_EX_pc<=IF_ID_pc;
      ID_EX_bhsr<= IF_ID_bhsr;
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
  
  adder pc_imm_adder(
    .in1(ID_EX_pc),
    .in2(ID_EX_imm),
    .result(pc_imm)
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
      EX_MEM_pc_4<=0;
      EX_MEM_pc_to_reg<=0;
    end
    else if(is_not_cache_stall) begin
      EX_MEM_mem_write<=ID_EX_mem_write;
      EX_MEM_mem_read<=ID_EX_mem_read;
      EX_MEM_mem_to_reg<=ID_EX_mem_to_reg;
      EX_MEM_reg_write<=ID_EX_reg_write;
      EX_MEM_alu_out<=alu_result;
      EX_MEM_dmem_data<=forWard_B_out;
      EX_MEM_rd<=ID_EX_rd;
      EX_MEM_is_halted<=ID_EX_is_halted;
      EX_MEM_pc_4<=ID_EX_pc_4;
      EX_MEM_pc_to_reg<=ID_EX_pc_to_reg;
    end
  end

  // ---------- Data Memory ----------
//  DataMemory dmem(
//    .reset (reset),      // input
//    .clk (clk),        // input
//    .addr (EX_MEM_alu_out),       // input
//    .din (EX_MEM_dmem_data),        // input
//    .mem_read (EX_MEM_mem_read),   // input
//    .mem_write (EX_MEM_mem_write),  // input
//    .dout (dm_out)        // output
//  );

  Cache cache(
    .reset (reset),      // input
    .clk (clk),        // input
    .is_input_valid(EX_MEM_mem_read|EX_MEM_mem_write),
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .is_ready(is_ready),        // output
    .is_output_valid(is_output_valid),        // output
    .is_hit(is_hit),        // output
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
      MEM_WB_pc_4<=0;
      MEM_WB_pc_to_reg<=0;
    end
    else if(is_not_cache_stall) begin
      MEM_WB_mem_to_reg<=EX_MEM_mem_to_reg;
      MEM_WB_reg_write<=EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1<=dm_out;
      MEM_WB_mem_to_reg_src_2<=EX_MEM_alu_out;
      MEM_WB_is_halted<=EX_MEM_is_halted;
      MEM_WB_rd<=EX_MEM_rd;
      MEM_WB_pc_4<=EX_MEM_pc_4;
      MEM_WB_pc_to_reg<=EX_MEM_pc_to_reg;
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
    .EX_MEM_RegWrite(EX_MEM_reg_write),
    .MEM_WB_rd(MEM_WB_rd),
    .MEM_WB_RegWrite(MEM_WB_reg_write),
    .ForwardA(forward_A),
    .ForwardB(forward_B)
  );
  
  mux2to1 mux_EX_MEM_pc_to_reg_forward(
    .in1(EX_MEM_alu_out),
    .in2(EX_MEM_pc_4),
    .signal(EX_MEM_pc_to_reg),
    .result(pc_4_or_alu_out)
  );
  
  mux2to1 mux_MEM_WB_pc_to_reg_forward(
    .in1(rd_din),
    .in2(MEM_WB_pc_4),
    .signal(MEM_WB_pc_to_reg),
    .result(pc_4_or_rd_din)
  );

   mux4to1 mux_forward_A(
    .in1(ID_EX_rs1_data),
    .in2(pc_4_or_alu_out),
    .in3(pc_4_or_rd_din),
    .in4(0),
    .signal(forward_A),
    .result(alu_in_1)
  );


   mux4to1 mux_forward_B(
    .in1(ID_EX_rs2_data),
    .in2(pc_4_or_alu_out),
    .in3(pc_4_or_rd_din),
    .in4(0),
    .signal(forward_B),
    .result(forWard_B_out)
  );

  ForwardingEcallUnit feu(
    .rs1(rs1), // is_ecall(rs1?�� x17) ?��?��?�� rs1
    .rs2(rs2),
    .fromWBrd(rd),
    .EX_MEM_rd(EX_MEM_rd),
    .EX_MEM_RegWrite(EX_MEM_reg_write),
    .is_ecall(is_ecall),
    .mux_rs1_dout(mux_rs1_dout),
    .mux_rs2_dout(mux_rs2_dout)
  );
  

  mux4to1 mux_mux_rs1_dout(
    .in1(pc_4_or_rd_din),
    .in2(rs1_dout),
    .in3(pc_4_or_alu_out),
    .in4(0),
    .signal(mux_rs1_dout),
    .result(f_rs1_dout)
  );
  

  mux2to1 mux_mux_rs2_dout(
    .in1(pc_4_or_rd_din),
    .in2(rs2_dout),
    .signal(mux_rs2_dout),
    .result(f_rs2_dout)
  );
  
    BTB btb(
    .pc(current_pc),
    .reset(reset),
    .clk(clk),
    .IF_ID_pc(IF_ID_pc),
    .is_jal(ID_EX_is_jal),
    .is_jalr(ID_EX_is_jalr),
    .is_branch(ID_EX_branch),
    .bcond(alu_bcond),
    .ID_EX_pc(ID_EX_pc),
    .ID_EX_BHSR(ID_EX_bhsr),
    .pc_plus_imm(pc_imm),
    .reg_plus_imm(alu_result),
    .new_pc(predict_pc),
    .BHSR(bhsr)
  );
    
  FlushforMissPrediction fmp(
    .IF_ID_pc(IF_ID_pc),
    .ID_EX_is_jal(ID_EX_is_jal),
    .ID_EX_is_jalr(ID_EX_is_jalr),
    .ID_EX_branch(ID_EX_branch),
    .ID_EX_bcond(alu_bcond),
    .ID_EX_pc(ID_EX_pc),
    .pc_plus_imm(pc_imm),
    .reg_plus_imm(alu_result),
    .is_miss_pred(predict_failed)
  );
  
  
  mux2to1 mux_predict_failed(
    .in1(predict_pc),
    .in2(correct_pc),
    .signal(predict_failed),
    .result(next_pc)
  );


  always @(*) begin
    if(ID_EX_is_jalr) begin
      correct_pc=alu_result;
    end
    else if((ID_EX_branch&alu_bcond)|ID_EX_is_jal) begin
      correct_pc=pc_imm;
    end
    else begin
      correct_pc=ID_EX_pc+4;
    end
  end


  
endmodule