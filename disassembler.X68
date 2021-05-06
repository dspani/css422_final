*-----------------------------------------------------------
* Title      : DASM
* Written by : Duncan Spani, Robin Seo, Jaeha Choi, Nicolas Feuchster
* Date       : Spring 2021
* Description: Disassembler Project, CSS 422
*-----------------------------------------------------------
    ORG    $1000
START:                  
    BRA MAIN ; START EXECUTION
    
GET_INSTRUCTION:        ; GET INSTRUCTION FROM USER
    LEA     INSTRUCTION_PROMPT, A1  ; LOAD PROMPT INTO A1
    MOVE.B  #14, D0                 ; LOAD 14 INTO D0
    TRAP    #15                     ; TRAP TASK 14, DISPLAY NULL TERM STRING
    
    LEA     ASCII_INSTRUCTION, A1 ; LOAD STARTING ADDRESS OF CURRENT INSTRUCTION
    MOVE.B  #2, D0
    TRAP    #15                     ; TRAP TASK 2, READ STRING FROM USER
    MOVE.W  D1, INSTRUCTION_LENGTH  ; MOVE STRING LENGTH TO D5

    RTS                             ; RETURN TO STACK ADDRESS

;-------------------------------------
; CONVERT ASCII INPUT STRING TO HEX
; ASCII NUMS 0-9 = 48-57 -- sub.b 48, val
; ASCII LETTERS A-F = 65-70 -- sub.b 55, val
;------------------------------------
ASCII_TO_HEX:
    LEA     ASCII_INSTRUCTION, A1 ; LOAD START OF CURRENT INSTRUCTION INTO A1
    MOVE.B  (A1), D1              ; MOVE INSTRUCTION BYTE TO D1
    MOVE.B  D1, D2

    

INPUT_ERROR:
    LEA     ERROR, A1
    MOVE.B  #15, D0
    TRAP    #15
    BRA     MAIN

MAIN:                               ; MAIN LOOP
    BSR     GET_INSTRUCTION
    BSR     ASCII_TO_HEX

    BRA     MAIN                    ; RESTART LOOP

* variables and constants
LF  EQU  $0A                        ;Line Feed
CR  EQU  $0D                        ;Carriage Return 

INSTRUCTION_PROMPT  DC.B    'ENTER HEX INSTRUCTION: ',0
ERROR               DC.B    'INPUT ERROR',CR,LF,0
INSTRUCTION_LENGTH  DS.B    1       ; DECLARE 1 BYTE FOR LENGTH
ASCII_INSTRUCTION   DS.W    10      ; DECLARE UP TO 5 WORDS FOR INSTRUCTION

    END    START        


*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
