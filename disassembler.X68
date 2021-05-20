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
    MOVE.L  (START_ADDRESS), A6
    BSR     INPUT_END_ADDRESS                
    BRA     MAIN    ; START DISASSEMBLY

RUN_TESTS:
    BSR     MATCH_INSTRUCTION_TEST_1
    BSR     MATCH_INSTRUCTION_TEST_2
    ;BSR     GET_BITS_TEST_1
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

; TESTS MATCH_INSTRUCTION

; TESTS RTS
MATCH_INSTRUCTION_TEST_1:
    MOVE.W  #$4E75, D7                  ; LOAD RTS HEX (4E75) TO D7
    BSR     MATCH_INSTRUCTION           ; EXPECTS D7: 0, CONSOLE: RTS

MATCH_INSTRUCTION_TEST_2:
    MOVE.L  #$4E75, D7                  ; LOAD RTS HEX (4E75) TO D7
    BSR     MATCH_INSTRUCTION           ; EXPECTS D7: 0, CONSOLE: RTS

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

; TESTS GET_BITS
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
    BSR     CLEAR_INSTRUCTION_MEMORY
    BRA     MAIN

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
    CMP.W   #$4E75, D5              ; COMPARE TO CONSTANT RTS OP CODE
    BEQ     RTS
    
    MOVE.L  D7, D5
    CMP.W   #$4E71, D5              ; COMPARE TO CONSTANT NOP OP CODE
    BEQ     NOP
    
    MOVE.L  D7, D5
    AND.W   #%1100000000000000, D5
    CMP.W   #$0000, D5
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
    CMP.W   #%0110011100000000, D5
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
    
    MOVE.L  D7, D5
    AND.W   #%1111111011000000, D5
    CMP.W   #%1110001011000000, D5
    BEQ     LSD_IMMEDIATE
    
    MOVE.L  D7, D5
    AND.W   #%1111000000011000, D5
    CMP.W   #%1110000000001000, D5
    BEQ     LSD_REGISTER
    
    MOVE.L  D7, D5
    AND.W   #%1111111011000000, D5
    CMP.W   #%1110000011000000, D5
    BEQ     ASD_IMMEDIATE
    
    MOVE.L  D7, D5
    AND.W   #%1111000000011000, D5
    CMP.W   #%1110000000000000, D5
    BEQ     ASD_REGISTER
    
    ;BRANCH NO MATTER WHAT TO INVALID IF INSTRUCTION DOES NOT MATCH   
    BRA     INVALID
      

**--------------GET BITS----------------**
;-------------------------------------
; ** GET N NUMBER OF BITS BASED X STARTING LOCATION
; ** REPLICATION OF "INT GETBITS(SHORT INSTRUCTION, INT START, INT END)"
; ** ARGUMENTS:
; D1: SOURCE INSTRCUTION
;   D1 STORES THE BASE WORD INSTRUCTION
; D2: STARTING LOCATION
;   X STARTING LOCATION FROM LEFT TO RIGHT OF BASE INSTRUCTION STARTING FROM 0
; D3: NUMBER OF BITS TO GET
;   N NUMBER OF BITS TO GET STARTING FROM D2 STARTING LOCATION STARTING FROM 1
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

    ;BSR     GET_INSTRUCTION         ; RETURNS ASCII INSTRUCTION STARTING AT ASCII_INSTRUCTION ADDRESS
    ;LEA     ASCII_INSTRUCTION, A1   ; LOAD START OF CURRENT INSTRUCTION INTO A1
    ;LEA     INSTRUCTION, A2         ; LOAD DESTINATION 
    ;BSR     ASCII_TO_HEX            ; RETURNS INSTRUCTION AT INSTRUCTION ADDRESS
    ;LEA     INSTRUCTION, A1
    MOVE.L  (END_ADDRESS), A5
    CMP.L   A5, A6
    BGE     END_DISASSEMBLY         ; END IF CURRENT ADDRESS GREATER OR EQUAL TO END ADDRESS
    MOVE.W  (A6)+, D7               ; DEREFERENCE WORD INSTRUCTION FROM POINTER TO CURRENT INSTRUCTION (A6)
    CMP.W   #$FFFF, D7
    BEQ     END_DISASSEMBLY         ; END IF INSTRUCTION = #$FFFF
    BSR     MATCH_INSTRUCTION
    BSR     CLEAR_INSTRUCTION_MEMORY       ; CLEAR MEMORY OF INSTRUCTION
      
    BRA     MAIN                    ; RESTART LOOP
    SIMHALT
**------------------END MAIN LOOP----------------**  
END_DISASSEMBLY:
    SIMHALT

