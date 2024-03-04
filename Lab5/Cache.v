`include "CLOG2.v"
`include "opcodes.v"

`define Idle 2'b00
`define Compare_tag 2'b01
`define Allocate 2'b10 
`define Write_back 2'b11

module Cache #(parameter LINE_SIZE = 16, //Line size is fixed
               parameter NUM_SETS = 16,
               parameter NUM_WAYS = 1) ( // we implemented direct mapped cache (a = 1)
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output is_output_valid,
    output reg [31:0] dout, // register redefine
    output reg is_hit); // register redefine

  // Wire declarations
  wire is_data_mem_ready;  // initial file 
  
  wire [23:0] tag; // Cache tag
  wire [3:0] index; // Cache (set) index 
  wire [1:0] bo; // block offset
  
  wire [0:127] data_read;
  wire [23:0] tag_to_read;
  wire valid_read;
  wire dirty_read;

  wire [0:127] dmem_dout;
  wire dmem_output_valid;
  wire [31:0] clog2;
  
  //Reg declarations

  reg [0:127] data_write;
  reg [23:0] tag_to_write;
  reg valid_write;
  reg dirty_write;

  reg data_write_enable;
  reg tag_write_enable;

  reg [31:0] dmem_addr;
  reg [0:127] dmem_din;
  reg dmem_input_valid;
  
  reg mem_read_req;
  reg mem_write_req;
  
  reg [1:0] cur_state;
  reg [1:0] next_state;
  
  integer total_count;
  integer hit_count;
  integer miss_count;
  
  reg [31:0] hit_counter;
  reg [31:0] miss_counter; 
  
  assign is_ready = is_data_mem_ready; // initial file 

  assign tag = addr[31:8];
  assign index = addr[7:4];
  assign bo = addr[3:2];

  assign is_output_valid = (next_state ==`Idle);
  assign clog2 = `CLOG2(LINE_SIZE);

  
  always @(posedge clk) begin // set for next state
    cur_state <= (!reset) ? next_state : `Idle;
    end
  
  always @(posedge clk) begin
    if(reset) begin
      total_count <= 0;
      hit_count <= 0;
      miss_count <= 0;
    end
    else begin
      hit_count <= total_count-miss_count;
      //$display("total memory access = %d, hit = %d, miss = %d", total_count, hit_count, miss_count);
      //$display("hit rate = %f, miss rate = %f", ((real)hit_count / (hit_count+miss_count)), ((real)miss_count / (hit_count+miss_count)) );
    end
  end
  
  always @(*) begin // update data & setting next state with FSM 
  
    tag_to_write=0;
    valid_write=0;
    dirty_write=0;

    tag_write_enable=0;
    data_write_enable=0;
    
    is_hit=0; // initialize output register

    data_write = data_read;
    
    case(bo) // write per 1 word (4 Byte)
      2'b00: data_write[0:31] = din;
      2'b01: data_write[32:63] = din;
      2'b10: data_write[64:95] = din;
      2'b11: data_write[96:127] = din;
    endcase

    case(bo) // read per 1 word 
      2'b00: dout=data_read[0:31];
      2'b01: dout=data_read[32:63];
      2'b10: dout=data_read[64:95];
      2'b11: dout=data_read[96:127];
    endcase
    
     case(cur_state) // FSM Logic
     
      `Idle: begin //Idle State
        if(is_input_valid) next_state=`Compare_tag;
        else begin 
          next_state=cur_state;
        end
      end

      `Compare_tag: begin // Compare_tag state
        // for cache hit 
        if((tag == tag_to_read)&valid_read) begin
          is_hit = 1;
          total_count=total_count+1;
          // write hit 
          if(mem_write) begin
            // read and modify cache line
            data_write_enable=1;
            tag_write_enable=1;
            tag_to_write=tag_to_read; 
            valid_write=1;
            dirty_write=1;
          end
          next_state=`Idle;
        end 
        
        // for cache miss 
        else begin
          //miss++;
          tag_write_enable=1;
          valid_write=1;
          tag_to_write=addr[31:8];
          dirty_write=mem_write; 
          dmem_input_valid=1; 
          miss_count = miss_count+1;

          if(valid_read==0||dirty_read==0) begin
            mem_read_req=1;
            mem_write_req=0;
            dmem_addr=addr;
            next_state=`Allocate; // go to allocate state 
          end

          else begin // valid and dirty_read
         
            dmem_addr={tag_to_read, addr[7:0]}; 
            dmem_din=data_read;
            mem_read_req=0;
            mem_write_req=1;
            next_state=`Write_back; // we need to go to write back state
          end
        end
      end

      `Allocate: begin // allocate state
        if(is_data_mem_ready) begin
          data_write=dmem_dout;
          data_write_enable=1;
          dmem_input_valid=0;
          next_state = `Compare_tag; //go back to compare_tag state
        end
        else begin
        
          next_state=cur_state;
        end
      end

      `Write_back: begin // write back state
        if(is_data_mem_ready) begin // if data memory is ready 
          dmem_input_valid=1; // input valid 
          mem_read_req=1; // only read, not write
          mem_write_req=0; 
          dmem_addr=addr;
          next_state=`Allocate; // go back to the allocate state
        end
        else begin
          next_state=cur_state; // not update next state
        end
      end
    endcase
  end


  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),
    .is_input_valid(dmem_input_valid),
    .addr(dmem_addr >> clog2), 
    .mem_read(mem_read_req),
    .mem_write(mem_write_req),
    .din(dmem_din),
    // is output from the data memory valid?
    .is_output_valid(dmem_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(is_data_mem_ready)
  );

  Cache_bank c_bank( 
  .reset(reset),
  .clk(clk),
  .index(index),
  .tag_write_enable(tag_write_enable),
  .data_write_enable(data_write_enable),
  .tag_write(tag_to_write),
  .data_write(data_write),
  .valid_write(valid_write),
  .dirty_write(dirty_write),
  .tag_read(tag_to_read),
  .data_read(data_read),
  .valid_read(valid_read),
  .dirty_read(dirty_read)
  );
endmodule

// We defined cache bank. (data bank + tag bank) 

module Cache_bank #(parameter NUM_SETS = 16)( // initialize databank

  input reset,
  input clk,
  
  input [3:0] index,
  input tag_write_enable, 
  input data_write_enable,
  input [23:0] tag_write,
  input [127:0] data_write,
  input valid_write,
  input dirty_write,
  
  output [23:0] tag_read,
  output [127:0] data_read,
  output valid_read,
  output dirty_read
 );
 
  reg [23:0] tag_bank [0:NUM_SETS-1];
  reg [127:0] data_bank [0:NUM_SETS-1];
  
  reg valid_table [0:NUM_SETS-1];
  reg dirty_table [0:NUM_SETS-1];
  
  //assign for data
  assign data_read = data_bank[index]; 

  //assign for tag
  assign tag_read = tag_bank[index];
  assign valid_read = valid_table[index];
  assign dirty_read = dirty_table[index];
  
  always @(posedge clk) begin // databank update

    if(reset) begin
        for(integer i=0;i< NUM_SETS;i=i+1) begin
            data_bank[i]=32'bZ;
        end
    end
    
    else if(data_write_enable) begin // if write is enable now 
        data_bank[index] <= data_write; //databank write
    end
  end
  
  always @(posedge clk) begin // tagbank update
 
    if(reset) begin
        for(integer i=0;i< NUM_SETS;i=i+1) begin
            tag_bank[i]=24'bZ;
            valid_table[i]=0;
            dirty_table[i]=0;
        end
    end
    
    else if (tag_write_enable) begin
        tag_bank[index] <= tag_write;
        valid_table[index] <= valid_write;
        dirty_table[index] <= dirty_write;
    end
  end

endmodule
  
  
  
