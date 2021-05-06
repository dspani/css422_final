*-----------------------------------------------------------
* Title      : DASM
* Written by : Duncan Spani, Robin Seo, Jaeha Choi, Nicolas Feuchster
* Date       : Spring 2021
* Description: Disassembler Project, CSS 422
*-----------------------------------------------------------
    ORG    $1000
START:  
    BSR     INPUT_START_ADDRESS
    BSR     INPUT_END_ADDRESS                
    BRA MAIN    ; START DISASSEMBLY
    
**--------GET INSTRUCTION FROM USER---------**
GET_INSTRUCTION:        ; GET INSTRUCTION FROM USER
    LEA     INSTRUCTION_PROMPT, A1  ; LOAD PROMPT INTO A1
    MOVE.B  #14, D0                 ; LOAD 14 INTO D0
    TRAP    #15                     ; TRAP TASK 14, DISPLAY NULL TERM STRING
    
    LEA     ASCII_INSTRUCTION, A1   ; LOAD STARTING ADDRESS OF CURRENT INSTRUCTION
    MOVE.B  #2, D0
    TRAP    #15                     ; TRAP TASK 2, READ STRING FROM USER
    MOVE.W  D1, INSTRUCTION_LENGTH  ; MOVE STRING LENGTH TO D5

    RTS                             ; RETURN TO STACK ADDRESS

**--------------CONVERSION ASCII TO HEX LOGIC------------**
;-------------------------------------
; CONVERT ASCII INPUT STRING TO HEX
; ASCII NUMS 0-9 = 48-57 -- sub.b 48, val
; ASCII LETTERS A-F = 65-70 -- sub.b 55, val
; ** ARGUMENTS:
; ** SOURCE ADDRESS IN A1 **
; ** DESTINATION ADDRESS IN A2 **
;------------------------------------
ASCII_TO_HEX:
    ;LEA     ASCII_INSTRUCTION, A1   ; LOAD START OF CURRENT INSTRUCTION INTO A1
    ;LEA     INSTRUCTION, A2         ; WHERE END INSTRUCTION WILL LIE
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
    BEQ     END_INSTRUCTION         ; BRANCH TO INPUT ERROR IF NULL INSTRUCTION
    CMP.B   #47, D1
    BLT     INPUT_ERROR             ; ERROR IF VALUE LESS THAN 47
    CMP.B   #71, D1
    BGT     INPUT_ERROR             ; ERROR IF VALUE GREATER THAN 71
    CMP.B   #57, D1
    BLE     NUMBER                  ; NUMBER IF VALUE BETWEEN 48 AND 57
    CMP.B   #65, D1
    BGE     LETTER                  ; LETTER IF VALUE BETWEEN 65 AND 70
    BRA     INPUT_ERROR 

COMBINE_BYTE:
    MOVE.B  #0, D4                  ; CLEAR D4
    MOVE.B  D5, (A2)                ; MOVE D5 INTO INSTRUCTION MEMORY
    MOVE.B  #0, D5                  ; CLEAR D5
    ADD.L   #1, A2                  ; INCREMENT A2 ADDRESS
    MOVE.B  (A1)+, D2               ; GRAB NEW VALUE FROM A1, PLACE IN D2
    BRA CONVERSION_LOOP

END_INSTRUCTION:
    MOVE.L  (SP)+, D0
    RTS                             ; RETURN TO MAIN

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
**----------END CONVERSION ASCII TO HEX LOGIC------------**
  
INPUT_ERROR:
    LEA     ERROR, A1
    MOVE.B  #13, D0
    TRAP    #15                     ; PRINT ERROR MESSAGE ON INSTRUCTION ERROR
    BRA     MAIN                    ; RETURN TO MAIN

INPUT_START_ADDRESS:
    LEA     GET_START_ADDRESS, A1
    MOVE.B  #14, D0
    TRAP    #15                     ; PRINT COMMAND FOR STARTING ADDRESS
    MOVE.B  #2, D0                  ; READ A NUMBER FROM THE KEYBOARD
    TRAP    #15
    LEA     START_ADDRESS, A2
    BSR     ASCII_TO_HEX
    RTS
 
