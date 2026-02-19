`timescale 1ns / 1ps
// <your student id>
// 111550129
/** [Prerequisite] Lab 2: alu, control, alu_control
 * This module is the pipelined MIPS processor in FIGURE 4.51
 * You can implement it by any style you want, as long as it passes testbench
 */

/* checkout FIGURE 4.51 */
module pipelined #(
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
        .clk        (~clk),                  // only write when negative edge
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
        .clk       (~clk),                 // only write when negative edge
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

    /* (Main) Control */
    wire [5:0] control_opcode;
    // Execution/address calculation stage control lines
    wire control_reg_dst, control_alu_src;
    wire [1:0] control_alu_op;
    // Memory access stage control lines
    wire control_branch, control_mem_read, control_mem_write;
    // Wire-back stage control lines
    wire control_reg_write, control_mem_to_reg;
    control control (
        .opcode    (control_opcode),
        .reg_dst   (control_reg_dst),
        .alu_src   (control_alu_src),
        .mem_to_reg(control_mem_to_reg),
        .reg_write (control_reg_write),
        .mem_read  (control_mem_read),
        .mem_write (control_mem_write),
        .branch    (control_branch),
        .alu_op    (control_alu_op)
    );

    /** [step 1] Instruction fetch (IF)
     * 1. We need a register to store PC (acts like pipeline register).
     * 2. Wire pc to instruction memory.
     * 3. Implement an adder to calculate PC+4. (combinational)
     *    Hint: use "+" operator.
     * 4. Update IF/ID pipeline registers, and reset them @(negedge rstn)
     *    a. fetched instruction
     *    b. PC+4
     *    Hint: What else should be done when reset?
     *    Hint: Update of PC can be handle later in MEM stage.
     */
    // 1.
    reg [31:0] pc;  // DO NOT change this line
    // 2.
    assign instr_mem_address = pc;
    // 3.
    wire [31:0] pc_4 = pc + 4;
    // 4.
    reg [31:0] IF_ID_instr, IF_ID_pc_4;
    always @(posedge clk)
        if (rstn) begin
            IF_ID_instr <= instr_mem_instr;  // a.
            IF_ID_pc_4  <= pc_4;  // b.
        end
    always @(negedge rstn) begin
        IF_ID_instr <= 0;  // a.
        IF_ID_pc_4  <= 0;  // b.
    end

    /** [step 2] Instruction decode and register file read (ID)
     * From top to down in FIGURE 4.51: (instr. refers to the instruction from IF/ID)
     * 1. Generate control signals of the instr. (as Lab 2)
     * 2. Read desired registers (from register file) in the instr.
     * 3. Calculate sign-extended immediate from the instr.
     * 4. Update ID/EX pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB, MEM, EX)
     *    b. ??? (something from IF/ID)
     *    c. Data read from register file
     *    d. Sign-extended immediate
     *    e. ??? & ??? (WB stage needs to know which reg to write)
     */
    // Extract parts of the instruction
     wire [5:0] opcode = IF_ID_instr[31:26];
     wire [5:0] funct = IF_ID_instr[5:0];
     wire [4:0] rs = IF_ID_instr[25:21];
     wire [4:0] rt = IF_ID_instr[20:16];
    //  wire [4:0] rd = IF_ID_instr[15:11];
     wire [15:0] immediate = IF_ID_instr[15:0];

     // Sign-extend the immediate
     wire [31:0] sign_extended_immed = {{16{immediate[15]}}, immediate};

     // Control signals are already generated by your 'control' module
     assign control_opcode = opcode;

     // Connect register file
     assign reg_file_read_reg_1 = rs;
     assign reg_file_read_reg_2 = rt;
     
    
    // pipelined register of ID/EX
    // reg control_reg_dst_EX, control_alu_src_EX;
    // reg control_mem_read_EX, control_mem_write_EX, control_reg_write_EX;
    // IE:ID/EX
     reg [31:0] IE_next_pc;
     reg [31:0] IE_read_data1, IE_read_data2;
     reg [31:0] IE_sign_extended_immed;
     reg [4:0] IE_rs, IE_rt, IE_rd;
     reg IE_reg_dst, IE_alu_src, IE_mem_to_reg, IE_reg_write, IE_mem_read, IE_mem_write, IE_branch;
     reg [1:0] IE_alu_op;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            IE_next_pc <= 0;
            IE_read_data1 <= 0;
            IE_read_data2 <= 0;
            IE_sign_extended_immed <= 0;
            IE_rs <= 0;
            IE_rt <= 0;
            IE_rd <= 0;
            IE_reg_dst <= 0;
            IE_alu_src <= 0;
            IE_mem_to_reg <= 0;
            IE_reg_write <= 0;
            IE_mem_read <= 0;
            IE_mem_write <= 0;
            IE_branch <= 0;
            IE_alu_op <= 0;
            // Initialize control signals
        end else begin
            IE_next_pc <= IF_ID_pc_4;
            IE_read_data1 <= reg_file_read_data_1;
            IE_read_data2 <= reg_file_read_data_2;
            IE_sign_extended_immed <= sign_extended_immed;
            IE_rs <= IF_ID_instr[25:21];
            IE_rt <= IF_ID_instr[20:16];
            IE_rd <= IF_ID_instr[15:11];
            IE_reg_dst <= control_reg_dst;
            IE_alu_src <= control_alu_src;
            IE_mem_to_reg <= control_mem_to_reg;
            IE_reg_write <= control_reg_write;
            IE_mem_read <= control_mem_read;
            IE_mem_write <= control_mem_write;
            IE_branch <= control_branch;
            IE_alu_op <= control_alu_op;
            // Latch control signals
        end
    end
    
    /** [step 3] Execute or address calculation (EX)
     * From top to down in FIGURE 4.51
     * 1. Calculate branch target address from sign-extended immediate.
     * 2. Select correct operands of ALU like in Lab 2.
     * 3. Wire control signals to ALU control & ALU like in Lab 2.
     * 4. Select correct register to write.
     * 5. Update EX/MEM pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB, MEM)
     *    b. Branch target address
     *    c. ??? (What information dose MEM stage need to determine whether to branch?)
     *    d. ALU result
     *    e. ??? (What information does MEM stage need when executing Store?)
     *    f. ??? (WB stage needs to know which reg to write)
     */
    // 1.
     wire [31:0] branch_target = IE_next_pc + (IE_sign_extended_immed << 2);
    
    // 2. ALU connections
    wire [31:0] alu_input_a = IE_read_data1;
    wire [31:0] alu_input_b = IE_alu_src ? IE_sign_extended_immed : IE_read_data2;

   
    // 3.ALU control

     assign alu_control_alu_op = IE_alu_op;
     assign alu_control_funct = IE_sign_extended_immed [5:0];
     wire [3:0] alu_control_signal = alu_control_operation; 
    
     assign alu_a = alu_input_a;
     assign alu_b = alu_input_b;    
     assign alu_ALU_ctl = alu_control_signal; 
    // 4. 
     wire[4:0] W_reg = IE_reg_dst ? IE_rd : IE_rt;
    // 5. update EX/MEM
     // EM: EX/MEM 
     reg [31:0] EM_branch_target, EM_alu_result, EM_store_data;
     reg EM_alu_zero;
     reg [4:0] EM_write_reg;
     reg EM_reg_write, EM_mem_to_reg, EM_mem_read, EM_mem_write, EM_branch;
 
     always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            EM_branch_target <= 32'b0;
            EM_alu_result <= 32'b0;
            EM_store_data <= 32'b0;
            EM_alu_zero <= 0;
            EM_write_reg <= 5'b0;
            EM_reg_write <= 0;
            EM_mem_to_reg <= 0;
            EM_mem_read <= 0;
            EM_mem_write <= 0;
            // initialize control signals
        end else begin
            // Pass values to the EX/MEM pipeline stage on positive clock edge
            EM_branch_target <= branch_target;
            EM_alu_result <= alu_result;
            EM_store_data <= IE_read_data2;
            EM_alu_zero <= alu_zero;
            EM_write_reg <= W_reg;
            EM_reg_write <= IE_reg_write;
            EM_mem_to_reg <= IE_mem_to_reg;
            EM_mem_read <= IE_mem_read;
            EM_mem_write <= IE_mem_write;
            EM_branch <= IE_branch;
            // latch control signals
        end
    end     

    /** [step 4] Memory access (MEM)
     * From top to down in FIGURE 4.51
     * 1. Decide whether to branch or not.
     * 2. Wire address & data to write
     * 3. Wire control signal of read/write
     * 4. Update MEM/WB pipeline registers, and reset them @(negedge rstn)
     *    a. Control signals (WB)
     *    b. ???
     *    c. ???
     *    d. ???
     * 5. Update PC.
     */
    // 1. decide on branching
    wire take_branch = (EM_branch && EM_alu_zero) ? 1:0;
    // 2??3. data memory operation
    assign data_mem_mem_read = EM_mem_read;
    assign data_mem_mem_write = EM_store_data;
    assign data_mem_address = EM_alu_result;
    assign data_mem_write_data = EM_mem_write;
    //4. update MEM/WB
    //MW: MEM / WB
    reg [31:0] MW_data_to_write, MW_alu_result;
    reg [4:0] MW_w_reg;
    reg MW_reg_write, MW_mem_to_reg;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset MEM/WB pipeline registers
            MW_data_to_write <= 0;
            MW_alu_result <= 0;
            MW_w_reg <= 0;
            MW_reg_write <= 0;
            MW_mem_to_reg <= 0;
        end else begin
            // Update the MEM/WB pipeline registers
            MW_data_to_write <= data_mem_mem_read ? data_mem_read_data : EM_alu_result;
            MW_alu_result <= EM_alu_result;
            MW_w_reg <= EM_write_reg;
            MW_reg_write <= EM_reg_write;
            MW_mem_to_reg <= EM_mem_to_reg;
        end
    end
    //5.update pc
//     always @(posedge clk or negedge rstn) begin
//         if (!rstn) begin
//             pc <= TEXT_START;
//         end else if (take_branch) begin
//             pc <= EM_branch_target;
// //            pc <= branch_target;
//         end else begin
//             pc <= pc_4;
//         end
//     end
    


    always @(posedge clk)
        if (rstn) begin
            pc <= take_branch ? EM_branch_target : pc_4 ;  // 5.
        end
    always @(negedge rstn) begin
        pc <= TEXT_START;
    end


    /** [step 5] Write-back (WB)
     * From top to down in FIGURE 4.51
     * 1. Wire RegWrite of register file.
     * 2. Select the data to write into register file.
     * 3. Select which register to write.
     */

    // 1. Register file update
    assign reg_file_reg_write = MW_reg_write;
    // 2.
    wire [31:0] write_back = MW_mem_to_reg ? MW_data_to_write : MW_alu_result;// Decide between memory and ALU result
    // 3.
    assign reg_file_write_reg = MW_w_reg;  // Decide data to write

    // Connect write back signals
    assign reg_file_write_data = write_back;

endmodule  // pipelined
