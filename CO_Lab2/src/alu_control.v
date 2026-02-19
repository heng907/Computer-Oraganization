`timescale 1ns / 1ps
// <your student id>
//111550129
/** [Reading] 4.4 p.316-318
 * "The ALU Control"
 */
/**
 * This module is the ALU control in FIGURE 4.17
 * You can implement it by any style you want.
 * There's a more hardware efficient design in Appendix D.
 */

/* checkout FIGURE 4.12/13 */
module alu_control (
    input [1:0] alu_op,    // ALUOp
    input [5:0] funct,     // Funct field
    output reg [3:0] operation  // Operation
);

    /* implement "combinational" logic satisfying requirements in FIGURE 4.12 */
    // Combinational logic to determine ALU operation
    always @(*) begin
        case (alu_op)
            2'b00: operation <= 4'b0010; // LW and SW, addition
            2'b01: operation <= 4'b0110; // BEQ, subtraction
            2'b10: begin // R-type instructions
                case (funct)
                    6'b100000: operation <= 4'b0010;  // add
                    6'b100010: operation <= 4'b0110;  // sub
                    6'b100100: operation <= 4'b0000;  // and
                    6'b100101: operation <= 4'b0001;  // or
                    6'b100111: operation <= 4'b1100;  // nor
                    6'b101010: operation <= 4'b0111;  // slt
                    default: operation <= 4'b1111;    // not happen
                endcase
            end
            2'b11: operation <= 4'b1110;
            default: operation <= 4'b1111;
        endcase
    end
endmodule
