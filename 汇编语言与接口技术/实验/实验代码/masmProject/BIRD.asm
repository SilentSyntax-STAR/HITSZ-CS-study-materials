; Experiment 4 - Flying Bird
; For MASM 5.0 in DOSBox (80x25 text mode)

.MODEL SMALL
.STACK 100H

.DATA
    BIRDCOL    DB 0       ; current column: 0..79
    BIRDCHAR   DB 76H     ; 'v', then 0C4H
    STARTTICK  DW 0       ; BIOS clock tick at delay start

.CODE
START:
    MOV AX, @DATA
    MOV DS, AX

    ; Set 80x25 color text mode and clear the screen.
    MOV AX, 0003H
    INT 10H

NEXT_COL:
    ; Move the cursor to row 12, current column.
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 12
    MOV DL, BIRDCOL
    INT 10H

    ; Draw one bird character at the cursor position.
    MOV AH, 09H
    MOV AL, BIRDCHAR
    MOV BH, 00H
    MOV BL, 0FH
    MOV CX, 1
    INT 10H

    ; Keep the character visible for about half a second.
    CALL DELAY_HALF

    ; Return to the same screen position.
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 12
    MOV DL, BIRDCOL
    INT 10H

    ; Erase the bird character by drawing a blank space.
    MOV AH, 09H
    MOV AL, ' '
    MOV BH, 00H
    MOV BL, 07H
    MOV CX, 1
    INT 10H

    ; Advance by one column, alternating 'v' and line glyph.
    INC BIRDCOL
    CMP BIRDCOL, 80
    JAE FINISH

    CMP BIRDCHAR, 76H
    JE USE_LINE
    MOV BIRDCHAR, 76H
    JMP NEXT_COL

USE_LINE:
    MOV BIRDCHAR, 0C4H
    JMP NEXT_COL

FINISH:
    MOV AX, 4C00H
    INT 21H

; Delay by 9 BIOS clock ticks (about 9/18.2 = 0.495 sec).
DELAY_HALF PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX

    MOV AH, 00H
    INT 1AH
    MOV STARTTICK, DX

WAIT_TICK:
    MOV AH, 00H
    INT 1AH
    MOV AX, DX
    SUB AX, STARTTICK
    CMP AX, 9
    JB WAIT_TICK

    POP DX
    POP CX
    POP AX
    RET
DELAY_HALF ENDP

END START
