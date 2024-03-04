module BTB(input [31:0] pc,
    input reset,
    input clk,
    input [31:0] IF_ID_pc,
    input is_jal, // ID_EX
    input is_jalr, // ID_EX
    input is_branch, // ID_EX
    input bcond,
    input [31:0] ID_EX_pc, // ID_EX
    input [4:0] ID_EX_BHSR,
    input [31:0] pc_plus_imm,
    input [31:0] reg_plus_imm,
    output reg [31:0] new_pc,
    output reg [4:0] BHSR
);

    wire [24:0] tag;
    wire [4:0] BTB_idx;
    wire [24:0] write_tag;
    wire [4:0] write_idx;


    wire is_b_taken;
    wire is_taken;

    reg [5:0] i;
    reg [31:0] BTB[0:31];
    reg [31:0] tag_table[0:31];
    reg [1:0] BHT[0:31];

    assign tag = pc[31:0];
    assign BTB_idx = pc[6:2] ^ BHSR[4:0];
    assign write_tag= ID_EX_pc[31:0];
    assign write_idx= ID_EX_pc[6:2]^ID_EX_BHSR;
    assign is_b_taken = is_branch && bcond;
    assign is_taken = is_b_taken || is_jal || is_jalr; // branch   taken ?      

    always @(*) begin
        if(reset)begin //BTB initialziation
            for(i = 0; i < 32; i = i + 1)begin
                tag_table[i] = 32'bZ;
                BTB[i] = 32'b0;
                BHT[i] = 2'b00;
            end
            BHSR = 5'b0;

        end

        else begin
            if(tag == tag_table[BTB_idx] && (BTB[BTB_idx] >= 2'b10)) begin
                new_pc = BTB[BTB_idx];
            end
            else begin
                new_pc = pc+4;
            end
        end
    end

    always @(*) begin
        if(is_jal|is_branch) begin
            if((tag_table[write_idx]!=write_tag)||(BTB[write_idx]!=pc_plus_imm)) begin
                tag_table[write_idx] = write_tag;
                BTB[write_idx]=pc_plus_imm;
            end
        end
        else if(is_jalr) begin
            if((tag_table[write_idx]!=write_tag)||(BTB[write_idx]!=reg_plus_imm)) begin
                tag_table[write_idx] = write_tag;
                BTB[write_idx]=reg_plus_imm;
            end
        end
    end

    // 2-bit Saturation machine predictor (for each idx) update 
    always @(*) begin
        if(is_branch || is_jal || is_jalr) begin //  ?      branch   jal, jal        pc   BHT        
        // BHT      idx     2bit saturation machine(assume)    ? ,         ?   ?  update ?  
            if(is_taken == 1)begin
                if(BHT[BTB_idx]==2'b11)begin end
                else begin
                    BHT[BTB_idx] <= BHT[BTB_idx]+1;
                end
            end
            else if(is_taken == 0)begin
                if(BHT[BTB_idx]==2'b00)begin end
                else begin
                    BHT[BTB_idx] <= BHT[BTB_idx]-1;
                end
            end
        end
    end

    always @(*) begin // BHSR Update for Gshare 
        if(is_branch || is_jal || is_jalr) begin
            if(is_taken) begin
                BHSR = (BHSR << 1) +1; //If Recent instruction is taken 
            end
            else begin
                BHSR = BHSR << 1; // If not 
            end
        end
    end
endmodule

module FlushforMissPrediction(
    input [31:0] IF_ID_pc,
    input ID_EX_is_jal, 
    input ID_EX_is_jalr,
    input ID_EX_branch, 
    input ID_EX_bcond,
    input [31:0] ID_EX_pc,
    input [31:0] pc_plus_imm,
    input [31:0] reg_plus_imm,
    output reg is_miss_pred);

    reg pc_reg_miss = 0;
    reg pc_imm_miss = 0;

    always @(*) begin
    
        assign pc_imm_miss = (IF_ID_pc!=pc_plus_imm);
        assign pc_reg_miss = (IF_ID_pc!=reg_plus_imm);
        
        is_miss_pred = 0;
        
        if(ID_EX_is_jal && pc_imm_miss) begin
            is_miss_pred = 1;
        end
        if(ID_EX_is_jalr && pc_reg_miss) begin
            is_miss_pred = 1;
        end
        if ((ID_EX_branch&ID_EX_bcond) && pc_imm_miss) begin
            is_miss_pred = 1;
        end
        if((ID_EX_branch&!ID_EX_bcond) && (IF_ID_pc!=ID_EX_pc+4)) begin
            is_miss_pred = 1;
        end
               
    end
endmodule

