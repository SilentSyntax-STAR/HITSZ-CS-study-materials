DATAS SEGMENT
    X DW 8000H, 0012H
    Y DW 9006H, 0010H
    Z DW ?, ?
DATAS ENDS

CODES SEGMENT
    ASSUME CS:CODES, DS:DATAS

START:
    MOV AX, DATAS
    MOV DS, AX

    ; X 的低16位 -> AX
    MOV AX, X

    ; X 的高16位 -> DX
    MOV DX, X+2

    ; 低16位相加
    ADD AX, Y

    ; 高16位相加，同时加上低16位产生的进位CF
    ADC DX, Y+2

    ; 减去十进制120
    SUB AX, 120

    ; 如果低16位减法产生借位，高16位也减1
    SBB DX, 0

    ; 保存结果
    MOV Z, AX
    MOV Z+2, DX

    MOV AH, 4CH
    INT 21H

CODES ENDS
END START