INPUT_END_ADDRESS:
    LEA     GET_END_ADDRESS, A1
    MOVE.B  #14, D0
    TRAP    #15                     ; PRINT COMMAND FOR STARTING ADDRESS
    MOVE.B  #2, D0                  ; READ A NUMBER FROM THE KEYBOARD
    TRAP    #15
    LEA     END_ADDRESS , A2
    BSR     ASCII_TO_HEX
    RTS
    
MAIN:                               ; MAIN LOOP
    BSR     GET_INSTRUCTION         ; RETURNS ASCII INSTRUCTION STARTING AT ASCII_INSTRUCTION ADDRESS
    BSR     ASCII_TO_HEX            ; RETURNS INSTRUCTION AT INSTRUCTION ADDRESS
    LEA     INSTRUCTION, A1
    MOVE.W  (A1)+, D1
    CMP.W   #$4E75, D1
    BEQ     RTS
    CMP.W   #$4E71, D1
    BEQ     NOP
    BRA     MAIN                    ; RESTART LOOP
    
**-----------BEGIN INSTRUCTION DISASSEMBLY----------**
RTS:
    LEA     OPC_RTS, A1
    MOVE.B  #13, D0
    TRAP    #15                     ; PRINT RTS OP CODE
    BRA     MAIN
    
NOP:
    LEA     OPC_NOP, A1
    MOVE.B  #13, D0
    TRAP    #15                     ; PRINT NOP OP CODE
    BRA     MAIN
**-----------END INSTRUCTION DISASSEMBLY----------**


**------------------VARIABLES---------------------**
LF  EQU  $0A                        ; Line Feed
CR  EQU  $0D                        ; Carriage Return 
**----------DISPLAY INSTRUCTION CONSTANTS---------**
OPC_NOP                    DC.L        'NOP',0      * Required OP CODE
OPC_MOVE                   DC.L        'MOVE',0     * Required OP CODE   
OPC_MOVEM                  DC.L        'MOVEM',0    * Required OP CODE
OPC_ADD                    DC.L        'ADD',0      * Required OP CODE
OPC_SUB                    DC.L        'SUB',0      * Required OP CODE
OPC_MULS                   DC.L        'MULS',0     * Required OP CODE
OPC_DIVU                   DC.L        'DIVU',0     * Required OP CODE
OPC_LEA                    DC.L        'LEA',0      * Required OP CODE
OPC_AND                    DC.L        'AND',0      * Required OP CODE
OPC_NOT                    DC.L        'NOT',0      * Required OP CODE
OPC_LSL                    DC.L        'LSL',0      * Required OP CODE
OPC_ASR                    DC.L        'ASR',0      * Required OP CODE
OPC_BLT                    DC.L        'BLT ',0     * Required OP CODE
OPC_BGE                    DC.L        'BGE ',0     * Required OP CODE
OPC_BEQ                    DC.L        'BEQ ',0     * Required OP CODE
OPC_JSR                    DC.L        'JSR ',0     * Required OP CODE
OPC_RTS                    DC.L        'RTS',0      * Required OP CODE
OPC_BRA                    DC.L        'BRA ',0     * Required OP CODE

VAR_ZERO                   DC.L        '0',0		* Symbol for printing OP code
VAR_ONE                    DC.L        '1',0		* Symbol for printing OP code
VAR_TWO                    DC.L        '2',0	    * Symbol for printing OP code
VAR_THREE                  DC.L        '3',0        * Symbol for printing OP code
VAR_FOUR                   DC.L        '4',0        * Symbol for printing OP code
VAR_FIVE                   DC.L        '5',0        * Symbol for printing OP code
VAR_SIX                    DC.L        '6',0        * Symbol for printing OP code
VAR_SEVEN                  DC.L        '7',0		* Symbol for printing OP code
VAR_EIGHT                  DC.L        '8',0        * Symbol for printing OP code
VAR_NINE                   DC.L        '9',0   	    * Symbol for printing OP code
VAR_A                      DC.L        'A',0        * Symbol for printing OP code
VAR_B                      DC.L        'B',0	    * Symbol for printing OP code
VAR_C                      DC.L        'C',0		* Symbol for printing OP code
VAR_D                      DC.L        'D',0        * Symbol for printing OP code
VAR_E                      DC.L        'E',0   	    * Symbol for printing OP code
VAR_F                      DC.L        'F',0		* Symbol for printing OP code

