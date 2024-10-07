// Instituto Tecnológico de Costa Rica
// EL-3310 Diseño de sistemas digitales
// Autor:       Juan José Montero Rodríguez
// Fecha:       26.08.2024
// Descripción: RISC-V CPU Testbench (Multicycle)

`timescale 1ns/1ps

module cpu_tb ();

    logic        clk;
    logic        rst;
    logic [31:0] read_data;
    logic [31:0] instruction;
    logic [31:0] program_counter;
    

    cpu cpu1 (
        .clk(clk),
        .rst(rst),
        .Result(read_data),
        .Instr(instruction),
        .PC(program_counter)
    );

    initial begin

        rst = 1;
        #10 rst = 0;

        repeat (100) begin
            @(posedge clk);
            $display("PC: %8h  Result: %8h  Instr: %8h", program_counter, read_data, instruction);
        end

        #100 $finish();

    end

    initial begin

        clk <= 0;
        forever #5 clk <= !clk;

    end

endmodule
