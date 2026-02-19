`timescale 1ns / 1ps
// <your student id>
//111550129
/** [Reading] 4.4 p.321-327
 * "Operation of the Datapath"
 * "Finalizing Control": double check your control.v !
 */
/** [Prerequisite] control.v
 * This module is the single-cycle MIPS processor in FIGURE 4.17
 * You can implement it by any style you want, but port `clk` & `rstn` must remain.
 */

/* checkout FIGURE 4.17 */
module single_cycle #(
    parameter integer TEXT_BYTES = 1024,        // size in bytes of instruction memory
    parameter integer TEXT_START = 'h00400000,  // start address of instruction memory
    parameter integer DATA_BYTES = 1024,        // size in bytes of data memory
    parameter integer DATA_START = 'h10008000   // start address of data memory
) (
    input clk,  // clock
    input rstn  // negative reset
);

    /* Instruction Memory */
    wire [31:0] instr_mem_address, instr_mem_instr;
    instr_mem #(
        .BYTES(TEXT_BYTES),
        .START(TEXT_START)
    ) instr_mem (
        .address(instr_mem_address),
        .instr  (instr_mem_instr)
    );

    /* Register Rile */
    wire [4:0] reg_file_read_reg_1, reg_file_read_reg_2, reg_file_write_reg;
    wire reg_file_reg_write;
    wire [31:0] reg_file_write_data, reg_file_read_data_1, reg_file_read_data_2;
    reg_file reg_file (
        .clk        (clk),
        .rstn       (rstn),
        .read_reg_1 (reg_file_read_reg_1),
        .read_reg_2 (reg_file_read_reg_2),
        .reg_write  (reg_file_reg_write),
        .write_reg  (reg_file_write_reg),
        .write_data (reg_file_write_data),
        .read_data_1(reg_file_read_data_1),
        .read_data_2(reg_file_read_data_2)
    );

    /* ALU */
    wire [31:0] alu_a, alu_b, alu_result;
    wire [3:0] alu_ALU_ctl;
    wire alu_zero, alu_overflow;
    alu alu (
        .a       (alu_a),
        .b       (alu_b),
        .ALU_ctl (alu_ALU_ctl),
        .result  (alu_result),
        .zero    (alu_zero),
        .overflow(alu_overflow)
    );

    /* Data Memory */
    wire data_mem_mem_read, data_mem_mem_write;
    wire [31:0] data_mem_address, data_mem_write_data, data_mem_read_data;
    data_mem #(
        .BYTES(DATA_BYTES),
        .START(DATA_START)
    ) data_mem (
        .clk       (clk),
        .mem_read  (data_mem_mem_read),
        .mem_write (data_mem_mem_write),
        .address   (data_mem_address),
        .write_data(data_mem_write_data),
        .read_data (data_mem_read_data)
    );

    /* ALU Control */
    wire [1:0] alu_control_alu_op;
    wire [5:0] alu_control_funct;
    wire [3:0] alu_control_operation;
    alu_control alu_control (
        .alu_op   (alu_control_alu_op),
        .funct    (alu_control_funct),
        .operation(alu_control_operation)
    );
    
    
    /* (Main) Control */  // named without `control_` prefix!
    wire [5:0] opcode;
    wire reg_dst, alu_src, mem_to_reg, reg_write, mem_read, mem_write, branch;
    wire [1:0] alu_op;
    control control (
        .opcode    (opcode),
        .reg_dst   (reg_dst),
        .alu_src   (alu_src),
        .mem_to_reg(mem_to_reg),
        .reg_write (reg_write),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .branch    (branch),
        .jump      (jump),
        .ori       (ori),
        .lui       (lui),
        .alu_op    (alu_op)
    );

    /** [step 1] Instruction Fetch
     * Fetch the instruction pointed by PC form memory.
     * 1. We need a register to store PC.
     * 2. Wire the pc to instruction memory.
     * 3. Implement an adder to calculate PC+4. (combinational)
     *    Hint: use "+" operator.
     */
    /** [Check Yourself]
     * After this stage, what does `instr_mem_instr` represents?
     */
    reg [31:0] pc;  // DO NOT change this line
    
    // PC register
//    initial pc = TEXT_START; // Initial value for PC
    
    // Increment PC by 4 to fetch the next instruction
    wire [31:0] pc_next = pc + 4; 
    
    // Connect the PC to the instruction memory address
    assign instr_mem_address = pc;

    
    /** [step 2] Instruction Decode
     * Let the processor understand what the instruction means & how to process this instruction.
     * (And read register files)
     * i.e. Let Control & ALU Control set correct control signal.
     * We will implement from top to bottom in FIGURE 4.17.
     * 1. Each segment of instruction refers to different meanings.
     *    Review FIGURE 4.14 to understand MIPS instruction formats. (Green Card is helpful, too)
     * 2. Wire each segment to Control & read address of Register File.
     * 3. Skip write address of Register File here.
     *    We will wire it in step 5.
     * 4. Implement a Sign-extend unit. (combinational)
     *    Hint: in two's complement, which bit represents sign-bit?
     * 5. Wire an segment to ALU Control.
     * 6. Wire ALUOp.
     * Hint: you can check your wiring by "Schematic" in Vivado.
     */
    /** [Check Yourself]
     * After this stage, are the outputs of Control ready?
     * Why we use combinational logic for Control unit instead of sequential?
     */
        // Extracting fields from instruction
    wire [5:0] instr_opcode = instr_mem_instr[31:26];
    wire [4:0] instr_rs = instr_mem_instr[25:21];
    wire [4:0] instr_rt = instr_mem_instr[20:16];
    
    wire [4:0] instr_rd = instr_mem_instr[15:11];
    
    wire [5:0] instr_funct = instr_mem_instr[5:0];
    wire [15:0] instr_immediate = instr_mem_instr[15:0];
    
    // Sign-extension
    wire [31:0] sign_extended_immediate = {{16{instr_immediate[15]}}, instr_immediate[15:0]};
    
    // Set read addresses for register file
    assign reg_file_read_reg_1 = instr_rs;
    assign reg_file_read_reg_2 = instr_rt;
    
    // Connect opcode and function to control units
    assign opcode = instr_opcode;
    assign alu_control_funct = instr_funct;
    assign alu_control_alu_op = alu_op;


    

    /** [step 3] Execution
     * The processor execute the instruction using ALU.
     * e.g. calculate result of R-type instr, address of load/store, branch or not.
     * 1. Wire control signal to ALU.
     * 2. Use a Mux to select inputs (a, b) of ALU.
     *    Hint: use "?" operator with "assign", which is easier to read than an always block.
     * 3. Calculate branch target address. (combinational)
     * 4. Use a Mux & gate to select the next pc to be pc+4 or branch target. (combinational)
     */
    /** [Check Yourself]
     * Can you describe what the result of ALU means and how it is calculated for each different instruction?
     */
    // ALU connections
    assign alu_a = reg_file_read_data_1; // Connect the read data 1 to ALU input a
    assign alu_b = alu_src ? sign_extended_immediate : reg_file_read_data_2; // Mux for ALU input b
    assign alu_ALU_ctl = alu_control_operation;
    
    // Compute branch target address (add sign-extended immediate shifted left by 2 to PC+4)
    wire [31:0] branch_target = (branch & alu_zero) ? (pc_next + (sign_extended_immediate << 2)) : pc_next;
    
    // Implement jump address calculation (for J-type instructions)
    wire [31:0] nxt_pc = jump ? {pc_next[31:28], instr_mem_instr[25:0], 2'b00} : branch_target;
    
//    // Update the Mux logic for the next PC value to include the jump logic
//    wire [31:0] pc_pre_branch = jump ? jump_address : pc_next;
    
//    // Now include the branch logic (assuming you have a 'branch' control signal)
//    assign pc_src = (branch && alu_zero) ? branch_target : pc_pre_branch;

    /** [step 4] Memory
     * The processor interact with Data Memory to execute load/store instr.
     * 1. wire address & data to write
     * 2. wire control signal of read/write
     * 3. check the clock signal is wired to data memory.
     */
    /** [Check Yourself]
     * Can you describe how the address is calculated?
     */
    // Wire the address to data memory, which is the result from ALU
    assign data_mem_address = alu_result;

    // Wire the data to write to data memory, which is the content of the second register read from the register file
    assign data_mem_write_data = reg_file_read_data_2;
    // Wire the control signals to data memory
    assign data_mem_mem_read = mem_read;
    assign data_mem_mem_write = mem_write;

    /** [step 5] Write Back
     * For R-type & load/store instr, data calculated or read from memory should be write back to register file.
     * 1. Use a Mux to select whether the write reg is rt or rd.
     * 2. Use a Mux to select whether the write data is from ALU or Memory.
     * 3. Wire the write control signal of Register File.
     */
//    // Define wire for the write data
//    wire [31:0] write_data;

//    // MUX to select between ALU result and memory data
//    assign write_data = (mem_to_reg) ? data_mem_read_data : alu_result;
//    // Wire the write control signal to the Register File
//    // 'reg_file_reg_write' is assumed to be the write enable signal for the register file
//    assign reg_file_reg_write = reg_write;
//    // Connect the write register and write data to the register file along with the write enable signal

    // Mux for RegDst
    assign reg_file_write_reg = reg_dst ? instr_rd : instr_rt;
    
    // Mux for MemtoReg
//    assign reg_file_write_data = mem_to_reg ? data_mem_read_data : alu_result;
    assign reg_file_write_data = lui ? {instr_mem_instr[15:0], {16{1'b0}}} : 
                             ori ? (reg_file_read_data_1 | { {16{1'b0}}, instr_mem_instr[15:0] }) :
                             mem_to_reg ? data_mem_read_data : alu_result;
    // Register file write enable
    assign reg_file_reg_write = reg_write;

    /** [step 6] Clocking (sequential logic)
     * This define the behavior of processor when a new clock cycle comes.
     * It should be very simple. Do not write your processor like a program.
     * Instead, it should looks more like a bunch of connected hardwares.
     * In single-cycle processor, it have to do 2 things:
     * 1. Update the registers inside the processor.
     *    Depends on your implementation, at least PC needs to be updated.
     * 2. Write data into Register File or Memory.
     *    Remember in Lab 1, Register File write is positive edge-trigger.
     * What else needs to be done besides clearing Register File when reset?
     * Important: our processor executes instruction at 0x00400000 when booted.
     */
    // Sequential block for the positive edge of the clock
    always @(posedge clk) 
//        if (!rstn) begin
//            // Reset condition: initialize PC and possibly other registers
//            pc <= TEXT_START; // Set PC to the initial address (0x00400000)
        if(rstn) begin
            // Normal operation: update the PC and any other necessary registers
            // 'next_pc' is the calculated next value for PC which could be PC+4 or a branch target
            pc = nxt_pc;
            // Any other state updates would go here
        end
    
//     Sequential block for the negative edge of the reset
    always @(negedge rstn) begin
        // Clear the register file and set PC to the initial address
        // This assumes a synchronous reset for the register file; if it's asynchronous, it would be outside this block.
        pc = TEXT_START; // Set PC to the initial address (0x00400000)
        // Here you would also reset any other stateful elements
    end
    
endmodule

