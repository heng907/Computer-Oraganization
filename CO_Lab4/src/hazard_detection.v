`timescale 1ns / 1ps
// <your student id>
// 111550129
/** [Reading] 4.7 p.372-375
 * Understand when and how to detect stalling caused by data hazards.
 * When read a reg right after it was load from memory,
 * it is impossible to solve the hazard just by forwarding.
 */

/* checkout FIGURE 4.59 to understand why a stall is needed */
/* checkout FIGURE 4.60 for how this unit should be connected */

module hazard_detection (
    input            branch,
    input            ID_EX_mem_read,
    input    [4:0]   ID_EX_rt,
    input    [4:0]   IF_ID_rs,
    input    [4:0]   IF_ID_rt,
    input            EX_MEM_mem_read,
    input            EX_MEM_reg_write,
    input    [4:0]   EX_MEM_write_reg,
    input            MEM_WB_mem_to_reg,
    input    [4:0]   MEM_WB_write_reg,
    output    reg    pc_write,           // only update PC when this is set
    output    reg    IF_ID_write,        // only update IF/ID stage registers when this is set
    output    reg    stall               // insert a stall (bubble) in ID/EX when this is set
);
    /** [step 3] Stalling
     * 1. calculate stall by equation from textbook.
     * 2. Should pc be written when stall?
     * 3. Should IF/ID stage registers be updated when stall?
     */
    always @(*) begin
        if (ID_EX_mem_read && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt))) begin
            // A load-use hazard is detected
            stall = 1'b1;        // Insert a stall
            pc_write = 1'b0;     // Do not update PC
            IF_ID_write = 1'b0;  // Do not update IF/ID stage registers
        end else begin
            // No hazard detected
            stall = 1'b0;        // No stall needed
            pc_write = 1'b1;     // Update PC
            IF_ID_write = 1'b1;  // Update IF/ID stage registers
        end
    end
//    // 1. Calculate stall signal
//     assign stall = (ID_EX_mem_read && ((ID_EX_rt == IF_ID_rs) || (ID_EX_rt == IF_ID_rt)));

//     // 2. PC should not be written when there is a stall
//     assign pc_write = ~stall;
 
//     // 3. IF/ID stage registers should not be updated when there is a stall
//     assign IF_ID_write = ~stall;
endmodule