CLEAR_INSTRUCTION_MEMORY:           ; CLEAR ALL PREVIOUSLY USED MEMORY
    LEA     INSTRUCTION, A1
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.B  #$FF, SIZE
    MOVE.B  #$FF, SIZE_TYPE
    MOVE.B  #$FF, FIRST_FOUR_NYBBLE
    MOVE.B  #$FF, DESTINATION_MODE
    MOVE.B  #$FF, DESTINATION_XN
    MOVE.B  #$FF, SOURCE_MODE
    MOVE.B  #$FF, SOURCE_XN
    MOVE.B  #$FF, DIRECTION
    MOVE.B  #$FF, ROTATION
    MOVE.B  #$FF, DISPLACEMENT
    LEA     ASCII_INSTRUCTION, A1
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    MOVE.W  #$0000, (A1)+
    CLR.L   D0
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D4
    CLR.L   D5
    CLR.L   D6
    CLR.L   D7
    RTS

**-----------BEGIN INSTRUCTION DISASSEMBLY----------**
; ** FOR THE FOLLOWING, THE INSTRUCTION MUST BE LOADED
; ** IN D7 FOR REMAINDER OF INSTRUCTION DECOMPOSITION
RTS:
    LEA     OPC_RTS, A1
    MOVE.B  #14, D0
    TRAP    #15                     ; PRINT RTS OP CODE
    BSR     PRINT_NEWLINE
    BSR     CLEAR_INSTRUCTION_MEMORY
    BRA     MAIN
    
NOP:
    LEA     OPC_NOP, A1
    MOVE.B  #14, D0
    TRAP    #15                     ; PRINT NOP OP CODE
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

MOVE:
    ** GET SIZE 3**
    MOVE.B  #3, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #2, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET DESTINATION Xn **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET DESTINATION MODE **
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_MODE
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN

    ** PRINT INSTRUCTION **
    LEA     OPC_MOVE, A1
    BSR     PRINT_OPCODE
    BSR     PRINT_SIZE3
    BSR     GET_SOURCE_MODE
    BSR     PRINT_COMMA
    BSR     GET_DEST_MODE
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY
    
JSR:
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_JSR, A1
    BSR     PRINT_OPCODE
    BSR     GET_SOURCE_MODE
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

MOVEM:                                                          
    ** GET DIRECTION **
    ** REGISTER TO MEMORY (0) OR MEMORY TO REGISTER (1)**
    MOVE.W  D7, D1
    MOVE.B  #5, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SIZE 2**
    MOVE.B  #2, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #9, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_MOVEM, A1
    BSR     PRINT_OPCODE
    BSR     PRINT_SIZE2
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

LEA:
    ** DESTINATION ALWAYS ADDRESS REGISTER **
    ** GET DESTINATION An **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_LEA, A1
    BSR     PRINT_OPCODE
    BSR     GET_SOURCE_MODE
    BSR     PRINT_COMMA
    BSR     D_ADDRESS_REG_DIRECT
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

NOT:
    ** GET SIZE 1**
    MOVE.B  #1, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_NOT, A1
    BSR     PRINT_OPCODE
    BSR     PRINT_SIZE1
    BSR     GET_SOURCE_MODE
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

BLT:
    ** DISPLACMENT CAN BE UP TO 1 LONGWORD **
    ** GET DISPLACMENET **
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #8, D3
    BSR     GET_BITS
    MOVE.B  D1, DISPLACEMENT
    
    LEA     OPC_BLT, A1
    BSR     PRINT_OPCODE
    BSR     GET_DISPLACEMENT
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

BGE:
    ** DISPLACMENT CAN BE UP TO 1 LONGWORD **
    ** GET DISPLACMENET **
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #8, D3
    BSR     GET_BITS
    MOVE.B  D1, DISPLACEMENT
    
    LEA     OPC_BGE, A1
    BSR     PRINT_OPCODE
    BSR     GET_DISPLACEMENT
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

BEQ:
    ** DISPLACMENT CAN BE UP TO 1 LONGWORD **
    ** GET DISPLACMENET **
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #8, D3
    BSR     GET_BITS
    MOVE.B  D1, DISPLACEMENT
    
    LEA     OPC_BEQ, A1
    BSR     PRINT_OPCODE
    BSR     GET_DISPLACEMENT

    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

BRA:
    ** DISPLACMENT CAN BE UP TO 1 LONGWORD **
    ** GET DISPLACMENET **
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #8, D3
    BSR     GET_BITS
    MOVE.B  D1, DISPLACEMENT
    
    LEA     OPC_BRA, A1
    BSR     PRINT_OPCODE
    BSR     GET_DISPLACEMENT
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

