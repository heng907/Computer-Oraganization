`timescale 1ns / 1ps
// <1115500129

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
    wire [1:0] forward_A, forward_B, branch_forward_A, branch_forward_B;
    forwarding forwarding (
        .branch             (control_branch),
        .IF_ID_rs           (IF_ID_instr[25:21]),
        .IF_ID_rt           (IF_ID_instr[20:16]),
        .ID_EX_rs           (IE_rs),
        .ID_EX_rt           (IE_write_reg[9:5]),
        .EX_MEM_reg_write   (EM_reg_write),
        .EX_MEM_rd          (EM_write_reg[4:0]),
        .EX_MEM_reg_dst     (EM_reg_dst),
        .MEM_WB_reg_write   (MW_reg_write),
        .MEM_WB_rd          (MW_write_reg),
        .MEM_WB_mem_to_reg  (MW_mem_to_reg),
        .forward_A          (forward_A),
        .forward_B          (forward_B),
        .branch_forward_A   (branch_forward_A),
        .branch_forward_B   (branch_forward_B)
    );
    hazard_detection hazard_detection (
        .branch             (control_branch),
        .ID_EX_mem_read     (IE_mem_read),
        .ID_EX_rt           (IE_write_reg[9:5]),
        .IF_ID_rs           (IF_ID_instr[25:21]),
        .IF_ID_rt           (IF_ID_instr[20:16]),
        .EX_MEM_mem_read    (EM_mem_read),
        .EX_MEM_reg_write   (EM_reg_write),
        .EX_MEM_write_reg   (EM_write_reg[4:0]),
        .MEM_WB_write_reg   (MW_write_reg),
        .MEM_WB_mem_to_reg  (MW_mem_to_reg),
        .pc_write           (pc_write),            // implicitly declared
        .IF_ID_write        (IF_ID_write),         // implicitly declared
        .stall              (stall)                // implicitly declared
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
            if(IF_ID_write)begin
                IF_ID_instr <= instr_mem_instr;  // a.
                IF_ID_pc_4  <= pc_4;  // b.
            end else begin
                IF_ID_instr <= IF_ID_instr;  // a.
                IF_ID_pc_4  <= IF_ID_pc_4;  // b.
            end
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
    assign control_opcode = IF_ID_instr[31:26];
    assign reg_file_read_reg_1 = IF_ID_instr[25:21];
    assign reg_file_read_reg_2 = IF_ID_instr[20:16];

    wire [31:0] extend;
    assign extend[31:16] = {16{IF_ID_instr[15]}};
    assign extend[15:0] = IF_ID_instr[15:0];

    wire [31:0] branch_target;
    assign branch_target = IF_ID_pc_4 + (extend << 2);
    wire [31:0] branch_f_A, branch_f_B;
    assign branch_f_A = (branch_forward_A == 2'b10) ? EM_alu_result : (branch_forward_A == 2'b01) ? reg_file_write_data : reg_file_read_data_1;
    assign branch_f_B = (branch_forward_B == 2'b10) ? EM_alu_result : (branch_forward_B == 2'b01) ? reg_file_write_data : reg_file_read_data_2;
    
    reg [31:0] pc_next;

    always@(*)begin
        if(control_branch & branch_f_A == branch_f_B)begin
            pc_next <= branch_target;
        end else begin
            pc_next <= pc_4;
        end
    end
    always @(posedge clk)
        if (rstn) begin
           if(pc_write) pc <= pc_next;
        end
    always @(negedge rstn) begin
        pc <= TEXT_START;
    end


    reg IE_reg_write, IE_mem_to_reg, IE_mem_write, IE_mem_read, IE_alu_src, IE_reg_dst, IE_branch;
    reg [1:0] IE_alu_op;
    reg [9:0] IE_write_reg;
    reg [4:0] IE_rs;
    reg [31:0] IE_extend, IE_read_1, IE_read_2;
    always @(posedge clk)
        if (rstn) begin
            IE_write_reg[9:5] <= IF_ID_instr[20:16];//rt
            IE_write_reg[4:0] <= IF_ID_instr[15:11];//rd
            IE_rs <= IF_ID_instr[25:21];
            IE_read_1 <= reg_file_read_data_1;  
            IE_read_2 <= reg_file_read_data_2; 
            IE_extend <= extend;
            if(stall)begin
                IE_reg_write <= 0;
                IE_mem_to_reg <= 0;
                IE_mem_write <= 0;
                IE_mem_read <= 0;
                IE_alu_op <= 0;
                IE_alu_src <= 0;
                IE_reg_dst <= 0;
                IE_branch <= 0;
            end else begin
                IE_reg_write <= control_reg_write;
                IE_mem_to_reg <= control_mem_to_reg;
                IE_mem_write <= control_mem_write;
                IE_mem_read <= control_mem_read;
                IE_alu_op <= control_alu_op;
                IE_alu_src <= control_alu_src;
                IE_reg_dst <= control_reg_dst;
                IE_branch <= control_branch;
            end
        end
    always @(negedge rstn) begin
            IE_write_reg <= 10'b0;
            IE_read_1 <= 32'b0;  
            IE_read_2 <= 32'b0;
            IE_rs <= 5'b0;
            IE_reg_write <= 0;
            IE_mem_to_reg <= 0;
            IE_mem_write <= 0;
            IE_mem_read <= 0;
            IE_alu_op <= 2'b0;
            IE_alu_src <= 0;   
            IE_reg_dst <= 0;
            IE_extend <= 32'b0;
            IE_branch <= 0;
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
    assign alu_ALU_ctl = ((control_opcode == 6'b001111) || (control_opcode == 6'b001101)) ? 4'b0010 : alu_control_operation;
    assign alu_a = (forward_A == 2'b10) ? EM_alu_result : (forward_A == 2'b01) ? reg_file_write_data : IE_read_1;
    assign alu_b = (forward_B == 2'b10) ? EM_alu_result : (forward_B == 2'b01) ? reg_file_write_data : (IE_alu_src) ? IE_extend : IE_read_2;
    assign alu_control_alu_op = IE_alu_op;
    assign alu_control_funct = IE_extend[5:0];
    reg EM_reg_write, EM_mem_to_reg, EM_mem_write, EM_mem_read, EM_alu_zero, EM_reg_dst;
    reg [9:0] EM_write_reg;
    reg [31:0] EM_alu_b, EM_alu_result, EM_read_2;
    always @(posedge clk)
        if (rstn) begin
            EM_write_reg[9:5] <= IE_write_reg[9:5];//rt
            EM_write_reg[4:0] <= IE_reg_dst ? IE_write_reg[4:0] : IE_write_reg[9:5]; //rd
            EM_alu_b <= alu_b;  
            EM_reg_write <= IE_reg_write;
            EM_mem_to_reg <= IE_mem_to_reg;
            EM_mem_write <= IE_mem_write;
            EM_mem_read <= IE_mem_read;
            EM_alu_result <= alu_result;
            EM_alu_zero <= alu_zero;
            EM_reg_dst <= IE_reg_dst;
            EM_read_2 <= IE_read_2;
        end
    always @(negedge rstn) begin
            EM_write_reg <= 10'b0;
            EM_alu_b <= 32'b0;  
            EM_reg_write <= 0;
            EM_mem_to_reg <= 0;
            EM_mem_write <= 0;
            EM_mem_read <= 0;
            EM_alu_result <= 32'b0;
            EM_alu_zero <= 0;
            EM_reg_dst <= 0;
            EM_read_2 <= 32'b0;
    end
    assign data_mem_write_data = (MW_mem_to_reg & EM_mem_write & EM_write_reg[9:5] != 5'b0 & EM_write_reg[9:5] == MW_write_reg) ? reg_file_write_data : EM_read_2;
    assign data_mem_address = EM_alu_result;
    assign data_mem_mem_write = EM_mem_write;
    assign data_mem_mem_read = EM_mem_read;
    reg MW_mem_to_reg, MW_reg_write;
    reg [4:0] MW_write_reg;
    reg [31:0] MW_read, MW_alu_result;
    always @(posedge clk)
        if (rstn) begin
            MW_mem_to_reg <= EM_mem_to_reg;
            MW_reg_write <= EM_reg_write;
            MW_write_reg <= EM_write_reg[4:0];
            MW_read <= data_mem_read_data;
            MW_alu_result <= EM_alu_result;
        end
    always @(negedge rstn) begin
            MW_mem_to_reg <= 0;
            MW_reg_write <= 0;
            MW_write_reg <= 5'b0;
            MW_read <= 32'b0;
            MW_alu_result <= 32'b0;
    end
    assign reg_file_write_data = MW_mem_to_reg ? MW_read : MW_alu_result;
    assign reg_file_reg_write = MW_reg_write;
    assign reg_file_write_reg = MW_write_reg;
    /** [step 2] Connect Forwarding unit
     * 1. add `ID_EX_rs` into ID/EX stage registers
     * 2. Use a mux to select correct ALU operands according to forward_A/B
     *    Hint don't forget that alu_b might be sign-extended immediate!
     */
    
    
    //assign alu_a = ???;  // forward 1st operand
    //assign alu_b = ???;  // forward 2nd operand

    /** [step 4] Connect Hazard Detection unit
     * 1. use `pc_write` when updating PC
     * 2. use `IF_ID_write` when updating IF/ID stage registers
     * 3. use `stall` when updating ID/EX stage registers
     */
    
    
    /** [step 5] Control Hazard
     * This is the most difficult part since the textbook does not provide enough information.
     * By reading p.377-379 "Reducing the Delay of Branches",
     * we can disassemble this into the following steps:
     * 1. Move branch target address calculation & taken or not from EX to ID
     * 2. Move branch decision from MEM to ID
     * 3. Add forwarding for registers used in branch decision from EX/MEM
     * 4. Add stalling:
          branch read registers right after an ALU instruction writes it -> 1 stall
          branch read registers right after a load instruction writes it -> 2 stalls
     */
    
endmodule  // pipelined
