*-----------------------------------------------------------
* Title      : DASM
* Written by : Duncan Spani, Robin Seo, Jaeha Choi, Nicolas Feuchster
* Date       : Spring 2021
* Description: Disassembler Project, CSS 422
*-----------------------------------------------------------
    ORG    $1000   
START:
    ;BRA     RUN_TESTS              ; ENABLE THIS LINE FOR UNIT TESTING
    BSR     INPUT_START_ADDRESS
    BSR     INPUT_END_ADDRESS                
    BRA     MAIN    ; START DISASSEMBLY

RUN_TESTS:
    BSR     GET_BITS_TEST_1
    ;BSR     GET_BITS_TEST_2
    ;BSR     GET_BITS_TEST_3
    ;BSR     GET_BITS_TEST_4
    ;BSR     GET_BITS_TEST_5
    ;BSR     ASCII_TO_HEX_TEST_1
    ;BSR     ASCII_TO_HEX_TEST_2
    ;BSR     ASCII_TO_HEX_TEST_3
    ;BSR     ASCII_TO_HEX_TEST_4
    ;BSR     ASCII_TO_HEX_TEST_5
    SIMHALT

; TESTS ASCII_TO_HEX
ASCII_TO_HEX_TEST_1:
    MOVE.W  #$3939, TEST_VAR_1          ; LOADS "99" ASCII CHAR IN HEX TO TEST_VAR_1
    LEA     TEST_VAR_1, A1
    LEA     TEST_VAR_2, A2
    BSR     ASCII_TO_HEX                ; EXPECTED: 99
    CMP.W   #99, TEST_VAR_2
    ; TODO: ADD ASSERTION HERE
    RTS

ASCII_TO_HEX_TEST_2:
    MOVE.L  #$30393900, TEST_VAR_1      ; LOADS "099" ASCII CHAR IN HEX TO TEST_VAR_1
    LEA     TEST_VAR_1, A1
    LEA     TEST_VAR_2, A2
    BSR     ASCII_TO_HEX                ; EXPECTED: 09
    ; TODO: ADD ASSERTION HERE
    RTS

ASCII_TO_HEX_TEST_3:
    MOVE.L  #$31317070, TEST_VAR_1      ; LOADS "00FF" ASCII CHAR IN HEX TO TEST_VAR_1
    LEA     TEST_VAR_1, A1
    LEA     TEST_VAR_2, A2
    BSR     ASCII_TO_HEX                ; EXPECTED: 00FF
    ; TODO: ADD ASSERTION HERE
    RTS

ASCII_TO_HEX_TEST_4:
    MOVE.L  #$3942FFFF, TEST_VAR_1      ; LOADS "9B00" ASCII CHAR IN HEX TO TEST_VAR_1
    LEA     TEST_VAR_1, A1
    LEA     TEST_VAR_2, A2
    BSR     ASCII_TO_HEX                ; EXPECTED: 9B
    ; TODO: ADD ASSERTION HERE
    RTS

ASCII_TO_HEX_TEST_5:
    MOVE.W  #$5842, TEST_VAR_1          ; LOADS "XA" ASCII CHAR IN HEX TO TEST_VAR_1
    LEA     TEST_VAR_1, A1
    LEA     TEST_VAR_2, A2
    BSR     ASCII_TO_HEX                ; EXPECTED: INPUT ERROR
    ; TODO: ADD ASSERTION HERE
    RTS

GET_BITS_TEST_1:
    MOVE.W  #%0001000000000001, D1      ; LOAD HEX: 1001 (MOVE.B  D1, D0)
    MOVE.B  #0, D2                      ; START FROM 0
    MOVE.B  #16, D3                     ; GET 16 BITS OR A WORD
    BSR     GET_BITS                    ; EXPECTS D1: 1001
    RTS

GET_BITS_TEST_2:
    MOVE.W  #%0001000000000010, D1      ; LOAD HEX: 1002 (MOVE.B  D2, D0)
    MOVE.B  #0, D2                      ; START FROM 0
    MOVE.B  #4, D3                      ; GET 4 BITS OR A NYBBLE
    BSR     GET_BITS                    ; EXPECTS D1: 1
    RTS

