
module cpu_test_1; 
timeunit 1ns;
timeprecision 100ps;

import typedefs::*;

logic          rst_;
logic [12*8:1] testfile;
opcode_t   topcode;

logic clk, alu_clk, cntrl_clk, clk2, fetch, halt;
logic load_ir;

// clock generator
`define PERIOD 10
logic master_clk = 1'b1;

logic [3:0] count;

always
    #(`PERIOD/2) master_clk = ~master_clk;


always @(posedge master_clk or negedge rst_)
   if (~rst_)
     count <= 4'b0;
   else
     count <= count + 1;

assign cntrl_clk = ~count[0];
assign clk  = count[1];
assign fetch = ~count[3];
assign alu_clk = ~(count == 4'hc);
// end of clock generator

cpu     cpu1    (
                .halt  (halt  ),
                .load_ir(load_ir),
                .clk   (clk   ),     
                .alu_clk   (alu_clk),    
                .cntrl_clk   (cntrl_clk),    
                .fetch (fetch ),
                .rst_  (rst_  )
                );


  // Monitor Results

  initial
    $timeformat ( -9, 1, " ns", 12 );


  // Apply Stimulus

  initial
      begin
            $display ( "CPUtest1 - BASIC CPU DIAGNOSTIC PROGRAM \n" );
            $display ( "THIS TEST SHOULD HALT WITH THE PC AT 17 hex\n" );

            testfile = { "CPUtest1.dat" };

            $display ( "Test file: %s\n", testfile);

            $readmemb ( testfile, cpu1.mem1.memory );
            rst_ = 1;
            repeat (2) @(negedge master_clk);
            rst_ = 0;
            repeat (2) @(negedge master_clk);
            rst_ = 1;
            $display("     TIME       PC    INSTR    OP   ADR   DATA\n");
            $display("  ----------    --    -----    --   ---   ----\n");
            while ( !halt )
              @( posedge clk )
              // hierarchical pathname reference
              if ( load_ir )
                begin
                  #(`PERIOD/2)
                  topcode =  cpu1.opcode;
                  $display ( "%t    %h    %s      %h    %h     %h     %h",
                    $time,cpu1.pc_addr,topcode.name(),cpu1.opcode,
                    cpu1.addr,cpu1.alu_out,cpu1.data_out );
                end
            if (cpu1.pc_addr !== 5'h17)
              begin
                $display ( "CPU TEST FAILED" );
                $finish;
              end
            $display ( "\nCPU TEST 1 PASSED");
            $finish;
          end

endmodule
