// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/4/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel. When no key is pressed,
// the screen should be cleared.

// without key preparation
(RESET1)

@i
M=0
@SCREEN
D=A
@s
M=D
@8192
D=A
@count
M=D

@LOOP1
0;JMP

(LOOP1)
// アドレスの設定
@i
D=M
@s
A=M
A=A+D
// 白くする
M=0


// アドレス値の差分インクリメント
@i
M=M+1
@count
M=M-1

// 完了チェック
@count
D=M
@FINISHLOOP1
D;JEQ

@LOOP1
0;JMP

(FINISHLOOP1)

@KBD
D=M
@RESET2
D;JNE

@FINISHLOOP1
0;JMP


(RESET2)
@i
M=0
@SCREEN
D=A
@s
M=D
@8192
D=A
@count
M=D

@LOOP2
0;JMP

(LOOP2)
// アドレスの設定
@i
D=M
@s
A=M
A=A+D
// 黒くする
M=-1


// アドレス値の差分インクリメント
@i
M=M+1
@count
M=M-1

// 完了チェック
@count
D=M
@FINISHLOOP2
D;JEQ

@LOOP2
0;JMP

(FINISHLOOP2)

@KBD
D=M
@RESET1
D;JEQ

@FINISHLOOP2
0;JMP