GET_BITS_TEST_3:
    MOVE.W  #$1013, D1                  ; LOAD HEX: 1013
    MOVE.B  #8, D2                      ; START FROM 4
    MOVE.B  #4, D3                      ; GET 4 BITS OR A NYBBLE
    BSR     GET_BITS                    ; EXPECTS D1: 1
    RTS

GET_BITS_TEST_4:
    MOVE.W  #%1010101010101010, D1      ; LOAD HEX: AAAA
    MOVE.B  #10, D2                     ; START FROM 10
    MOVE.B  #1, D3                      ; GET 1 BIT
    BSR     GET_BITS                    ; EXPECTS D1: 1
    RTS

GET_BITS_TEST_5:
    MOVE.W  #$00FC, D1                  ; LOAD HEX: 00FC
    MOVE.B  #15, D2                     ; START FROM 15
    MOVE.B  #1, D3                      ; GET 1 BIT
    BSR     GET_BITS                    ; EXPECTS D1: 0
    RTS

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
; ** CONVERT ASCII INPUT STRING TO HEX
; ASCII NUMS 0-9 = 48-57 -- sub.b 48, val
; ASCII LETTERS A-F = 65-70 -- sub.b 55, val
; ** ARGUMENTS:
; A1: SOURCE ADDRESS
;   ADDRESS OF A DATA STORAGE THAT STORES NULL OR $FF TERMINATED ASCII VALUE
; A2: DESTINATION ADDRESS
;   ADDRESS OF A DATA STORAGE THAT STORES HEX VALUE OF THE SOURCE ASCII VALUE
; ** RETURNS:
; A2:
;   UPDATE VALUE OF DESTINATION ADDRESS DATA STORAGE TO STORE HEX VALUE OF THE PROVIDED ASCII CHAR 
;------------------------------------
ASCII_TO_HEX:
    MOVE.B  (A1)+, D1                ; MOVE FIRST BYTE TO D1
    MOVE.B  (A1)+, D2                ; MOVE NEXT BYTE TO D2
    MOVE.B  #0, D4                   ; SET COUNTER TO 0
    ;BSR     CONVERSION_LOOP
    BRA     CONVERSION_LOOP


CONVERSION_LOOP:
    CMP.B   #0, D1 
    BEQ     END_INSTRUCTION           ; BRANCH TO END ON NULL
    CMP.B   #$FF, D1
    BEQ     END_INSTRUCTION           ; END IF BYTE FF (NON-NULL TERMINATED)
    CMP.B   #47, D1
    BLT     INPUT_ERROR               ; ERROR IF VALUE LESS THAN 47
    CMP.B   #71, D1
    BGT     INPUT_ERROR               ; ERROR IF VALUES GREATER THAN 71
    CMP.B   #57, D1
    BLE     NUMBER                    ; NUMBER IF VALUE BETWEEN 48 AND 57
    CMP.B   #65, D1
    BGE     LETTER                    ; LETTER IF VALUE BETWEEN 65 AND 70
    ;RTS 
    BRA     INPUT_ERROR
    
COMBINE_BYTE:
    MOVE.B  #0, D4                  ; CLEAR D4
    MOVE.B  D5, (A2)                ; MOVE D5 INTO INSTRUCTION MEMORY
    MOVE.B  #0, D5                  ; CLEAR D5
    ADD.L   #1, A2                  ; INCREMENT A2 ADDRESS
    MOVE.B  (A1)+, D2               ; GRAB NEW VALUE FROM A1, PLACE IN D2
    BRA CONVERSION_LOOP

END_INSTRUCTION:
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
    ;BRA     MAIN                    ; RETURN TO MAIN (TODO: RETURN TO ORIGINAL LOCATION)
    RTS

