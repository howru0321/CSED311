`define NONE 2'b00
`define MEM 2'b01
`define WB 2'b10

module ForwardingUnit (input [4:0] ID_EX_rs1,
                        input [4:0] ID_EX_rs2,
                        input [4:0] EX_MEM_rd,
                        input [4:0] MEM_WB_rd,
                        input EX_MEM_RegWrite,
                        input MEM_WB_RegWrite,
                        output reg [1:0] ForwardA,// Signal of 3in1 Forward MUX 
                        output reg [1:0] ForwardB);
    always @(*) begin

        if((EX_MEM_rd!=0) && (ID_EX_rs1==EX_MEM_rd) && EX_MEM_RegWrite) begin
            ForwardA=`MEM;
        end
        else if((MEM_WB_rd!=0) &&(ID_EX_rs1==MEM_WB_rd) && MEM_WB_RegWrite) begin
            ForwardA=`WB;
        end
        else begin
            ForwardA=`NONE;
        end


        if((EX_MEM_rd!=0) && (ID_EX_rs2==EX_MEM_rd) && EX_MEM_RegWrite) begin
            ForwardB=`MEM;
        end
        else if((MEM_WB_rd!=0) &&(ID_EX_rs2==MEM_WB_rd) && MEM_WB_RegWrite) begin
            ForwardB=`WB;
        end
        else begin
            ForwardB=`NONE;
        end
  

    end

endmodule

// for forwarding data from MEM/WB to ID stage
module ForwardingEcallUnit (input [4:0] rs1,
                            input [4:0] rs2,
                            input [4:0] fromWBrd, // From WB stage
                            input [4:0] EX_MEM_rd,
                            input EX_MEM_RegWrite,
                            input MEM_WB_RegWrite,
                            input is_ecall,
                            output reg [1:0] mux_rs1_dout, //signal for rs1 
                            output reg mux_rs2_dout);
                            
                           
    always @(*) begin
    
       if((EX_MEM_rd==17) && is_ecall && EX_MEM_RegWrite) begin //forwarding for ecall 
            mux_rs1_dout=2'b10; 
        end
        else begin
            mux_rs1_dout=2'b01;
        end
        
        begin
            mux_rs2_dout=1;
        end
    end
endmodule
