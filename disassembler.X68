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
    
    LEA     CURRENT_INSTRUCTION, A1 ; LOAD STARTING ADDRESS OF CURRENT INSTRUCTION
    MOVE.B  #2, D0
    TRAP    #15                     ; TRAP TASK 2, READ STRING FROM USER
    MOVE.W  D1, INSTRUCTION_LENGTH  ; MOVE STRING LENGTH TO D5
    
    RTS                             ; RETURN TO STACK ADDRESS

ASCII_TO_HEX:
    LEA     CURRENT_INSTRUCTION, A1 ; LOAD START OF CURRENT INSTRUCTION INTO A1
    ;;; TODO ;;;

MAIN:                   ; MAIN LOOP
    BSR     GET_INSTRUCTION
    

    SIMHALT             ; halt simulator

* variables and constants
INSTRUCTION_PROMPT  DC.B    'ENTER HEX INSTRUCTION: ',0
CURRENT_INSTRUCTION DS.W    5       ; DECLARE UP TO 5 WORDS FOR INSTRUCTION
INSTRUCTION_LENGTH  DS.B    1       ; DECLARE 1 BYTE FOR LENGTH

    END    START        

*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
