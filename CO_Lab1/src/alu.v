`timescale 1ns / 1ps
// <your student id>
//111550129
/* checkout FIGURE C.5.12 */
/** [Prerequisite] complete bit_alu.v & msb_alu.v
 * We recommend you to design a 32-bit ALU with 1-bit ALU.
 * However, you can still implement ALU with more advanced feature in Verilog.
 * Feel free to code as long as the I/O ports remain the same shape.
 */
module alu (
    input  [31:0] a,        // 32 bits, source 1 (A)
    input  [31:0] b,        // 32 bits, source 2 (B)
    input  [ 3:0] ALU_ctl,  // 4 bits, ALU control input
    output [31:0] result,   // 32 bits, result
    output        zero,     // 1 bit, set to 1 when the output is 0
    output        overflow  // 1 bit, overflow
);
    /* [step 1] instantiate multiple modules */
    /**
     * First, we need wires to expose the I/O of 32 1-bit ALUs.
     * You might wonder if we can declare `operation` by `wire [31:0][1:0]` for better readability.
     * No, that is a feature call "packed array" in "System Verilog" but we are using "Verilog" instead.
     * System Verilog and Verilog are similar to C++ and C by their relationship.
     */

     //decalre internal wires
    wire [31:0] less, a_invert, b_invert, carry_in;
    wire [30:0] carry_out;
    wire [63:0] operation;  // flatten vector
    wire        set;  // set of most significant bit
    /**
     * Second, we instantiate the less significant 31 1-bit ALUs
     * How are these modules wired?
     */
    // Decoding ALU control signals
     assign operation = ALU_ctl[1:0]; // Assuming lower two bits for operation
     assign a_invert = ALU_ctl[3];    // Assuming third bit for A invert
     assign b_invert = ALU_ctl[2];    // Assuming fourth bit for B invert
     assign carry_in[0] = b_invert;   // For subtraction, carry_in starts with b_invert

    // Handle the 'less' signal for SLT operation
     assign less = {31'b0, set}; // Only the least significant bit (set) defines the SLT result    
    // Instantiate the 31 less significant 1-bit ALUs
    genvar i;
    generate
        for (i = 0; i < 31; i = i + 1) begin : lsbs
            bit_alu bit_alu_inst (
                .a(a[i]),
                .b(b[i]),
                .less(less[i]),
                .a_invert(a_invert),
                .b_invert(b_invert),
                .carry_in(carry_in[i]),
                .operation(operation),
                .result(result[i]),
                .carry_out(carry_out[i])
            );
        end
    endgenerate

     // Instantiate the most significant 1-bit ALU
    msb_bit_alu msb_bit_alu_inst (
        .a(a[31]),
        .b(b[31]),
        .less(less[31]),
        .a_invert(a_invert),
        .b_invert(b_invert),
        .carry_in(carry_in[30]), // The carry input for the MSB is the carry output from the second-to-MSB
        .operation(operation),
        .result(result[31]),
        .set(set),
        .overflow(overflow)
    );

     // Define carry chain
    assign carry_in[31:1] = carry_out[30:0]; // Carry chain across the ALUs

     // Determine if the result is zero
    assign zero = ~|(result);

endmodule