**--------------GET ADDRESSING----------------**
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
**------------END GET ADDRESSING------------**
**--------------GET NYBBLE----------------**
;-------------------------------------
; ** GET FIRST NYBBLE
; ** ARGUMENTS:
; D1: SOURCE REGISTER
;   D1 STORES INSTRUCTION
; ** RETURNS:
; D1:
;   D1 SAVES TO FIRST_FOUR_NYBBLE
;------------------------------------

**------------------START OF APIs----------------** 
GET_FIRST_NYBBLE:           ; RETURN FIRST FOUR BITS 

    MOVE.W  #$F000, D2  ; mask = $F000
    AND.W   D2, D1
    
    LSR.W   #8, D1  
    LSR.W   #4, D1

    MOVE.B  D1, FIRST_FOUR_NYBBLE   

MATCH_INSTRUCTION:  ;match instruction and branching to the specifide instruction branch       
    MOVE.L  D7, D5
    CMP.W   #$4E75, D1              ; COMPARE TO CONSTANT RTS OP CODE
    BEQ     RTS
    
    MOVE.L  D7, D5
    CMP.W   #$4E71, D1              ; COMPARE TO CONSTANT NOP OP CODE
    BEQ     NOP
    
    MOVE.L  D7, D5
    AND.W   #%1100000000000000, D5
    CMP.W   #$0000, D2
    BEQ     MOVE
    
    MOVE.L  D7, D5
    AND.W   #%1111111111000000, D5
    CMP.W   #%0100111010000000, D5
    BEQ     JSR
    
    MOVE.L  D7, D5
    AND.W   #%1111101110000000, D5
    CMP.W   #%0100100010000000, D5
    BEQ     MOVEM
    
    MOVE.L  D7, D5
    AND.W   #%1111000111000000, D5
    CMP.W   #%0100000111000000, D5
    BEQ     LEA
    
    MOVE.L  D7, D5
    AND.W   #%1111111100000000, D5
    CMP.W   #%0100011000000000, D5
    BEQ     NOT
    
    MOVE.L  D7, D5
    AND.W   #%1111111100000000, D5
    CMP.W   #%0110110100000000, D5
    BEQ     BLT
    
    MOVE.L  D7, D5
    AND.W   #%1111111100000000, D5
    CMP.W   #%0110110000000000, D5
    BEQ     BGE
    
    MOVE.L  D7, D5
    AND.W   #%1111111100000000, D5
    CMP.W   #%0110011000000000, D5
    BEQ     BEQ
    
    MOVE.L  D7, D5
    AND.W   #%1111111100000000, D5
    CMP.W   #%0110000000000000, D5
    BEQ     BRA
    
    MOVE.L  D7, D5
    AND.W   #%1111000000000000, D5
    CMP.W   #%1000000000000000, D5
    BEQ     DIVU
    
    MOVE.L  D7, D5
    AND.W   #%1111000000000000, D5
    CMP.W   #%1001000000000000, D5
    BEQ     SUB
    
    MOVE.L  D7, D5
    AND.W   #%1111000111000000, D5
    CMP.W   #%1100000111000000, D5
    BEQ     MULS
    
    MOVE.L  D7, D5
    AND.W   #%1111000000000000, D5
    CMP.W   #%1100000000000000, D5
    BEQ     AND
    
    MOVE.L  D7, D5
    AND.W   #%1111000000000000, D5
    CMP.W   #%1101000000000000, D5
    BEQ     ADD
    
    ;CHANGE NAME FROM LSD1 AND LSD2 TO SOMETHING MORE SPECIFIC
    MOVE.L  D7, D5
    AND.W   #%1111111011000000, D5
    CMP.W   #%1110001011000000, D5
    BEQ     LSD_IMMEDIATE
    
    MOVE.L  D7, D5
    AND.W   #%1111000000011000, D5
    CMP.W   #%1110000000001000, D5
    BEQ     LSD_REGISTER
    
    ;CHANGE NAME FROM ASD1 AND ASD2 TO SOMETHING MORE SPECIFIC
    MOVE.L  D7, D5
    AND.W   #%1111111011000000, D5
    CMP.W   #%1110000011000000, D5
    BEQ     ASD_IMMEDIATE
    
    MOVE.L  D7, D5
    AND.W   #%1111000000011000, D5
    CMP.W   #%1110000000000000, D5
    BEQ     ASD_REGISTER
    
    ;BRANCH NO MATTER WHAT TO BCC, AS IT'S NOT VISIBLY UNIQUE TO MORTALS    
    BRA     BCC
      

