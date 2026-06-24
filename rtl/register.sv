module register (
    input [7:0] data,
    input enable, clk, rst_,
    output logic [7:0] out
);
    timeunit 1ns;
    timeprecision 100ps;

    always_ff @( posedge clk , negedge rst_) begin 
        if(~rst_) out <= 8'd0;
        else if (enable) out <= data;
    end
endmodule