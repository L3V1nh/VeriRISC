module control (
    input logic [2:0] opcode,
    input logic zero, clk, rst_, jra,
    output logic mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc
);
    timeunit 1ns;
    timeprecision 100ps;
    import ctrl_typedefs::*;

    state_t state, state_next;
    opcode_t opc;

    logic ALUOP;

    assign ALUOP = opc == ADD | opc == AND | opc ==XOR | opc == LDA;

    always_ff @( posedge clk , negedge rst_) begin : state_reg
        if(~rst_) state <= INST_ADDR;
        else state <= state_next;
    end

    always_comb begin : state_logic
        state_next = state.next();
    end

    always_comb begin : output_logic
        opc = opcode_t'(opcode);
        case (state)
            INST_ADDR: {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = '0;
            INST_FETCH: {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {1'b1, 7'd0};
            INST_LOAD: {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {2'b11, 6'd0};
            IDLE: {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {2'b11, 6'd0};
            OP_ADDR:{mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {2'b00, opc == HLT , 1'b1, 4'd0};
            OP_FETCH:{mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {ALUOP, 6'd0, (opc == JMP) && ~jra};
            ALU_OP:{mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {ALUOP, 2'b00, (opc ==SKZ)&&zero, ALUOP,opc == JMP, 2'b00};
            STORE: {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = {ALUOP, 2'b00,opc == JMP, ALUOP,opc == JMP,opc == STO, 1'b0};
            default: {mem_rd, load_ir, halt, inc_pc, load_ac, load_pc, mem_wr, sto_pc} = 'x;
        endcase
    end

endmodule