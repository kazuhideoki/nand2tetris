// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/4/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel. When no key is pressed,
// the screen should be cleared.

// loopする
// key にゅうりょくされたらRAMに保存
// それをみてSCREENに反映 -> これも LOOPで表現

(LOOP1)

@i
M=0
@count
M=1000
@SCREEN
D=A
@s
M=D

// without key, goto LOOP1
@KBD
D=M
@LOOP1
D;JEQ

// fill
(LOOP2)

@i
D=M
@s
A=A+D
M=-1

@i
M=M+1
@count
M=M-1

// without key, goto LOOP1
@KBD
D=M
@LOOP1
D;JEQ
// @count
// D=M
// @LOOP1
// D;JEQ

@LOOP2
0;JMP
