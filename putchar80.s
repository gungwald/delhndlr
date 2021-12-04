********************************
*                              *
* PUTCHAR80 SUBROUTINE         *
*                              *
* IN 80-COL MODE EVEN COLUMNS  *
* ARE IN AUXILIARY MEMORY      *
* WHILE ODD COLUMNS ARE IN     *
* MAIN MEMORY.                 *
*                              *
*  A - CHARACTER TO DISPLAY    *
*  Y - DESIRED COLUMN          *
*                              *
********************************

PUTCHAR80
               PHA
               SEI              ;DISABLE INTERRUPTS
               STA   SET80COL   ;ENABLE MAIN/AUX MEM SWITCHING
               TYA              ;LOAD 80-COL HORIZ CURSOR POSITN
               LSR   A          ;DIVIDE BY 2 TO CALC PHYS COLUMN
               BCC   AUXMEM     ;IF EVEN, COLUMN IS IN AUX MEM
MAINMEM        STA   PAGE2OFF   ;TURN OFF AUX MEM, MAIN MEM ON
               JMP   CONTINUE   ;AVOID AUX MEM ENABLE
AUXMEM         STA   PAGE2ON    ;TURN ON AUX MEM, MAIN MEM OFF
CONTINUE       TAY              ;MOVE CURSOR POSITION TO Y
               PLA              ;LOAD THE CHARACTER TO DISPLAY
               STA   (BASL),Y   ;DISPLAY THE CHARACTER
               STA   PAGE2OFF   ;TURN MAIN MEM BACK ON
               CLI              ;ENABLE INTERRUPTS
               RTS
