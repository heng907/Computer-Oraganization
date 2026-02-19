`timescale 1ns / 1ps
// <your student id>
// 111550129
/** [Reading] 4.7 p.363-371
 * Understand when and how to forward
 */

/* checkout FIGURE 4.55 for definition of mux control signals */
/* checkout FIGURE 4.56/60 for how this unit should be connected */


module forwarding (
    input               branch,
    input    [4:0]      IF_ID_rs,
    input    [4:0]      IF_ID_rt,
    input    [4:0]      ID_EX_rs,// inputs are pipeline registers relate to forwarding
    input    [4:0]      ID_EX_rt,
    input               EX_MEM_reg_write,
    input    [4:0]      EX_MEM_rd,
    input               EX_MEM_reg_dst,
    input               MEM_WB_reg_write,
    input    [4:0]      MEM_WB_rd,
    input               MEM_WB_mem_to_reg,
    output reg [1:0]    forward_A,// ALU operand is from: 00:ID/EX, 10: EX/MEM, 01:MEM/WB
    output reg [1:0]    forward_B,
    output reg [1:0]    branch_forward_A,
    output reg [1:0]    branch_forward_B
);
    /** [step 1] Forwarding
     * 1. EX hazard (p.366)
     * 2. MEM hazard (p.369)
     * 3. Solve potential data hazards between:
          the result of the instruction in the WB stage,
          the result of the instruction in the MEM stage,
          and the source operand of the instruction in the ALU stage.
          Hint: Be careful that the textbook is wrong here!
          Hint: Which of EX & MEM hazard has higher priority?
     */
    
//   always @(*) begin
        
//        //ForwardA
//        if(MEM_WB_reg_write && MEM_WB_rd !=0 && MEM_WB_rd == ID_EX_rs)
//            forward_A <= 2'b10;
//        else if(EX_MEM_reg_write && EX_MEM_rd !=0 && EX_MEM_rd == ID_EX_rs)
//            forward_A <= 2'b01;
//        else
//            forward_A <= 2'b00;
    
//        //ForwardB
//        if(MEM_WB_reg_write && MEM_WB_rd !=0 && MEM_WB_rd == ID_EX_rt)
//            forward_B <= 2'b10;
//        else if(EX_MEM_reg_write && EX_MEM_rd !=0 && EX_MEM_rd == ID_EX_rt)
//            forward_B <= 2'b01;
//        else
//            forward_B <= 2'b00;
//    end
//     always @ (*) begin
// //        // Initialize forwarding signals to 0 (no forwarding)
// //        forward_A = 2'b00;
// //        forward_B = 2'b00;
//         // Forwarding for source operand A
//         if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs)) begin
//             forward_A = 2'b10; // EX hazard
//         end else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rs) &&
//                      !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs))) begin
//             forward_A = 2'b01; // MEM hazard
//         end
        
//         // Forwarding for source operand B
//         if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt)) begin
//             forward_B = 2'b10; // EX hazard
//         end else if (MEM_WB_reg_write && (MEM_WB_rd != 0) && (MEM_WB_rd == ID_EX_rt) &&
//                      !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt))) begin
//             forward_B = 2'b01; // MEM hazard
//         end

//     end

     
// Forwarding logic for EX stage

     always @(*) begin
        // Initialize forwarding controls to no forwarding (00)
        forward_A = 2'b00;
        forward_B = 2'b00;
    
        // Check EX stage forwarding
        if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs)) begin
            forward_A = 2'b10;
        end
        if (EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt)) begin
            forward_B = 2'b10;
        end
    
        // Check MEM stage forwarding
        if (MEM_WB_reg_write && (MEM_WB_rd != 0) && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs)) && (MEM_WB_rd == ID_EX_rs)) begin
            forward_A = 2'b01;
        end
        if (MEM_WB_reg_write && (MEM_WB_rd != 0) && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rt)) && (MEM_WB_rd == ID_EX_rt)) begin
            forward_B = 2'b01;
        end
    end
    
    // Forwarding logic for branch
    always @(*) begin
        // Initialize branch forwarding controls to no forwarding (00)
        branch_forward_A = 2'b00;
        branch_forward_B = 2'b00;
    
        // Check EX stage forwarding for branches
        if (branch && EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == IF_ID_rs)) begin
            branch_forward_A = 2'b10;
        end
        if (branch && EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == IF_ID_rt)) begin
            branch_forward_B = 2'b10;
        end
    
        // Check MEM stage forwarding for branches
        if (branch && MEM_WB_reg_write && (MEM_WB_rd != 0) && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == IF_ID_rs)) && (MEM_WB_rd == IF_ID_rs)) begin
            branch_forward_A = 2'b01;
        end
        if (branch && MEM_WB_reg_write && (MEM_WB_rd != 0) && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == IF_ID_rt)) && (MEM_WB_rd == IF_ID_rt)) begin
            branch_forward_B = 2'b01;
        end
    end
    

endmodule
