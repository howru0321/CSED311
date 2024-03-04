module PC (input reset,
            input clk,
            input PCWrite,
            input [31:0] next_pc,
            input is_not_cache_stall,
            output [31:0] current_pc);
  
  reg [31:0] pc;

  assign current_pc = pc;
  


  always @(posedge clk) begin
    if(reset) begin
      pc <= 32'b0;
    end
    else if(PCWrite&is_not_cache_stall) begin
      pc <= next_pc;
    end
    else begin
      // pc <= pc;
    end
  end
endmodule

