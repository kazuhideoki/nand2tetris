// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/4/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)
// The algorithm is based on repetitive addition.

// n(R1)
// @ = 0
// if (n == 0) goto END
// LOOP:
// R2 = R2 + a(R0)
// n = n - 1
// goto LOOP
// END:

// define result var
@sum
M=0
// define acc from R0
@R0
D=M
@acc
M=D
// define i as counter
@R1
D=M
@i
M=D

(LOOP)

// i == R1 -> goto STOP, else -> LOOP
@i
D=M
@STOP
D;JEQ

// sum + acc
@sum
D=M
@acc
D=D+M
@sum
M=D

// decrement i
@i
M=M-1

@LOOP
0;JMP

(STOP)

// save sum to R2
@sum
D=M
@R2
M=D

@END
0;JMP

(END)
@END
0;JMP
