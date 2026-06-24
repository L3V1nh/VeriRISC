module scale_mux #(
    parameter WIDTH = 1
) (
    input [WIDTH-1:0] in_a, in_b,
    input sel_a,
    output logic [WIDTH-1:0] out
);
    timeunit 1ns;
    timeprecision 100ps;

    always_comb begin : mux_logic
        unique case(sel_a)
            1'b0: out = in_b;
            1'b1: out = in_a;
            default: out = 'x;
        endcase
    end
endmodule