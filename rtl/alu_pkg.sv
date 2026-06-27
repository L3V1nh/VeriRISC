package alu_typedefs;
    typedef enum logic [3:0]{ 
        HLT, SKZ,
        ADD, AND,
        XOR, LDA,
        STO, JMP
    } opcode_t;
endpackage