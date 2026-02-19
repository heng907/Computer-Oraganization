`timescale 1ns / 1ps
// <your student id>
//111550129
/* checkout FIGURE 4.7 */
module reg_file (
    input         clk,          // clock
    input         rstn,         // negative reset
    input  [ 4:0] read_reg_1,   // Read Register 1 (address)
    input  [ 4:0] read_reg_2,   // Read Register 2 (address)
    input         reg_write,    // RegWrite: write data when posedge clk
    input  [ 4:0] write_reg,    // Write Register (address)
    input  [31:0] write_data,   // Write Data
    output [31:0] read_data_1,  // Read Data 1
    output [31:0] read_data_2   // Read Data 2
);

    /* [step 1] How many bits per register? How many registers does MIPS have? */
    reg [31:0] registers[0:31];  // do not change its name

    /* [step 2] Read Registers */
    /* Remember to check whether register number is zero */
    assign read_data_1 = (read_reg_1 != 5'b0) ?  registers[read_reg_1] : 32'b0;
    assign read_data_2 = (read_reg_2 != 5'b0) ? registers[read_reg_2] : 32'b0;

    /** Sequential Logic
     * `posedge clk` means that this block will execute when clk changes from 0 to 1 (positive edge trigger).
     * `negedge rstn` vice versa.
     * https://www.chipverify.com/verilog/verilog-always-block
     */
    /* [step 3] Write Registers */
    integer i;
    always @(posedge clk) begin
        if (!rstn) begin
            // This will clear all registers including register 0 on reset.
            // For SystemVerilog, you could use `registers <= '{default:0}` for a cleaner syntax
//            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write && (write_reg != 5'b0)) begin
            // Register 0 is not written to, as per MIPS convention
            registers[write_reg] <= write_data;
        end
    end

    /* [step 4] Reset Registers (wordy in Verilog, how about System Verilog?) */
    integer i;
    always @(negedge rstn) begin
//        integer i;
        for (i=0; i < 32; i = i + 1) begin
            registers[i] <= 32'b0;
        end
    end

endmodule