**--------------GET BITS----------------**
;-------------------------------------
; ** GET N NUMBER OF BITS BASED X STARTING LOCATION
; ** REPLICATION OF "INT GETBITS(SHORT INSTRUCTION, INT START, INT END)"
; ** ARGUMENTS:
; D1: SOURCE INSTRCUTION
;   D1 STORES THE BASE WORD INSTRUCTION
; D2: STARTING LOCATION
;   X STARTING LOCATION FROM LEFT TO RIGHT IN BASE INSTRUCTION
; D3: NUMBER OF BITS TO GET
;   N NUMBER OF BITS TO GET STARTING FROM D2 STARTING LOCATION
; ** RETURNS:
; D1:
;   D1 CONTAINS ONLY THE BITS STARTING FROM X SHIFTED ALL THE WAY TO THE RIGHT
;------------------------------------
GET_BITS: 
	MOVE.W #16, D4                  ; MOVE WORD SIZE INTO D4
	SUB.W D3, D4                    ; GET NUM OF BITS AFTER IMPORTANT BITS
	
	MOVE.W D2, D5                   ; MOVE STARTING LOCATION TO D5
	MOVE.W D3, D6                   ; MOVE NUMBER OF BITS TO D6
	LEFT_SHIFT:
	CMP.W #0, D2                    ; COMPARE 0 TO STARTING LOCATION
	BEQ RIGHT_SHIFT                 ; BRANCH TO RIGHT SHIFT IS LEFT_SHIFT
	SUB.W #1, D2                    ; DECREMENT COUNTER BY 1
	LSL.W #1, D1                    ; LEFT SHIFT INSTRUCTION BY 1

	BRA LEFT_SHIFT                  ; RESTART LEFT SHIFT
	RIGHT_SHIFT:
	CMP.W #0, D4                    ; COMPARE 0 TO D4 REGISTER
	BEQ GET_BITS_END                ; IF 0 END BIT SHIFT
	SUB.W #1, D4                    ; DECREMENT D4 COUNTER BY 1
	LSR.W #1, D1                    ; RIGHT SHIFT INSTRUCTION BY 1
	BRA RIGHT_SHIFT                 ; RESTART RIGHT SHIFT
    GET_BITS_END:
    RTS                             ; HELPER FUNCTION
**------------------END OF APIs----------------**  


**------------------BEGIN MAIN LOOP----------------**  
MAIN:                               ; MAIN LOOP    

    BSR     GET_INSTRUCTION         ; RETURNS ASCII INSTRUCTION STARTING AT ASCII_INSTRUCTION ADDRESS
    LEA     ASCII_INSTRUCTION, A1   ; LOAD START OF CURRENT INSTRUCTION INTO A1
    LEA     INSTRUCTION, A2         ; LOAD DESTINATION 
    BSR     ASCII_TO_HEX            ; RETURNS INSTRUCTION AT INSTRUCTION ADDRESS
    LEA     INSTRUCTION, A1
    MOVE.W  (A1)+, D7               ; DEREFERENCE WORD INSTRUCTION
    BSR     MATCH_INSTRUCTION
    BSR     CLEAR_INSTRUCTION       ; CLEAR MEMORY OF INSTRUCTION
      
    BRA     MAIN                    ; RESTART LOOP
    SIMHALT
**------------------END MAIN LOOP----------------**  


CLEAR_INSTRUCTION:
    LEA     INSTRUCTION, A1
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    BRA     MAIN

