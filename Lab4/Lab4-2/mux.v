module Mux(input [31:0] input0,
            input [31:0] input1,
            input signal,
            output reg [31:0] output_mux);
    always @(*) begin
        if(signal) begin
            output_mux=input1;
        end
        else begin
            output_mux=input0;
        end
    end
endmodule

module MuxForIsEcall(input [4:0] input0,
                    input [4:0] input1,
                    input signal,
                    output reg [4:0] output_mux);
    always @(*) begin
        if(signal) begin
            output_mux=input1;
        end
        else begin
            output_mux=input0;
        end
    end
endmodule

module MuxForForward(input [31:0] input00,
                    input [31:0] input01,
                    input [31:0] input10,
                    input [1:0] signal,
                    output reg [31:0] output_mux);
    always @(*) begin
        if(signal==2'b00) begin
            output_mux=input00;
        end
        else if(signal==2'b01) begin
            output_mux=input01;
        end
        else if(signal==2'b10) begin
            output_mux=input10;
        end
    end
endmodule