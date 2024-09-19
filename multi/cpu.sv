// Instituto Tecnológico de Costa Rica
// EL-3310 Diseño de sistemas digitales
// Autor:       Juan José Montero Rodríguez
// Fecha:       17.09.2024
// Descripción: RISC-V Multicycle CPU from Harris & Harris

`timescale 1ns/1ps

module cpu (
    input               clk,
    input               rst,
    output logic [31:0] Result
);

    // Data variables
    logic [31:0] PCNext;
    logic [31:0] PC;
    logic [31:0] Instr;
    logic [31:0] ImmExt;
    logic [31:0] regdata1;
    logic [31:0] A;
    logic [31:0] ALUResult;
    logic [31:0] ALUOut;
    logic [31:0] Adr;
    logic [31:0] ReadData;
    logic [31:0] Data;

    // Control variables
    logic        IRWrite;
    logic  [1:0] ImmSrc;
    logic  [2:0] ALUControl;
    logic        AdrSrc;

    assign dout = ALUOut;

    pc pc1(
        .clk    (clk),
        .rst    (rst),
        .PCNext (PCNext),
        .PC     (PC)
    );

    i_d_mem idm1(
        .clk   (clk),
        .rst   (rst),
        .WE    (),
        .RE    (1'b1),
        .A     (Adr),
        .WD    (),
        .RD    (ReadData)
    );

    reg32 reg_step1(
        .clk     (clk),
        .rst     (rst),
        .en      (IRWrite),
        .din     (ReadData),
        .dout    (Instr)
    );

    Extend ext1(
        .src    (ImmSrc),
        .A      (Instr),
        .Q      (ImmExt)
    );

    reg32 reg_step2(
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (regdata),
        .dout    (A)
    );

    register_bank (
        .clk    (clk),
        .rst    (rst),
        .WE3    (),
        .A1     (Instr[19:15]),
        .A2     (),
        .A3     (),
        .WD3    (),
        .RD1    (regdata1),
        .RD2    ()
    );

    ALU (
        .Ctrl   (ALUControl),
        .SrcA   (A),
        .SrcB   (ImmExt),
        .Result (ALUResult),
        .zero   ()
    );

    reg32 reg_step3(
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (ALUResult),
        .dout    (ALUOut)
    );

    mux32 mux_ram (
        .sel  (AdrSrc),
        .A    (PC),
        .B    (ALUOut),
        .Q    (Adr)
    );

    reg32 reg_step4(
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (ReadData),
        .dout    (Data)
    );

endmodule


// Program Counter
module pc ( 
    input               clk,
    input               rst,
    input        [31:0] PCNext,
    output logic [31:0] PC
);

    always_ff @ (posedge clk) begin
        if (rst) PC <= 32'h00400000; // text segment
        else PC <= PCNext;
    end

endmodule


// Register Bank
module register_bank (
    input clk,
    input rst,
    input WE3,
    input [4:0] A1,
    input [4:0] A2,
    input [4:0] A3,
    input [31:0] WD3,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    // array of static memory
    logic [31:0] mem[32];

    // reset logic
    int i;
    always_ff @(posedge clk) begin
        if (rst) for (i = 0; i<32; i++) mem[i] <= 0;
    end

    // write logic
    always_ff @ (posedge clk) begin
        if (WE3 & !rst) mem[A3] <= WD3;
    end

    // read logic (combinational)
    assign RD1 = (A1 == 0) ? 32'b0 : mem[A1];
    assign RD2 = (A2 == 0) ? 32'b0 : mem[A2];
    
endmodule


// Instruction and Data Memory
module i_d_mem (
    input               clk,
    input               rst,
    input               WE ,
    input               RE ,
    input        [31:0] A  ,
    input        [31:0] WD ,
    output logic [31:0] RD
);

    // associative array: dynamic memory
    logic [31:0] mem [logic [31:0]];

    // reset logic
    always_ff @(posedge clk) begin
        if (rst) begin
            mem.delete();

            // program in assembly
            RD[32'h00400000] = 32'h00600413; // addi x8, x0, 6
            RD[32'h00400004] = 32'h00400493; // addi x9, x0, 4
            RD[32'h00400008] = 32'h00940933; // add x18, x8, x9
            RD[32'h0040000C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400010] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400014] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400018] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040001C] = 32'h00500413; // addi x8, x0, 5
            RD[32'h00400020] = 32'h00500413; // addi x8, x0, 5
            RD[32'h00400024] = 32'h00200493; // addi x9, x0, 2
            RD[32'h00400028] = 32'h00940933; // add x18, x8, x9
            RD[32'h0040002C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400030] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400034] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400038] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040003C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400040] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400044] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400048] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040004C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400050] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400054] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400058] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040005C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400060] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400064] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400068] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040006C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400070] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400074] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400078] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040007C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400080] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400084] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400088] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040008C] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400090] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h00400094] = 32'h00940933; // add x18, x8, x9
            RD[32'h00400098] = 32'h409409B3; // sub x19, x8, x9
            RD[32'h0040009C] = 32'h00940933; // add x18, x8, x9
            RD[32'h004000A0] = 32'h409409B3; // sub x19, x8, x9
        end
    end

    // write logic
    always_ff @(posedge clk) begin
        if (WE & !rst) begin
            mem[A] = WD;
        end
    end

    // read logic (combinational)
    assign RD = (RE & !rst) ? mem[A] : 32'hDEADBEEF;

endmodule


module reg32 ( 
    input               clk,
    input               rst,
    input               en,
    input        [31:0] din,
    output logic [31:0] dout
);

    always_ff @ (posedge clk) begin
        if      (rst) dout <= 32'h00400000; // text segment
        else if (en)  dout <= din;
        else          dout <= dout;
    end

endmodule


// Sign extension
module Extend (
    input        [1:0]  src,
    input        [31:0] A,
    output logic [31:0] Q
);

    always_comb begin

        case (src)
            2'b00:   Q = {{20{A[31]}}, A[31:20]};                            // I-Type
            2'b01:   Q = {{20{A[31]}}, A[31:25], A[11:7]};                   // S-Type
            2'b10:   Q = {{19{A[31]}}, A[31], A[7],A[30:25], A[11:8], 1'b0}; // B-Type
            2'b11:   Q = {{12{A[31]}}, A[19:12], A[20], A[30:21], 1'b0};     // J-Type
            default: Q = 32'hDEADBEEF; // error
        endcase

    end

endmodule


// 32-bit ALU (Behavioral)
// Each operation needs to be replaced with proper hardware
module ALU (
    input        [2:0]  Ctrl,
    input        [31:0] SrcA,
    input        [31:0] SrcB,
    output logic [31:0] Result,
    output logic        zero
);

    always_comb begin

        case (Ctrl)
            3'b000:  Result = SrcA + SrcB;              // add
            3'b001:  Result = SrcA - SrcB;              // subtract
            3'b010:  Result = SrcA && SrcB;             // and
            3'b011:  Result = SrcA || SrcB;             // or
            3'b101:  Result = (SrcA < SrcB) ? 1 : 0;    // slt (set if less than)
            default: Result = 32'hDEADBEEF;             // error
        endcase

    end

    assign zero = (Result == 0) ? 1 : 0;

endmodule


module mux32 (
    input               sel,
    input        [31:0] A,
    input        [31:0] B,
    output logic [31:0] Q 
);

    assign Q = sel ? B : A;

endmodule