DIVU:
    ** DESTINATION ALWAYS DATA REGISTER **
    ** GET DESTINATION Dn **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_DIVU, A1
    BSR     PRINT_OPCODE
    BSR     GET_SOURCE_MODE
    BSR     PRINT_COMMA
    BSR     D_DATA_REGISTER
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

SUB:
    ** DESTINATION ALWAYS DATA REGISTER **
    ** GET DESTINATION Dn **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET DIRECTION **
    ** Dn ea -> Dn (0) or ea Dn -> ea (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SIZE 3 **
    MOVE.B  #3, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_SUB, A1
    BSR     PRINT_OPCODE
    BSR     PRINT_SIZE3
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

MULS:
    ** DESTINATION ALWAYS DATA REGISTER **
    ** GET DESTINATION Dn **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_MULS, A1
    BSR     PRINT_OPCODE
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

AND:
    ** DESTINATION ALWAYS DATA REGISTER **
    ** GET DESTINATION Dn **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET DIRECTION **
    ** Dn ea -> Dn (0) or ea Dn -> ea (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SIZE 1 **
    MOVE.B  #1, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_AND, A1
    BSR     PRINT_OPCODE
    BSR     PRINT_SIZE1
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

ADD:
    ** DESTINATION ALWAYS DATA REGISTER **
    ** GET DESTINATION Dn **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, DESTINATION_XN
    ** GET DIRECTION **
    ** Dn ea -> Dn (0) or ea Dn -> ea (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SIZE 3 **
    MOVE.B  #3, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    LEA     OPC_ADD, A1
    BSR     PRINT_OPCODE
    BSR     PRINT_SIZE3
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

LSD_IMMEDIATE:
    ** GET DIRECTION **
    ** Right (0) or Left (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    ;LEA     OPC_LSL/LSR, A1
    ;BSR     PRINT_OPCODE
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

LSD_REGISTER:
    ** GET COUNT/REGISTER **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, COUNT_REGISTER
    ** GET DIRECTION **
    ** Right (0) or Left (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SIZE 1 **
    MOVE.B  #1, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET ROTATION **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, ROTATION
    ** SOURCE REGISTER ALWAYS DATA REGISTER **
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    ;LEA     OPC_LSL/LSR, A1
    ;BSR     PRINT_OPCODE
    BSR     PRINT_SIZE1
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

ASD_IMMEDIATE:
    ** GET DIRECTION **
    ** Right (0) or Left (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SOURCE MODE **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_MODE
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    ;LEA     OPC_ASL/ASR, A1
    ;BSR     PRINT_OPCODE
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

ASD_REGISTER:
    ** GET COUNT/REGISTER **
    MOVE.W  D7, D1
    MOVE.B  #4, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, COUNT_REGISTER
    ** GET DIRECTION **
    ** Right (0) or Left (1)**
    MOVE.W  D7, D1
    MOVE.B  #7, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, DIRECTION
    ** GET SIZE 1 **
    MOVE.B  #1, SIZE_TYPE
    MOVE.W  D7, D1
    MOVE.B  #8, D2
    MOVE.B  #2, D3
    BSR     GET_BITS
    MOVE.B  D1, SIZE
    ** GET ROTATION **
    MOVE.W  D7, D1
    MOVE.B  #10, D2
    MOVE.B  #1, D3
    BSR     GET_BITS
    MOVE.B  D1, ROTATION
    ** SOURCE REGISTER ALWAYS DATA REGISTER **
    ** GET SOURCE Xn **
    MOVE.W  D7, D1
    MOVE.B  #13, D2
    MOVE.B  #3, D3
    BSR     GET_BITS
    MOVE.B  D1, SOURCE_XN
    
    ;LEA     OPC_ASL/ASR, A1
    ;BSR     PRINT_OPCODE
    BSR     PRINT_SIZE1
    
    BSR     PRINT_NEWLINE
    BRA     CLEAR_INSTRUCTION_MEMORY

INVALID:
    ** PRINT INVALID INSTRUCTION **
    LEA     INSTRUCTION_ERROR, A1
    MOVE.B  #13, D0
    TRAP    #15
    BRA     CLEAR_INSTRUCTION_MEMORY

**-----------END INSTRUCTION DISASSEMBLY----------**

**---------------PRINT OPCODE---------------------**
** PRINT OPCODE LOADED IN A1
PRINT_OPCODE:
    MOVE.B  #14, D0
    TRAP    #15
    RTS

**---------------PRINT NEWLINE--------------------**
PRINT_NEWLINE:
    LEA     VAR_NEW_LINE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

**---------------PRINT COMMA----------------------**
PRINT_COMMA:
    LEA     VAR_COMMA, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

**---------------PRINT HEX----------------------**
PRINT_HEX:
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

**---------------PRINT BASE 16--------------------**
** PRINT THE VALUE IN D1 IN BASE 16
** USED FOR PRINTING IMMEDIATE VALUES OR ADDRESSES
PRINT_BASE16:
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15
    RTS

**---------------GET BCC DISPLACEMENT--------------------**

GET_DISPLACEMENT:
    MOVE.B  (DISPLACEMENT), D1
    CMP.B   #$00, D1
    BEQ     PRINT_WORD_DISPLACEMENT
    CMP.B   #$FF, D1
    BEQ     PRINT_LONG_DISPLACEMENT
    BRA     PRINT_BYTE_DISPLACEMENT

PRINT_WORD_DISPLACEMENT:
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.W (A6)+,D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15 
    RTS
    
PRINT_LONG_DISPLACEMENT:
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.L (A6)+,D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15 
    RTS

PRINT_BYTE_DISPLACEMENT:
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15
    MOVE.B  (DISPLACEMENT), D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15 
    RTS

**-------------------GET MODE---------------------**
** ARGUMENTS:
* D1: SOURCE MODE
*   D1: MODE OF SOURCE REGISTER
GET_SOURCE_MODE:
    MOVE.B  SOURCE_MODE, D1
    CMP.B   #$00, D1
    BEQ     S_DATA_REGISTER
    CMP.B   #$01, D1
    BEQ     S_ADDRESS_REG_DIRECT
    CMP.B   #$02, D1
    BEQ     S_ADDRESS_REG_INDIRECT
    CMP.B   #$03, D1
    BEQ     S_ADDRESS_REG_POSTINC
    CMP.B   #$04, D1
    BEQ     S_ADDRESS_REG_PREDEC
    CMP.B   #$07, D1
    BEQ     S_IMM_ABS_WORD_LONG       ; NEED Xn TO DETERMINE
    BRA     INVALID

S_DATA_REGISTER:
    MOVE.B  SOURCE_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_D0
    CMP.B   #$01, D1
    BEQ     PRINT_D1
    CMP.B   #$02, D1
    BEQ     PRINT_D2
    CMP.B   #$03, D1
    BEQ     PRINT_D3
    CMP.B   #$04, D1
    BEQ     PRINT_D4
    CMP.B   #$05, D1
    BEQ     PRINT_D5
    CMP.B   #$06, D1
    BEQ     PRINT_D6
    CMP.B   #$07, D1
    BEQ     PRINT_D7
    BRA     INVALID
    
S_ADDRESS_REG_DIRECT:
    MOVE.B  SOURCE_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0
    CMP.B   #$01, D1
    BEQ     PRINT_A1
    CMP.B   #$02, D1
    BEQ     PRINT_A2
    CMP.B   #$03, D1
    BEQ     PRINT_A3
    CMP.B   #$04, D1
    BEQ     PRINT_A4
    CMP.B   #$05, D1
    BEQ     PRINT_A5
    CMP.B   #$06, D1
    BEQ     PRINT_A6
    CMP.B   #$07, D1
    BEQ     PRINT_A7
    BRA     INVALID
    
S_ADDRESS_REG_INDIRECT:
    MOVE.B  SOURCE_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0_IND
    CMP.B   #$01, D1
    BEQ     PRINT_A1_IND
    CMP.B   #$02, D1
    BEQ     PRINT_A2_IND
    CMP.B   #$03, D1
    BEQ     PRINT_A3_IND
    CMP.B   #$04, D1
    BEQ     PRINT_A4_IND
    CMP.B   #$05, D1
    BEQ     PRINT_A5_IND
    CMP.B   #$06, D1
    BEQ     PRINT_A6_IND
    CMP.B   #$07, D1
    BEQ     PRINT_A7_IND
    BRA     INVALID
    
S_ADDRESS_REG_POSTINC:
    MOVE.B  SOURCE_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0_POSTINC
    CMP.B   #$01, D1
    BEQ     PRINT_A1_POSTINC
    CMP.B   #$02, D1
    BEQ     PRINT_A2_POSTINC
    CMP.B   #$03, D1
    BEQ     PRINT_A3_POSTINC
    CMP.B   #$04, D1
    BEQ     PRINT_A4_POSTINC
    CMP.B   #$05, D1
    BEQ     PRINT_A5_POSTINC
    CMP.B   #$06, D1
    BEQ     PRINT_A6_POSTINC
    CMP.B   #$07, D1
    BEQ     PRINT_A7_POSTINC
    BRA     INVALID

S_ADDRESS_REG_PREDEC:
    MOVE.B  SOURCE_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0_PREDEC
    CMP.B   #$01, D1
    BEQ     PRINT_A1_PREDEC
    CMP.B   #$02, D1
    BEQ     PRINT_A2_PREDEC
    CMP.B   #$03, D1
    BEQ     PRINT_A3_PREDEC
    CMP.B   #$04, D1
    BEQ     PRINT_A4_PREDEC
    CMP.B   #$05, D1
    BEQ     PRINT_A5_PREDEC
    CMP.B   #$06, D1
    BEQ     PRINT_A6_PREDEC
    CMP.B   #$07, D1
    BEQ     PRINT_A7_PREDEC
    BRA     INVALID
    
S_IMM_ABS_WORD_LONG:
    ** GET XN VALUE TO DERETMINE IF IMMEDIATE, ABSOLUTE LONG OR ABSOLUTE WORD **
    MOVE.B  SOURCE_XN, D1
    CMP.B   #$04, D1
    BEQ     SOURCE_IMMEDIATE
    CMP.B   #$01, D1
    BEQ     SOURCE_ABS_LONG
    CMP.B   #$00, D1
    BEQ     SOURCE_ABS_WORD
    BRA     INVALID

SOURCE_IMMEDIATE:
    ** USE SIZE TO DETERMINE SIZE OF IMMEDIATE DATA **
    MOVE.B  SIZE_TYPE, D1
    CMP.B   #$01, D1
    BEQ     S_IMMEDIATE_SIZE1
    CMP.B   #$02, D1
    BEQ     S_IMMEDIATE_SIZE2
    CMP.B   #$03, D1
    BEQ     S_IMMEDIATE_SIZE3
    BRA     INVALID
   
S_IMMEDIATE_SIZE1:
    MOVE.B  SIZE, D1
    CMP.B   #$00, D1
    BEQ     IMMEDIATE_BYTE
    CMP.B   #$01, D1
    BEQ     IMMEDIATE_WORD
    CMP.B   #$02, D1
    BEQ     IMMEDIATE_LONG
    BRA     INVALID

S_IMMEDIATE_SIZE2:
    MOVE.B  SIZE, D1
    CMP.B   #$00, D1
    BEQ     IMMEDIATE_WORD
    CMP.B   #$01, D1
    BEQ     IMMEDIATE_LONG
    BRA     INVALID

S_IMMEDIATE_SIZE3:
    MOVE.B  SIZE, D1
    CMP.B   #$01, D1
    BEQ     IMMEDIATE_BYTE
    CMP.B   #$03, D1
    BEQ     IMMEDIATE_WORD
    CMP.B   #$02, D1
    BEQ     IMMEDIATE_LONG
    BRA     INVALID

IMMEDIATE_BYTE:
    MOVE.L  #$00000000, D1
    LEA     VAR_NUM, A1
    MOVE.B  #14, D0
    TRAP    #15             ; PRINT "#"
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15             ; PRINT "$"
    MOVE.W  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15             ; PRINT WORD VALUE
    RTS

IMMEDIATE_WORD:
    MOVE.L  #$0000000, D1
    LEA     VAR_NUM, A1
    MOVE.B  #14, D0
    TRAP    #15             ; PRINT "#"
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15             ; PRINT "$"
    MOVE.W  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15
    RTS

IMMEDIATE_LONG:
    LEA     VAR_NUM, A1
    MOVE.B  #14, D0
    TRAP    #15             ; PRINT "#"
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15             ; PRINT "$"
    MOVE.L  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15
    RTS

SOURCE_ABS_LONG:
    MOVE.L  #$00000000, D1      ; CLEAR D1
    ;LEA     VAR_OPEN_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT OPEN PAREN
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15                 ; PRINT HEX SIGN
    MOVE.L  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15                 ; PRINT VALUE IN HEX
    ;LEA     VAR_CLOSE_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT CLOSE PAREN
    ;LEA     VAR_LONG, A1
    ;MOVE.B  #14, D0 
    ;TRAP    #15                 ; PRINT ".L" END
    RTS
    
SOURCE_ABS_WORD:
    MOVE.L  #$00000000, D1      ; CLEAR D1
    ;LEA     VAR_OPEN_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT OPEN PAREN
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15                 ; PRINT HEX SIGN
    MOVE.W  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15                 ; PRINT VALUE IN HEX
    ;LEA     VAR_CLOSE_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT CLOSE PAREN
    ;LEA     VAR_WORD, A1
    ;MOVE.B  #14, D0 
    ;TRAP    #15                 ; PRINT ".W" END
    RTS
    
**-------------------GET MODE---------------------**
** ARGUMENTS:
* D1: SOURCE MODE
*   D1: MODE OF SOURCE REGISTER
GET_DEST_MODE:
    MOVE.B  DESTINATION_MODE, D1
    CMP.B   #$00, D1
    BEQ     D_DATA_REGISTER
    CMP.B   #$01, D1
    BEQ     D_ADDRESS_REG_DIRECT
    CMP.B   #$02, D1
    BEQ     D_ADDRESS_REG_INDIRECT
    CMP.B   #$03, D1
    BEQ     D_ADDRESS_REG_POSTINC
    CMP.B   #$04, D1
    BEQ     D_ADDRESS_REG_PREDEC
    CMP.B   #$07, D1
    BEQ     D_IMM_ABS_WORD_LONG       ; NEED Xn TO DETERMINE
    BRA     INVALID

D_DATA_REGISTER:
    MOVE.B  DESTINATION_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_D0
    CMP.B   #$01, D1
    BEQ     PRINT_D1
    CMP.B   #$02, D1
    BEQ     PRINT_D2
    CMP.B   #$03, D1
    BEQ     PRINT_D3
    CMP.B   #$04, D1
    BEQ     PRINT_D4
    CMP.B   #$05, D1
    BEQ     PRINT_D5
    CMP.B   #$06, D1
    BEQ     PRINT_D6
    CMP.B   #$07, D1
    BEQ     PRINT_D7
    BRA     INVALID

D_ADDRESS_REG_DIRECT:
    MOVE.B  DESTINATION_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0
    CMP.B   #$01, D1
    BEQ     PRINT_A1
    CMP.B   #$02, D1
    BEQ     PRINT_A2
    CMP.B   #$03, D1
    BEQ     PRINT_A3
    CMP.B   #$04, D1
    BEQ     PRINT_A4
    CMP.B   #$05, D1
    BEQ     PRINT_A5
    CMP.B   #$06, D1
    BEQ     PRINT_A6
    CMP.B   #$07, D1
    BEQ     PRINT_A7
    BRA     INVALID
    
D_ADDRESS_REG_INDIRECT:
    MOVE.B  DESTINATION_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0_IND
    CMP.B   #$01, D1
    BEQ     PRINT_A1_IND
    CMP.B   #$02, D1
    BEQ     PRINT_A2_IND
    CMP.B   #$03, D1
    BEQ     PRINT_A3_IND
    CMP.B   #$04, D1
    BEQ     PRINT_A4_IND
    CMP.B   #$05, D1
    BEQ     PRINT_A5_IND
    CMP.B   #$06, D1
    BEQ     PRINT_A6_IND
    CMP.B   #$07, D1
    BEQ     PRINT_A7_IND
    BRA     INVALID
    
D_ADDRESS_REG_POSTINC:
    MOVE.B  DESTINATION_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0_POSTINC
    CMP.B   #$01, D1
    BEQ     PRINT_A1_POSTINC
    CMP.B   #$02, D1
    BEQ     PRINT_A2_POSTINC
    CMP.B   #$03, D1
    BEQ     PRINT_A3_POSTINC
    CMP.B   #$04, D1
    BEQ     PRINT_A4_POSTINC
    CMP.B   #$05, D1
    BEQ     PRINT_A5_POSTINC
    CMP.B   #$06, D1
    BEQ     PRINT_A6_POSTINC
    CMP.B   #$07, D1
    BEQ     PRINT_A7_POSTINC
    BRA     INVALID
    
D_ADDRESS_REG_PREDEC:
    MOVE.B  DESTINATION_XN, D1
    CMP.B   #$00, D1
    BEQ     PRINT_A0_PREDEC
    CMP.B   #$01, D1
    BEQ     PRINT_A1_PREDEC
    CMP.B   #$02, D1
    BEQ     PRINT_A2_PREDEC
    CMP.B   #$03, D1
    BEQ     PRINT_A3_PREDEC
    CMP.B   #$04, D1
    BEQ     PRINT_A4_PREDEC
    CMP.B   #$05, D1
    BEQ     PRINT_A5_PREDEC
    CMP.B   #$06, D1
    BEQ     PRINT_A6_PREDEC
    CMP.B   #$07, D1
    BEQ     PRINT_A7_PREDEC
    BRA     INVALID
    
D_IMM_ABS_WORD_LONG:
    ** GET XN VALUE TO DERETMINE IF IMMEDIATE, ABSOLUTE LONG OR ABSOLUTE WORD **
    MOVE.B  DESTINATION_XN, D1
    CMP.B   #$04, D1
    BEQ     DEST_IMMEDIATE
    CMP.B   #$01, D1
    BEQ     DEST_ABS_LONG
    CMP.B   #$00, D1
    BEQ     DEST_ABS_WORD
    BRA     INVALID

DEST_IMMEDIATE:
    ** DESTINATION CANNOT BE IMMEDIATE DATA **
    BRA INVALID
    
DEST_ABS_LONG:
    MOVE.L  #$00000000, D1      ; CLEAR D1
    ;LEA     VAR_OPEN_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT OPEN PAREN
    ;LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15                 ; PRINT HEX SIGN
    MOVE.L  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15                 ; PRINT VALUE
    ;LEA     VAR_CLOSE_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT CLOSE PAREN
    ;LEA     VAR_LONG, A1
    ;MOVE.B  #14, D0 
    ;TRAP    #15                 ; PRINT ".L" END
    RTS
    
DEST_ABS_WORD:
    MOVE.L  #$00000000, D1      ; CLEAR D1
    ;LEA     VAR_OPEN_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT OPEN PAREN
    LEA     VAR_HEX, A1
    MOVE.B  #14, D0
    TRAP    #15                 ; PRINT HEX SIGN
    MOVE.W  (A6)+, D1
    MOVE.B  #15, D0
    MOVE.B  #16, D2
    TRAP    #15                 ; PRINT VALUE IN HEX
    ;LEA     VAR_CLOSE_PAREN, A1
    ;MOVE.B  #14, D0
    ;TRAP    #15                 ; PRINT CLOSE PAREN
    ;LEA     VAR_WORD, A1
    ;MOVE.B  #14, D0 
    ;TRAP    #15                 ; PRINT ".W" END
    RTS
    
**----------------PRINT DATA REGISTER-------------**
PRINT_D0:
    LEA     DATA_ZERO, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D1:
    LEA     DATA_ONE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D2:
    LEA     DATA_TWO, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D3:
    LEA     DATA_THREE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D4:
    LEA     DATA_FOUR, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D5:
    LEA     DATA_FIVE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D6:
    LEA     DATA_SIX, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_D7:
    LEA     DATA_SEVEN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
**----------------PRINT ADDRESS REGISTER-------------**
PRINT_A0:
    LEA     ADDR_ZERO, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A1:
    LEA     ADDR_ONE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A2:
    LEA     ADDR_TWO, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A3:
    LEA     ADDR_THREE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A4:
    LEA     ADDR_FOUR, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A5:
    LEA     ADDR_FIVE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A6:
    LEA     ADDR_SIX, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A7:
    LEA     ADDR_SEVEN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
*----------------PRINT ADDRESS REGISTER INDIRECT-------------**
PRINT_A0_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_ZERO, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A1_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_ONE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A2_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_TWO, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A3_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_THREE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A4_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_FOUR, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A5_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_FIVE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A6_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_SIX, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A7_IND:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_SEVEN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

*----------------PRINT ADDRESS REGISTER POSTINCREMENT-------------**
PRINT_A0_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_ZERO, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A1_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_ONE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A2_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_TWO, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A3_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_THREE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A4_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_FOUR, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A5_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_FIVE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A6_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_SIX, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A7_POSTINC:
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_SEVEN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_PLUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

*----------------PRINT ADDRESS REGISTER PREDECREMENT-------------**
PRINT_A0_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_ZERO, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A1_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_ONE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A2_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_TWO, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A3_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_THREE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A4_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_FOUR, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A5_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_FIVE, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A6_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_SIX, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_A7_PREDEC:
    LEA     VAR_MINUS, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_OPEN_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     ADDR_SEVEN, A1
    MOVE.B  #14, D0
    TRAP    #15
    LEA     VAR_CLOSE_PAREN, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

**-------------------GET SIZE---------------------**
** USES SIZE IN SIZE MEMORY LOCATION**
PRINT_SIZE1:
    MOVE.B  SIZE, D1
    CMP.B   #$00, D1
    BEQ     PRINT_BYTE
    CMP.B   #$01, D1
    BEQ     PRINT_WORD
    CMP.B   #$02, D1
    BEQ     PRINT_LONG
    BRA     INVALID
    
PRINT_SIZE2:
    MOVE.B  SIZE, D1
    CMP.B   #$00, D1
    BEQ     PRINT_WORD
    CMP.B   #$01, D1
    BEQ     PRINT_LONG
    BRA     INVALID
    
    
PRINT_SIZE3:
    MOVE.B  SIZE, D1
    CMP.B   #$01, D1
    BEQ     PRINT_BYTE
    CMP.B   #$03, D1
    BEQ     PRINT_WORD
    CMP.B   #$02, D1
    BEQ     PRINT_LONG
    BRA     INVALID

PRINT_BYTE:
    LEA     VAR_BYTE, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS
    
PRINT_WORD:
    LEA     VAR_WORD, A1
    MOVE.B  #14, D0
    TRAP    #15
    RTS

PRINT_LONG:
    LEA     VAR_LONG, A1
    MOVE.B  #14, D0
    TRAP    #15    
    RTS
   
**------------------VARIABLES---------------------**
LF  EQU  $0A                        ; Line Feed
CR  EQU  $0D                        ; Carriage Return 
**----------DISPLAY INSTRUCTION CONSTANTS---------**
OPC_NOP                    DC.L        'NOP ',0      * Required OP CODE
OPC_MOVE                   DC.L        'MOVE',0     * Required OP CODE   
OPC_MOVEM                  DC.L        'MOVEM',0    * Required OP CODE
OPC_ADD                    DC.L        'ADD',0      * Required OP CODE
OPC_SUB                    DC.L        'SUB',0      * Required OP CODE
OPC_MULS                   DC.L        'MULS',0     * Required OP CODE
OPC_DIVU                   DC.L        'DIVU',0     * Required OP CODE
OPC_LEA                    DC.L        'LEA ',0      * Required OP CODE
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

ADDR_SEVEN                 DC.L        'A7',0
ADDR_SIX                   DC.L        'A6',0
ADDR_FIVE                  DC.L        'A5',0
ADDR_FOUR                  DC.L        'A4',0
ADDR_THREE                 DC.L        'A3',0
ADDR_TWO                   DC.L        'A2',0
ADDR_ONE                   DC.L        'A1',0
ADDR_ZERO                  DC.L        'A0',0

DATA_SEVEN                 DC.L        'D7',0
DATA_SIX                   DC.L        'D6',0
DATA_FIVE                  DC.L        'D5',0
DATA_FOUR                  DC.L        'D4',0
DATA_THREE                 DC.L        'D3',0
DATA_TWO                   DC.L        'D2',0
DATA_ONE                   DC.L        'D1',0
DATA_ZERO                  DC.L        'D0',0

INSTRUCTION_PROMPT  DC.B    'ENTER HEX INSTRUCTION: ',0
ERROR               DC.B    'INPUT ERROR',CR,LF,0
INSTRUCTION_ERROR   DC.B    'INVALID INSTRUCTION',CR,LF,0
GET_START_ADDRESS   DC.B    'ENTER START ADDRESS IN LONG HEX FORMAT: ',0
GET_END_ADDRESS     DC.B    'ENTER END ADDRESS IN LONG HEX FORMAT: ',0
TEST_FAIL           DC.B    'ASSERT FAILED: ',0           
TEST_SUCC           DC.B    'ASSERT SUCCESSFUL: ',0

**-------------------MEMORY FOR OPCODE DECOMPOSITION----------------**
FIRST_FOUR_NYBBLE   DS.B    1       ; DECLARE 1 BYTE FOR FIRST NYBBLE
DESTINATION_MODE    DS.B    1       ; DECLARE 1 BYTE FOR DESTINATION MODE
DESTINATION_XN      DS.B    1       ; DECLARE 1 BYTE FOR DESTINATION Xn
SOURCE_MODE         DS.B    1       ; DECLARE 1 BYTE FOR SOURCE MODE
SOURCE_XN           DS.B    1       ; DELCARE 1 BYTE FOR SOURCE Xn
SIZE                DS.B    1       ; DECLARE 1 BYTE FOR SIZE
SIZE_TYPE           DS.B    1       ; DECLARE 1 BYTE FOR TYPE OF SIZE (1,2,3)
DIRECTION           DS.B    1       ; DECLARE 1 BYTE FOR DIRECTION
ROTATION            DS.B    1       ; DECLARE 1 BYTE FOR LSD/ASD ROTATION
COUNT_REGISTER      DS.B    1       ; DECLARE 1 BYTE FOR LSD/ASD COUNT/REGISTER
DISPLACEMENT        DS.B    1       ; DECLARE UP TO 1 LONGWORD FOR BCC DISPLACEMENT    

INSTRUCTION_LENGTH  DS.W    1       ; DECLARE 1 BYTE FOR LENGTH
ASCII_INSTRUCTION   DS.W    10      ; DECLARE UP TO 10 WORDS FOR ASCII INSTRUCTION
INSTRUCTION_BREAK   DS.B    1       ; BREAK ASCII INSTRUCTION AND HEX INSTRUCTION IN MEMORY
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
