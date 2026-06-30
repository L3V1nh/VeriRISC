module register #(WIDTH=8) (
    input [WIDTH-1:0] data,
    input enable, clk, rst_,
    output logic [WIDTH-1:0] out
);
    timeunit 1ns;
    timeprecision 100ps;

    always_ff @( posedge clk , negedge rst_) begin 
        if(~rst_) out <= '0;
        else if (enable) out <= data;
    end
endmodule