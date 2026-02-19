`timescale 1ns / 1ps
// <your student id>
//111550129
/* checkout FIGURE C.5.10 (Bottom) */
/* [Prerequisite] complete bit_alu.v */
module msb_bit_alu (
    input        a,          // 1 bit, a
    input        b,          // 1 bit, b
    input        less,       // 1 bit, Less
    input        a_invert,   // 1 bit, Ainvert
    input        b_invert,   // 1 bit, Binvert
    input        carry_in,   // 1 bit, CarryIn
    input  [1:0] operation,  // 2 bit, Operation
    output  reg  result,     // 1 bit, Result (Must it be a reg?)
    output       set,        // 1 bit, Set
    output       overflow    // 1 bit, Overflow
);

    /* Try to implement the most significant bit ALU by yourself! */
    wire ai, bi;
    //invert
//    assign ai = a ^ a_invert;
//    assign bi = b ^ b_invert;
    assign ai = (a_invert == 0) ? a: ~a ;
    assign bi = (~b_invert & b) | (b_invert & ~b);

    //1-bit full adder
//    assign carry_out = (carry_in & ai) | (carry_in & bi) | (ai & bi);
//    assign sum       = (ai ^ bi ^ carry_in); //(a.b'.carryin')+(a'.b.carryin')+(a'.b'.carryin)+(a.b.carryin)
    assign carry_out = ( ai & bi ) | ( (ai ^ bi) & carry_in );
    
    //SLT operation
    assign set = ( ai ^ bi ) ^ carry_in;

    //overflow
    // overflow when carry_out is 0 and carry_in is 1
    // or carry_out is 1 and carry_in is 0
//    assign overflow = (operation == 2'b10) ? (~a & ~b & sum) | (a & b & ~sum) : 0;
    assign overflow  = (operation == 2'b10 | operation == 2'b11) ? ( carry_in ^ carry_out ) : 0;//using a mux to assign result
    always @(*) begin
        case (operation)
            2'b00:   result <= ai & bi;  // AND
            2'b01:   result <= ai | bi;  // OR
            2'b10:   result <= set;  // ADD
            2'b11:   result <= less;  // SLT
            default: result <= 0;  // should not happened
        endcase
    end


endmodule