**-----------BEGIN INSTRUCTION DISASSEMBLY----------**
; ** FOR THE FOLLOWING, THE INSTRUCTION MUST BE LOADED
; ** IN D7 FOR REMAINDER OF INSTRUCTION DECOMPOSITION
RTS:
    LEA     OPC_RTS, A1
    MOVE.B  #13, D0
    TRAP    #15                     ; PRINT RTS OP CODE
    BRA     CLEAR_INSTRUCTION
    
NOP:
    LEA     OPC_NOP, A1
    MOVE.B  #13, D0
    TRAP    #15                     ; PRINT NOP OP CODE
    BRA     CLEAR_INSTRUCTION

MOVE:
    BRA     CLEAR_INSTRUCTION
    
JSR:
    BRA     CLEAR_INSTRUCTION

MOVEM:
    BRA     CLEAR_INSTRUCTION

LEA:
    BRA     CLEAR_INSTRUCTION

NOT:
    BRA     CLEAR_INSTRUCTION

BLT:
    BRA     CLEAR_INSTRUCTION

BGE:
    BRA     CLEAR_INSTRUCTION

BEQ:
    BRA     CLEAR_INSTRUCTION

BRA:
    BRA     CLEAR_INSTRUCTION

DIVU:
    BRA     CLEAR_INSTRUCTION

SUB:
    BRA     CLEAR_INSTRUCTION

MULS:
    BRA     CLEAR_INSTRUCTION

AND:
    BRA     CLEAR_INSTRUCTION

ADD:
    BRA     CLEAR_INSTRUCTION

LSD_IMMEDIATE:
    BRA     CLEAR_INSTRUCTION

LSD_REGISTER:
    BRA     CLEAR_INSTRUCTION

ASD_IMMEDIATE:
    BRA     CLEAR_INSTRUCTION

ASD_REGISTER:
    BRA     CLEAR_INSTRUCTION

BCC:
    BRA     CLEAR_INSTRUCTION

**-----------END INSTRUCTION DISASSEMBLY----------**
MOVE_SIZE:
    
    ;LSL.L    #2,A2                 ;SHIFT LEFT BY 2 BITS TO GET RID OF FIRST 2 BITS
    ;LSR.L    #8,A2                 ;SHIFT RIGHT BY 8 WHERE WE ARE STORING THE INSTRUCTION
    ;LSR.L    #6,A2                 ;SHIFT RIGHT BY 6 WHERE WE ARE STORING THE INSTRUCTION
    
    ;CMP.B  #%00000001,A2           ;COMPARES HEX INSTRUCTION FOR THE BYTE VALUE OF MOVE
    ;BEQ    BYTE_SIZE               ;GOES TO BRANCH FOR BYTE SIZE

    ;CMP.B  #%00000011,A2           ;COMPARES HEX INSTRUCTION FOR THE BYTE VALUE OF MOVE
    ;BEQ    WORD_SIZE               ;GOES TO BRANCH FOR WORD SIZE
    
    ;CMP.B  #%00000010,A2           ;COMPARES HEX INSTRUCTION FOR THE BYTE VALUE OF MOVE
    ;BEQ    LONG_SIZE               ;GOES TO BRANCH FOR LONG SIZE

    
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
TEST_FAIL           DC.B    'ASSERT FAILED: ', 0           
TEST_SUCC           DC.B    'ASSERT SUCCESSFUL: ', 0

FIRST_FOUR_NYBBLE   DS.B    1       ; DECLARE 1 BYTE FOR LENGTH 
INSTRUCTION_LENGTH  DS.W    1       ; DECLARE 1 BYTE FOR LENGTH
ASCII_INSTRUCTION   DS.W    10      ; DECLARE UP TO 10 WORDS FOR ASCII INSTRUCTION
INSTRUCTION         DS.W    5       ; DECLARE UP TO 5 WORDS FOR HEX INSTRUCTION
START_ADDRESS       DS.L    1       ; DECLARE START ADDRESS
END_ADDRESS         DS.L    1       ; DECLARE END ADDRESS
TEST_VAR_1          DS.L    1       ; FOR TESTING          
TEST_VAR_2          DS.L    1       ; FOR TESTING
    END    START        









*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
