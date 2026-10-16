DATAS SEGMENT

    ; 有符号字节数组
    ARRAY     DB  -5, 0, 8, -1, 0, 12, -7, 3, 0, 9

    ; 统计结果
    POSCOUNT  DB  0       ; 正数个数
    NEGCOUNT  DB  0       ; 负数个数
    ZEROCOUNT DB  0       ; 零的个数

    MAXVAL    DB  ?       ; 最大值
    MINVAL    DB  ?       ; 最小值

DATAS ENDS


STACKS SEGMENT PARA STACK 'STACK'
    DW 64 DUP(?)
STACKS ENDS


CODES SEGMENT
    ASSUME CS:CODES, DS:DATAS, SS:STACKS

START:

    ; 初始化数据段 DS
    MOV AX, DATAS
    MOV DS, AX

    ; 用数组第一个元素初始化最大值和最小值
    MOV AL, ARRAY
    MOV MAXVAL, AL
    MOV MINVAL, AL

    ; SI 指向数组第一个元素
    ; CX = 数组元素个数
    MOV SI, 0
    MOV CX, 10


AGAIN:

    ; 取出当前数组元素
    MOV AL, ARRAY[SI]

    ; 判断正、负、零

    CMP AL, 0
    JG  IS_POSITIVE
    JL  IS_NEGATIVE

    ; AL = 0
    INC ZEROCOUNT
    JMP CHECK_MAX


IS_POSITIVE:

    INC POSCOUNT
    JMP CHECK_MAX


IS_NEGATIVE:

    INC NEGCOUNT


CHECK_MAX:

    ; 判断是否比当前最大值大

    CMP AL, MAXVAL
    JLE CHECK_MIN

    MOV MAXVAL, AL


CHECK_MIN:

    ; 判断是否比当前最小值小

    CMP AL, MINVAL
    JGE NEXT_ONE

    MOV MINVAL, AL


NEXT_ONE:

    INC SI
    LOOP AGAIN

    ; 返回 DOS

    MOV AH, 4CH
    INT 21H


CODES ENDS
END START