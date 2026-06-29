///////////////////////////////////////////////////////////////////////////
// (c) Copyright 2013 Cadence Design Systems, Inc. All Rights Reserved.
//
// File name   : mem_intf_tb.sv
// Title       : Memory Testbench Module
// Project     : SystemVerilog Training
// Created     : 2013-4-8
// Description : Defines the Memory testbench module
// Notes       :
// 
///////////////////////////////////////////////////////////////////////////



module mem_intf_test (mem_if intf);
// SYSTEMVERILOG: timeunit and timeprecision specification
timeunit 1ns;
timeprecision 1ns;

// SYSTEMVERILOG: new data types - bit ,logic
bit         debug = 1;
logic [7:0] rdata;      // stores data read from memory for checking

// Monitor Results
  initial begin
      $timeformat ( -9, 0, " ns", 9 );
// SYSTEMVERILOG: Time Literals
      #40000ns $display ( "MEMORY TEST TIMEOUT" );
      $finish;
    end

initial
  begin: memtest
  int error_status;

    $display("Clear Memory Test");

    for (int i = 0; i< 32; i++)
       // Write zero data to every address location
       intf.write_mem(i, 8'd0);

    for (int i = 0; i<32; i++)
      begin 
       // Read every address location
        intf.read_mem(i, rdata);
       // check each memory location for data = 'h00
        if (rdata != 8'd0) begin
          error_status++;
          $display("address=%0d data=%h should be 00", i, rdata);
        end
      end

   // print results of test
    printstatus(error_status);

    $display("Data = Address Test");
    error_status = 0;

    for (int i = 0; i< 32; i++)
       // Write data = address to every address location
       intf.write_mem(i, i[7:0]);
       
    for (int i = 0; i<32; i++)
      begin
       // Read every address location
        intf.read_mem(i, rdata);
       // check each memory location for data = address
        if(rdata != i) begin
          error_status++;
          $display("address=%0d data=%h should be %0d", i, rdata, i);
        end
      end

   // print results of test
    printstatus(error_status);

    $finish;
  end

// add read_mem and write_mem tasks
// add result print function
  function void printstatus(input int status);
    if (status == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED: %0d error(s)", status);
  endfunction

endmodule
