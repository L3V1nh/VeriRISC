///////////////////////////////////////////////////////////////////////////
// (c) Copyright 2013 Cadence Design Systems, Inc. All Rights Reserved.
//
// File name   : top.sv
// Title       : top module for Memory labs 
// Project     : SystemVerilog Training
// Created     : 2013-4-8
// Description : Defines the top module for memory labs
// Notes       :
// Memory Lab - top-level 
// A top-level module which instantiates the memory and mem_intf_test modules
// 
///////////////////////////////////////////////////////////////////////////

interface mem_if(input clk);
  logic read; 
  logic write; 
  logic [4:0] addr; 
  logic [7:0] data_in;
  logic [7:0] data_out; 

  modport dut (
  input read, write, addr, data_in,
  output data_out, 
  import write_mem, read_mem
  );
  modport tb (
  input data_out,
  output read, write, addr, data_in
  );

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

endinterface //mem_if

module top;
// SYSTEMVERILOG: timeunit and timeprecision specification
timeunit 1ns;
timeprecision 1ns;

// SYSTEMVERILOG: logic and bit data types
bit clk;
mem_if bus(clk);

// SYSTEMVERILOG:: implicit .* port connections
mem_intf_test test (.intf(bus.tb));

// SYSTEMVERILOG:: implicit .name port connections
mem_intf memory (.intf(bus.dut));

always #5 clk = ~clk;
endmodule
