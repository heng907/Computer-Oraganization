`timescale 1ns / 1ps
// <your student id>
// 111550129
///* checkout FIGURE 4.16/18 to understand each definition of control signals */
module control (
    input  [5:0] opcode,      // the opcode field of a instruction is [?:?]
    output       reg_dst,     // select register destination: rt(0), rd(1)
    output       alu_src,     // select 2nd operand of ALU: rt(0), sign-extended(1)
    output       mem_to_reg,  // select data write to register: ALU(0), memory(1)
    output       reg_write,   // enable write to register file
    output       mem_read,    // enable read form data memory
    output       mem_write,   // enable write to data memory
    output       branch,      // this is a branch instruction or not (work with alu.zero)
    output       jump,
    output       ori,
    output       lui,
    output [1:0] alu_op       // ALUOp passed to ALU Control unit
);

    /* implement "combinational" logic satisfying requirements in FIGURE 4.18 */
    /* You can check the "Green Card" to get the opcode/funct for each instruction. */
    
    // Opcode constants for instruction identification
    //R_type   = 6'b000000 //R-type is 0
    //LW       = 6'b100011 //load word is 35
    //SW       = 6'b101011 //store word is 43
    //BEQ      = 6'b000100 //branch instruction is 4
    assign reg_dst    = ( opcode == 6'b000000 ) ? 1 : 0;              // R-format
    assign alu_src    = ( opcode == 6'b100011 | opcode == 6'b101011 |  opcode == 6'b001111 | opcode == 6'b001101 | opcode == 6'b001000 ) ? 1 : 0;  // lw, sw, lui, ori, addi
    assign mem_to_reg = ( opcode == 6'b100011) ? 1 : 0;  // lw, lui, ori
    // lw and lui need to be 1 since it may search for non-exist memory
    assign reg_write  = ( opcode == 6'b000000 | opcode == 6'b100011 | opcode == 6'b001111 | opcode == 6'b001101 | opcode == 6'b001000 ) ? 1 : 0; // R-type, lw, lui, ori, addi
    assign mem_read   = ( opcode == 6'b100011 ) ? 1 : 0;              // lw
    assign mem_write  = ( opcode == 6'b101011 ) ? 1 : 0;              // sw
    assign branch     = ( opcode == 6'b000100 ) ? 1 : 0;              // beq
    assign jump       = ( opcode == 6'b000010 ) ? 1 : 0;
    assign lui        = ( opcode == 6'b001111 ) ? 1 : 0;  
    assign ori        = ( opcode == 6'b001101 ) ? 1 : 0;  
    assign alu_op[1]  = ( opcode == 6'b000000 ) ? 1 : 0;              // R-format
    assign alu_op[0]  = ( opcode == 6'b000100 ) ? 1 : 0;              // beq
endmodule




    // Combinational logic to set control signals based on opcode
//    always @(*) begin
//        // Initialize control signals to zero
        
//        reg_dst    <= 0;
//        alu_src    <= 0;
//        mem_to_reg <= 0;
//        reg_write  <= 0;
//        mem_read   <= 0;
//        mem_write  <= 0;
//        branch     <= 0;
//        alu_op     <= 2'b00;
        
//        case(opcode)
//            6'b000000: begin  //R_type
//                reg_dst    <= 1;
//                alu_src    <= 0;
//                mem_to_reg <= 0;
//                reg_write  <= 1;
//                mem_read   <= 0;
//                mem_write  <= 0;
//                branch     <= 0;
//                alu_op     = 2'b10;
//            end
//            6'b100011: begin //LW
//                reg_dst    <= 0;
//                alu_src    <= 1;
//                mem_to_reg <= 1;
//                reg_write  <= 1;
//                mem_read   <= 1;
//                mem_write  <= 0;
//                branch     <= 0;
//                alu_op     = 2'b00;
//            end
//            6'b101011: begin  //SW
//                reg_dst    <= 0;
//                alu_src    <= 1;
//                mem_to_reg <= 0;
//                reg_write  <= 0;
//                mem_read   <= 0;
//                mem_write  <= 1;
//                branch     <= 0; 
//                alu_op     = 2'b00;
//            end
//            6'b000100: begin  //BEQ
//                reg_dst    <= 0;
//                alu_src    <= 0;
//                mem_to_reg <= 0;
//                reg_write  <= 0;
//                mem_read   <= 0;
//                mem_write  <= 0;
//                branch     <= 1;
//                alu_op     = 2'b01;
//            end
//            default: begin
//            end
//        endcase
//    end
//endmodule


