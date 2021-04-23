*-----------------------------------------------------------
* Title      : File I/O
* Written by : Duncan Spani
* Date       : 4/22/21
* Description: Test file input and output
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program
    LEA     FILE,A1     ;LOAD FILE NAME INTO A1
    MOVE.B  #51,D0
    TRAP    #15
    
    MOVE.B  #120,D2
    MOVE.B  #53,D0
    TRAP    #15
    

* Put variables and constants here
FILE    DC.B    'file.txt',0
ABC     DC.B    'HELLO',0
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
