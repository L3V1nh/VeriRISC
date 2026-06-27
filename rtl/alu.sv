module alu (
    input [7:0] accum, data,
    input [2:0] opcode,
    input clk,
    output logic [7:0] out,
    output zero
);
    timeunit 1ns;
    timeprecision 100ps;
    import alu_typedefs::*;
    
    
    opcode_t opc;
    assign opc = opcode_t'(opcode);
    assign zero = accum == '0;
    logic [7:0] out_next;

    always_ff @( negedge clk ) begin
        out <= out_next;
    end
    always_comb begin : output_logic
        case (opc)
            ADD: out_next = data + accum;
            AND: out_next = data & accum;
            XOR: out_next = data ^ accum;
            LDA: out_next = data;
            default: out_next = accum;
        endcase
    end

endmodule