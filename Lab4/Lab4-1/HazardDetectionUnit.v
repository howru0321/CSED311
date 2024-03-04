`include "opcodes.v"

module HazardDetectionUnit (input [4:0] rs1,
                            input [4:0] rs2,
                            input [4:0] ID_EX_rd,
                            input [4:0] EX_MEM_rd,
                            input ID_EX_mem_read,
                            input EX_MEM_mem_read,
                            input [6:0] opcode,
                            input is_ecall,
                            output reg hazard);
   
    
    reg isWB;
    
    always @(*) begin
    
    hazard = 0;
    isWB = 0;
  
    
        if (opcode==`ARITHMETIC || opcode==`ARITHMETIC_IMM || opcode==`LOAD || opcode==`JAL || opcode==`JALR) begin 
            isWB = 1;
        end

        if((rs1 == ID_EX_rd || rs2 == ID_EX_rd) & ID_EX_mem_read) begin //���� ������ load, �� ������ rd�� source�� ����ϴ� ��� 
            hazard=1;  
        end

        else if (is_ecall) begin //ecall�� ���� ����ó�� 
        
            if ((ID_EX_rd==17) && isWB) begin
                hazard=1;
            end
            
            else if((EX_MEM_rd==17) && (EX_MEM_mem_read)) begin // EX_MEM �ܰ� ������ load�̸鼭 rd�� rf17�� ����ϴ� ��� hazard
                hazard=1;
            end    
        end

        else begin
        end
    end

endmodule