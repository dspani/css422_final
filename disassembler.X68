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

**--------------CONVERSION LOGIC------------**
;-------------------------------------
; CONVERT ASCII INPUT STRING TO HEX
; ASCII NUMS 0-9 = 48-57 -- sub.b 48, val
; ASCII LETTERS A-F = 65-70 -- sub.b 55, val
;------------------------------------
ASCII_TO_HEX:
    LEA     ASCII_INSTRUCTION, A1   ; LOAD START OF CURRENT INSTRUCTION INTO A1
    LEA     INSTRUCTION, A2
    MOVE.W  (A1)+, D1               ; MOVE INSTRUCTION BYTE TO D1
    MOVE.W  D1, D2
    BSR     SPLIT_VALS              ; SPLIT VALUE INTO 2 SEPERATE BYTES
    MOVE.B  #0, D4
    BSR     CONVERSION_LOOP
    
SPLIT_VALS:
    LSR.L   #8, D1                  ; SHIFT LAST BYTE OUT OF D1
    LSL.L   #8, D2                  
    LSL.L   #8, D2
    LSL.L   #8, D2                  ; SHIFT FIRST BYTE OUT OF D2
    LSR.L   #8, D2
    LSR.L   #8, D2
    LSR.L   #8, D2                  ; RETURN D2 TO FRONT OF REGISTER
    RTS

CONVERSION_LOOP:
    CMP.B   #0, D1 
    BEQ     END_INSTRUCTION           ; BRANCH TO INPUT ERROR IF NULL INSTRUCTION
    CMP.B   #47, D1
    BLT     INPUT_ERROR               ; ERROR IF VALUE LESS THAN 47
    CMP.B   #71, D1
    BGT     INPUT_ERROR               ; ERROR IF VALUES GREATER THAN 71
    CMP.B   #57, D1
    BLE     NUMBER                    ; NUMBER IF VALUE BETWEEN 48 AND 57
    CMP.B   #65, D1
    BGE     LETTER                    ; LETTER IF VALUE BETWEEN 65 AND 70
    RTS 

COMBINE_BYTE:
    MOVE.B  #0, D4                  ; CLEAR D4
    MOVE.B  D5, (A2)                ; MOVE D5 INTO INSTRUCTION MEMORY
    MOVE.B  #0, D5                  ; CLEAR D5
    ADD.L   #1, A2                  ; INCREMENT A2 ADDRESS
    MOVE.B  (A1)+, D2               ; GRAB NEW VALUE FROM A1, PLACE IN D2
    BRA CONVERSION_LOOP

END_INSTRUCTION:
    BRA INSTRUCTION_DONE            ; RETURN TO MAIN

NUMBER:
    SUB.B   #48, D1                 ; CONVERT ASCII NUM TO HEX VALUE
    LSL.B   #4, D5                  ; LEFT SHIFT D5
    ADD.B   D1, D5                  ; MOVE D1 INTO D5
    MOVE.B  D2, D1                  ; QUEUE D2 INTO D1 FOR CONVERSION
    ADD.B   #1, D4                  ; INCREMENT COUNTER IN D4
    CMP.B   #2, D4                  
    BEQ     COMBINE_BYTE            ; BRANCH IF COUNTER IS 2
    MOVE.B  (A1)+, D2               ; DEREFERENCE NEW VALUE AND PLACE INTO D2
    BRA     CONVERSION_LOOP
    
LETTER:
    SUB.B   #55, D1                 ; CONVERT ASCII NUM TO HEX VALUE
    LSL.B   #4, D5                  ; LEFT SHIFT D5
    ADD.B   D1, D5                  ; MOVE D1 INTO D5
    MOVE.B  D2, D1                  ; QUEUE D2 INTO D1 FOR CONVERSION
    ADD.B   #1, D4                  ; INCREMENT COUNTER IN D4
    CMP.B   #2, D4                  
    BEQ     COMBINE_BYTE            ; BRANCH IF COUNTER IS 2
    MOVE.B  (A1)+, D2               ; DEREFERENCE NEW VALUE AND PLACE INTO D2
    BRA     CONVERSION_LOOP
    
    
INPUT_ERROR:
    LEA     ERROR, A1
    MOVE.B  #13, D0
    TRAP    #15                     ; PRINT ERROR MESSAGE ON INSTRUCTION ERROR
    BRA     MAIN                    ; RETURN TO MAIN

MAIN:                               ; MAIN LOOP
    BSR     GET_INSTRUCTION
    BSR     ASCII_TO_HEX
    INSTRUCTION_DONE:
    BRA     MAIN                    ; RESTART LOOP

* variables and constants
LF  EQU  $0A                        ;Line Feed
CR  EQU  $0D                        ;Carriage Return 

INSTRUCTION_PROMPT  DC.B    'ENTER HEX INSTRUCTION: ',0
ERROR               DC.B    'INPUT ERROR',CR,LF,0
INSTRUCTION_LENGTH  DS.B    1       ; DECLARE 1 BYTE FOR LENGTH
ASCII_INSTRUCTION   DS.W    10      ; DECLARE UP TO 10 WORDS FOR ASCII INSTRUCTION
INSTRUCTION         DS.W    5       ; DECLARE UP TO 5 WORDS FOR HEX INSTRUCTION

    END    START        


*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
