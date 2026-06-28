///////////////////////////////////////////////////////////////////////////
// (c) Copyright 2013 Cadence Design Systems, Inc. All Rights Reserved.
//
// File name   : mem_test.sv
// Title       : Memory Testbench Module
// Project     : SystemVerilog Training
// Created     : 2013-4-8
// Description : Defines the Memory testbench module
// Notes       :
// 
///////////////////////////////////////////////////////////////////////////

module mem_test ( input logic clk, 
                  output logic read, 
                  output logic write, 
                  output logic [4:0] addr, 
                  output logic [7:0] data_in,     // data TO memory
                  input  wire [7:0] data_out     // data FROM memory
                );
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
       write_mem(i, 8'd0);

    for (int i = 0; i<32; i++)
      begin 
       // Read every address location
        read_mem(i, rdata);
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
       write_mem(i, i[7:0]);
       
    for (int i = 0; i<32; i++)
      begin
       // Read every address location
        read_mem(i, rdata);
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
  task  write_mem (input logic [4:0] address, input logic [7:0] data, input bit debug = 0);
    @ (negedge clk);
    read <= '0;
    write <= '1;
    addr <= address;
    data_in <= data;
    if(debug) $display("Address: %h, Write Data:%h", address, data);
  endtask

  task  read_mem(input logic [4:0] address, output logic [7:0] read_data, input bit debug = 0);
    @ (negedge clk);
    write <= '0;
    read <= '1;
    addr <= address;
    #6 read_data = data_out;
    if(debug) $display("Address: %h, Read Data:%h", address, read_data);
  endtask
// add result print function
  function void printstatus(input int status);
    if (status == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED: %0d error(s)", status);
  endfunction

endmodule
