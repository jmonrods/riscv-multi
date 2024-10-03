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
    logic [31:0] regdata2;
    logic [31:0] A;
    logic [31:0] ALUResult;
    logic [31:0] ALUOut;
    logic [31:0] Adr;
    logic [31:0] WriteData;
    logic [31:0] ReadData;
    logic [31:0] Data;
    logic [31:0] SrcA;
    logic [31:0] SrcB;
    logic [31:0] OldPC;

    // Control variables
    logic        IRWrite;
    logic  [1:0] ImmSrc;
    logic  [2:0] ALUControl;
    logic        AdrSrc;
    logic  [1:0] ResultSrc;
    logic        RegWrite;
    logic  [1:0] ALUSrcA;
    logic  [1:0] ALUSrcB;
    logic        MemWrite;


    pc pc1(
        .clk    (clk),
        .rst    (rst),
        .PCNext (PCNext),
        .PC     (PC)
    );

    assign PCNext = Result;

    mux32_4 mux_pc_1 (
        .sel  (ALUSrcA),
        .A    (PC)     ,
        .B    (OldPC)  ,
        .C    (A)      ,
        .D    (0)      ,
        .Q    (SrcA)
    );

    mux32_4 mux_pc_2 (
        .sel (ALUSrcB),
        .A   (WriteData),
        .B   (ImmExt),
        .C   (32'h00000004),
        .D   (0),
        .Q   (SrcB)
    );

    i_d_mem idm1(
        .clk   (clk),
        .rst   (rst),
        .WE    (MemWrite),
        .RE    (1'b1),
        .A     (Adr),
        .WD    (WriteData),
        .RD    (ReadData)
    );

    reg32 reg_step1a(
        .clk     (clk),
        .rst     (rst),
        .en      (IRWrite),
        .din     (ReadData),
        .dout    (Instr)
    );

    reg32 reg_step1b(
        .clk     (clk),
        .rst     (rst),
        .en      (IRWrite),
        .din     (PC),
        .dout    (OldPC)
    );

    Extend ext1(
        .src    (ImmSrc),
        .A      (Instr),
        .Q      (ImmExt)
    );

    reg32 reg_step2a (
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (regdata1),
        .dout    (A)
    );

    reg32 reg_step2b (
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (regdata2),
        .dout    (WriteData)
    );

    register_bank rb1 (
        .clk    (clk),
        .rst    (rst),
        .WE3    (RegWrite),
        .A1     (Instr[19:15]),
        .A2     (Instr[24:20]),
        .A3     (Instr[11:7]),
        .WD3    (Result),
        .RD1    (regdata1),
        .RD2    (regdata2)
    );

    ALU alu1 (
        .Ctrl   (ALUControl),
        .SrcA   (SrcA),
        .SrcB   (SrcB),
        .Result (ALUResult),
        .zero   ()
    );

    reg32 reg_step3 (
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (ALUResult),
        .dout    (ALUOut)
    );

    mux32 mux_ram (
        .sel  (AdrSrc),
        .A    (PC),
        .B    (Result),
        .Q    (Adr)
    );

    reg32 reg_step4 (
        .clk     (clk),
        .rst     (rst),
        .en      (1'b1),
        .din     (ReadData),
        .dout    (Data)
    );
    
    mux32_4 mux_result (
        .sel (ResultSrc),
        .A   (ALUOut),
        .B   (Data),
        .C   (ALUResult),
        .D   (0),
        .Q   (Result)
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

    // write logic
    int i;
    always_ff @(posedge clk) begin
        if (rst) for (i = 0; i<32; i++) mem[i] <= 0;
        else if (WE3) mem[A3] <= WD3;
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
            mem[32'h00400000] = 32'h00600413; // addi x8, x0, 6
            mem[32'h00400004] = 32'h00400493; // addi x9, x0, 4
            mem[32'h00400008] = 32'h00940933; // add x18, x8, x9
            mem[32'h0040000C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400010] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400014] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400018] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040001C] = 32'h00500413; // addi x8, x0, 5
            mem[32'h00400020] = 32'h00500413; // addi x8, x0, 5
            mem[32'h00400024] = 32'h00200493; // addi x9, x0, 2
            mem[32'h00400028] = 32'h00940933; // add x18, x8, x9
            mem[32'h0040002C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400030] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400034] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400038] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040003C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400040] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400044] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400048] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040004C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400050] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400054] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400058] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040005C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400060] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400064] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400068] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040006C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400070] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400074] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400078] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040007C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400080] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400084] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400088] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040008C] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400090] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h00400094] = 32'h00940933; // add x18, x8, x9
            mem[32'h00400098] = 32'h409409B3; // sub x19, x8, x9
            mem[32'h0040009C] = 32'h00940933; // add x18, x8, x9
            mem[32'h004000A0] = 32'h409409B3; // sub x19, x8, x9
        end
        else
        begin // write logic
            if (WE) begin
                mem[A] = WD;
            end
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


module mux32_4 (
    input         [1:0] sel,
    input        [31:0] A,
    input        [31:0] B,
    input        [31:0] C,
    input        [31:0] D,
    output logic [31:0] Q 
);

    always_comb begin
        case (sel)
            2'b00: Q = A;
            2'b01: Q = B;
            2'b10: Q = C;
            2'b11: Q = D;
            default: Q = 32'hDEADBEEF;
        endcase
    end

endmodule


module control_unit (
    input              rst,
    input              clk,
    input        [6:0] op,
    input        [2:0] funct3,
    input              funct7_bit5,
    input              zero,
    output logic       PCWrite,
    output logic       AdrSrc,
    output logic       MemWrite,
    output logic       IRWrite,
    output logic [1:0] ResultSrc,
    output logic [2:0] ALUControl,
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic [1:0] ImmSrc,
    output logic       RegWrite
);

    logic        Branch;
    logic        PCUpdate;
    logic  [1:0] ALUop;

    assign PCWrite = (PCUpdate | (zero & Branch));


    main_fsm fsm1(
        .rst        (rst),
        .clk        (clk),
        .op         (op),
        .Branch     (Branch),
        .PCUpdate   (PCUpdate),
        .RegWrite   (RegWrite),
        .MemWrite   (MemWrite),
        .IRWrite    (IRWrite),
        .ResultSrc  (ResultSrc),
        .ALUSrcA    (ALUSrcA),
        .ALUSrcB    (ALUSrcB),
        .AdrSrc     (AdrSrc),
        .ALUop      (ALUop)
    );

    alu_decoder aludec1(
        .ALUOp       (ALUop),
        .funct3      (funct3),
        .op_bit5     (op[5]),
        .funct7_bit5 (funct7_bit5),
        .ALUControl  (ALUControl)
    );

    instr_decoder instrdec1(
        .op         (op),
        .ImmSrc     (ImmSrc)
    );

endmodule


module main_fsm(
    input              rst,
    input              clk,
    input        [6:0] op,
    output logic       Branch,
    output logic       PCUpdate,
    output logic       MemWrite,
    output logic       RegWrite,
    output logic       IRWrite,
    output logic [1:0] ResultSrc,
    output logic [1:0] ALUSrcA,
    output logic [1:0] ALUSrcB,
    output logic       AdrSrc,
    output logic [1:0] ALUop
);

    typedef enum {S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10} State;

    State current_state;
    State next_state;

    always_ff @(posedge clk) begin

        if (rst) current_state <= S0;
        else begin
            case (current_state)
                S0:
                begin : Fetch 
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b1;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b1;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b10;
                    ALUSrcA    <= 2'b00;
                    ALUSrcB    <= 2'b10;
                    ALUop      <= 2'b00;
                    next_state <= S1;
                end : Fetch
                S1:
                begin : Decode
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b01;
                    ALUSrcB    <= 2'b01;
                    ALUop      <= 2'b00;
                    case (op)
                        7'b0000011: next_state <= S2;  // lw
                        7'b0100011: next_state <= S2;  // sw
                        7'b0110011: next_state <= S6;  // R-type
                        7'b0010011: next_state <= S8;  // I-type
                        7'b1101111: next_state <= S9;  // jal
                        7'b1100011: next_state <= S10; // beq
                    endcase
                end : Decode
                S2:
                begin : MemAdr
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b10;
                    ALUSrcB    <= 2'b01;
                    ALUop      <= 2'b00;
                    case (op)
                        7'b0000011: next_state <= S3; // lw
                        7'b0100011: next_state <= S5; // sw
                    endcase
                end : MemAdr
                S3:
                begin : MemRead
                    AdrSrc     <= 1'b1;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b00;
                    ALUSrcB    <= 2'b00;
                    ALUop      <= 2'b00;
                    next_state <= S4;
                end : MemRead
                S4:
                begin : MemWB
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b1;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b01;
                    ALUSrcA    <= 2'b00;
                    ALUSrcB    <= 2'b00;
                    ALUop      <= 2'b00;
                    next_state <= S0;
                end : MemWB
                S5: 
                begin : S5_MemWrite
                    AdrSrc     <= 1'b1;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b1;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b00;
                    ALUSrcB    <= 2'b00;
                    ALUop      <= 2'b00;
                    next_state <= S0;
                end : S5_MemWrite
                S6: 
                begin : ExecuteR
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b10;
                    ALUSrcB    <= 2'b00;
                    ALUop      <= 2'b10;
                    next_state <= S7;
                end : ExecuteR
                S7: 
                begin : ALUWB
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b1;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b00;
                    ALUSrcB    <= 2'b00;
                    ALUop      <= 2'b00;
                    next_state <= S0;
                end : ALUWB
                S8: 
                begin : ExecuteI
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b10;
                    ALUSrcB    <= 2'b01;
                    ALUop      <= 2'b10;
                    next_state <= S7;
                end : ExecuteI
                S9: 
                begin : JAL
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b0;
                    PCUpdate   <= 1'b1;
                    RegWrite   <= 1'b0;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b01;
                    ALUSrcB    <= 2'b10;
                    ALUop      <= 2'b00;
                    next_state <= S7;
                end : JAL
                S10: 
                begin : BEQ
                    AdrSrc     <= 1'b0;
                    IRWrite    <= 1'b0;
                    Branch     <= 1'b1;
                    PCUpdate   <= 1'b0;
                    RegWrite   <= 1'b1;
                    MemWrite   <= 1'b0;
                    ResultSrc  <= 2'b00;
                    ALUSrcA    <= 2'b10;
                    ALUSrcB    <= 2'b00;
                    ALUop      <= 2'b01;
                    next_state <= S0;
                end : BEQ
            endcase
        end
    end

    always_ff @(posedge clk) current_state <= next_state;

endmodule : main_fsm


module alu_decoder (
    input              ALUOp,
    input              funct3,
    input              op_bit5,
    input              funct7_bit5,
    output logic [2:0] ALUControl
);

    always_comb begin

        casex ({ALUOp,funct3,op_bit5,funct7_bit5})
            7'b00xxxxx: ALUControl = 3'b000; // lw, sw
            7'b01xxxxx: ALUControl = 3'b001; // beq
            7'b1000000: ALUControl = 3'b000; // add
            7'b1000001: ALUControl = 3'b000; // add
            7'b1000010: ALUControl = 3'b000; // add
            7'b1000011: ALUControl = 3'b001; // sub
            7'b10010xx: ALUControl = 3'b101; // slt
            7'b10110xx: ALUControl = 3'b011; // or
            7'b10111xx: ALUControl = 3'b010; // and
            default:    ALUControl = 3'b000;
        endcase

    end

endmodule : alu_decoder


module instr_decoder(
    input        [6:0] op,
    output logic [1:0] ImmSrc
);

    always_comb begin

        case (op)
            3:       ImmSrc = 2'b00; // lw
            35:      ImmSrc = 2'b01; // sw
            51:      ImmSrc = 2'b00; // R-type
            99:      ImmSrc = 2'b10; // beq
            default: ImmSrc = 2'b00; // not used
        endcase

    end

endmodule : instr_decoder

