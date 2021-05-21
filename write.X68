*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    MOVE.L  #0, TOTAL_BYTES

    ; OPEN NEW FILE
    LEA     FILE_NAME, A1
    MOVE.B  #52, D0
    TRAP    #15
    MOVE.L  D1, FID

    ; WRITE MOVEM
    MOVE.L  TOTAL_BYTES, D2
    LEA     OPC_MOVEM, A1
    MOVE.L  #8, D2
    ADDI    #8, TOTAL_BYTES
    MOVE.B  #54, D0
    TRAP    #15
    
    ; WRITE NEW LINE
    MOVE.L  TOTAL_BYTES, D2
    LEA     VAR_NEW_LINE, A1
    MOVE.L  #2, D2
    ADDI    #2, TOTAL_BYTES
    MOVE.B  #54, D0
    TRAP    #15
    
    ; WRITE NOP
    MOVE.L  TOTAL_BYTES, D2
    LEA     OPC_NOP, A1
    MOVE.L  #8, D2
    ADDI    #8, TOTAL_BYTES
    MOVE.B  #54, D0
    TRAP    #15

    ; WRITE FILE
    MOVE.B  #50, D0
    TRAP    #15
    SIMHALT             ; halt simulator


* Put variables and constants here
LF  EQU  $0A                        ; Line Feed
CR  EQU  $0D                        ; Carriage Return 
FILE_NAME           DC.B    'output.txt', 0
TOTAL_BYTES         DS.L    1
FID             DS.L    1
VAR_NEW_LINE               DC.B        '',CR,LF,0   * Symbol used for formatting
OPC_MOVEM                    DC.L        'MOVEM',0      * Required OP CODE
OPC_NOP                    DC.L        'NOP',0
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