VAR_LONG                   DC.L        '.L ',0		* Symbol for printing OP code
VAR_WORD                   DC.L        '.W ',0		* Symbol for printing OP code
VAR_BYTE                   DC.L        '.B ',0		* Symbol for printing OP code

VAR_BINARY                 DC.L        '%',0		* Symbol used for formatting
VAR_HEX                    DC.L        '$',0		* Symbol used for formatting
VAR_NUM                    DC.L        '#',0		* Symbol used for formatting

VAR_OPEN_PAREN        	   DC.L        '(',0		* Symbol used for formatting
VAR_CLOSE_PAREN            DC.L        ')',0		* Symbol used for formatting
MOVEM_SLASH                DC.L        '/',0		* Symbol used for formatting
VAR_PLUS               	   DC.L        '+',0		* Symbol used for formatting
VAR_MINUS              	   DC.L        '-',0		* Symbol used for formatting
VAR_COMMA                  DC.L        ',',0		* Symbol used for formatting
VAR_SPACE                  DC.L        ' ',0		* Symbol used for formatting
VAR_TAB                    DC.L        '    ',0     * Symbol used for formatting
VAR_NEW_LINE               DC.B        '',CR,LF,0   * Symbol used for formatting
VAR_DATA_REG           	   DC.L        'D',0		* Symbol used for formatting
VAR_ADDR_REG        	   DC.L        'A',0		* Symbol used for formatting
VAR_COM                    DC.L        ',',0        * Symbol used for formatting
VAR_DATA                   DC.B        'DATA    ',0	* For Data Errors

ADDR_SEVEN                 DC.L        'A7,',0
ADDR_SIX                   DC.L        'A6,',0
ADDR_FIVE                  DC.L        'A5,',0
ADDR_FOUR                  DC.L        'A4,',0
ADDR_THREE                 DC.L        'A3,',0
ADDR_TWO                   DC.L        'A2,',0
ADDR_ONE                   DC.L        'A1,',0
ADDR_ZERO                  DC.L        'A0,',0

DATA_SEVEN                 DC.L        'D7,',0
DATA_SIX                   DC.L        'D6,',0
DATA_FIVE                  DC.L        'D5,',0
DATA_FOUR                  DC.L        'D4,',0
DATA_THREE                 DC.L        'D3,',0
DATA_TWO                   DC.L        'D2,',0
DATA_ONE                   DC.L        'D1,',0
DATA_ZERO                  DC.L        'D0,',0

INSTRUCTION_PROMPT  DC.B    'ENTER HEX INSTRUCTION: ',0
ERROR               DC.B    'INPUT ERROR',CR,LF,0
GET_START_ADDRESS   DC.B    'ENTER START ADDRESS IN HEX: ', 0
GET_END_ADDRESS     DC.B    'ENTER END ADDRESS IN HEX: ', 0
INSTRUCTION_LENGTH  DS.B    1       ; DECLARE 1 BYTE FOR LENGTH
ASCII_INSTRUCTION   DS.W    10      ; DECLARE UP TO 10 WORDS FOR ASCII INSTRUCTION
INSTRUCTION         DS.W    5       ; DECLARE UP TO 5 WORDS FOR HEX INSTRUCTION
START_ADDRESS       DS.L    1       ; DECLARE START ADDRESS
END_ADDRESS         DS.L    1       ; DECLARE END ADDRESS

    END    START        



*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
