*-----------------------------------------------------------
* Title      : File I/O
* Written by : Duncan Spani
* Date       : 4/22/21
* Description: Test file input and output
*-----------------------------------------------------------
    ORG    $1000
START:                          
    LEA     FILE,A1             ;LOAD FILE NAME INTO A1
    MOVE.B  #51,D0
    TRAP    #15                 ;OPEN FILE TRAP TASK 51
    
    MOVE.B  #120,D2             ;TELL TRAP TASK 53 TO READ #120 BYTES
    MOVE.B  #53,D0              
    TRAP    #15                 ;READ FROM FILE TRAP TASK 53
    
    ; DOES NOT WORK
    ; assumed addressing error
    LEA     OUTPUT,A1           ;LOAD ADDRESS OF OUTPUT STRING INTO A1
    MOVE.B  #30,D2              ;TELL TRAP TASK 54 TO WRITE #30 BYTES
    MOVE.B  #54,D0              
    TRAP    #15                 ;WRITE TO FILE TRAP TASK 54
    
    MOVE.B  #50,D0
    TRAP    #15                 ;CLOSE ALL FILES TRAP TASK 50
    ; DOES NOT WORK
    
    

* variables and constants
OUTPUT  DC.B    'and Microsoft WordPad and Apple TextEdit can optionally save files as TXT files.',0
FILE    DC.B    'file.txt',0
ABC     DC.B    'HELLO',0       ;WILL OVERWRITE ONCE BYTES READ FROM FILE
    END    START

*~Font name~Courier New~
*~Font size~16~
*~Tab type~1~
*~Tab size~4~
