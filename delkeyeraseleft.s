********************************
*                              *
* DELETE KEY HANDLER           *
*                              *
* AUTHOR:  BILL CHATFIELD      *
* LICENSE: GPL                 *
*                              *
********************************

               ORG   $300
               TYP   $06        	;BINARY TYPE
               DSK   delkeyeraseleft	;PUT FILE NAME

CH             EQU   $24        ;HORIZ CHAR POS (40-COL)
BASL           EQU   $28        ;BASE ADDR FOR CURR VIDEO LINE
KSWL           EQU   $38        ;KEYBOARD SWITCH LOW BYTE
KSWH           EQU   $39        ;KEYBOARD SWITCH HIGH BYTE
OURCH          EQU   $57B       ;HORIZONTAL POSITION (80-COL)
OURCV          EQU   $5FB       ;VERTICAL POSITION (80-COL)
KBD            EQU   $C000      ;KEYBOARD DATA + STROBE
KBDSTRB        EQU   $C010      ;CLEAR KEYBOARD STROBE
CXROMON        EQU   $C007      ;TURN ON INTERNAL ROM
CXROMOFF       EQU   $C006      ;ENABLE SLOT ROMS
ALTCHAR        EQU   $C01E      ;>=$80 IF IN 80-COL
COUT           EQU   $FDED      ;WRITE A CHARACTER

* 80-COL SUBS INSIDE THE INTERNAL ROM
INVERT         EQU   $CEDD      ;INVERT CHAR ON SCREEN
PICK           EQU   $CF01      ;PICK CHAR OFF SCREEN

* INPUT SUBS
RDKEY          EQU   $FD0C
RDCHAR         EQU   $FD35
KEYIN          EQU   $FD1B
BASICIN        EQU   $C305
GETLN          EQU   $FD6A
NOESC          EQU   $C9B7      ;HANDLES KEY OTHER THAN ESC
BINPUT         EQU   $C8F6
ESCAPING       EQU   $C918
IN             EQU   $200       ;256-CHAR INPUT BUFFER

ESC            EQU   $9B        ;ESC WITH HIGH BIT SET
RTARROW        EQU   $95        ;RIGHT ARROW WITH HIGH BIT SET
DELETE         EQU   $FF        ;DELETE WITH HIGH BIT SET
BKSPACE        EQU   $88        ;BACKSPACE WITH HIGH BIT SET

HEXDEC         EQU   $ED24      ;HEX-TO-DECIMAL CONVERSION
CROUT          EQU   $FD8E      ;PRINT A CARRIAGE RETURN
STROUT         EQU   $DB3A      ;PRINT NULL-TERM STRING IN AY
* MONITOR SUBS
PRINTXY        EQU   $F940      ;PRINT X & Y AS HEX
PRBYTE         EQU   $FDDA      ;PRINT BYTE AS 2 HEX DIGITS

STOR80ON       EQU   $C001      ;ENABLE AUXILIARY MEM SWITCHING
PAGE2OFF       EQU   $C054      ;TURN ON MAIN MEMORY
PAGE2ON        EQU   $C055      ;TURN ON AUXILIARY MEMORY

DEBUG          EQU   1
DEBUG2         EQU   0

********************************
*                              *
* PUTS MACRO                   *
*                              *
* APPLESOFT MUST BE IN MEMORY  *
* BECAUSE THE STROUT SUB IS    *
* USED.                        *
*                              *
* X & Y ARE PRESERVED          *
*                              *
* ]1 - ADDRESS OF STRING       *
*                              *
********************************

PUTS           MAC
               TYA              ;PRESERVE Y
               PHA
               LDA   #<]1       ;PUT LOW BYTE INTO A
               LDY   #>]1       ;PUT HIGH BYTE INTO Y
               JSR   STROUT     ;CALL APPLESOFT'S STRING PRINT
               PLA              ;RESTORE Y
               TAY
               <<<

********************************
*                              *
* PUTC80 MACRO                 *
*                              *
* IN 80-COL MODE EVEN COLUMNS  *
* ARE IN AUXILIARY MEMORY      *
* WHILE ODD COLUMNS ARE IN     *
* MAIN MEMORY.                 *
*                              *
* ]1 - CHARACTER TO DISPLAY    *
* ]2 - DESIRED COLUMN          *
*                              *
********************************

PUTC80         MAC
               TYA              ;MOVE Y TO A
               PHA              ;SAVE Y VALUE ON STACK
               SEI              ;DISABLE INTERRUPTS
               STA   STOR80ON   ;ENABLE MAIN/AUX MEM SWITCHING
               LDA   ]2         ;LOAD 80-COL HORIZ CURSOR POSITN
               LSR   A          ;DIVIDE BY 2 TO CALC PHYS COLUMN
               BCC   AUXMEM     ;IF EVEN, COLUMN IS IN AUX MEM
MAINMEM        STA   PAGE2OFF   ;TURN OFF AUX MEM, MAIN MEM ON
               JMP   CONTINUE   ;AVOID AUX MEM ENABLE
AUXMEM         STA   PAGE2ON    ;TURN ON AUX MEM, MAIN MEM OFF
CONTINUE       TAY              ;MOVE CURSOR POSITION TO Y
               LDA   ]1         ;LOAD THE CHARACTER TO DISPLAY
               STA   (BASL),Y   ;DISPLAY THE CHARACTER
               STA   PAGE2OFF   ;TURN MAIN MEM BACK ON
               CLI              ;ENABLE INTERRUPTS
               PLA              ;PULL Y VALUE FROM STACK
               TAY              ;RESTORE Y VALUE
               <<<

********************************
*                              *
* INSTALL VECTOR TO HANDLER    *
*                              *
********************************

MAIN
               LDA   #<DELHNDLR
               STA   KSWL
               LDA   #>DELHNDLR
               STA   KSWH
               PUTS  LOADMSG
               RTS

********************************
*                              *
* KEYBOARD INPUT ROUTINE       *
*                              *
* PRECONDITIONS:               *
* 1. CURSOR AT CH & BASL       *
* 2. ACCUM = ORIG SCREEN BYTE  *
* 3. Y = VALUE IN CH           *
*                              *
* POSTCONDITIONS:              *
* 1. MUST RETURN CHAR IN ACCUM *
* 2. X & Y MUST NOT BE CHANGED *
*                              *
********************************

DELHNDLR
               STA   ORIGCURS   ;STORE THE ORIGINAL CURSOR CHAR
               TXA              ;SAVE X
               PHA
               TYA              ;SAVE Y
               PHA

               BIT   ALTCHAR    ;TEST FOR 80-COL ON
               BMI   COL80

COL40
               JSR   GETKEY     ;LOAD "KEY" VARIABLE
               JSR   DEL2BS     ;CONVERT DELETE TO BACKSPACE
               LDA   ORIGCURS
               STA   (BASL),Y   ;REMOVE CURSOR
               JMP   FINISH

COL80
               PUTC80 #' ';OURCH ;DISPLAY OUR CURSOR, INVERSE SPC

NEXTKEY
               JSR   GETKEY     ;LOAD "KEY" VARIABLE
               JSR   DEL2BS     ;CONVERT DELETE TO BACKSPACE
               CMP   #ESC       ;IS IT ESC?
               BEQ   NEXTKEY    ;IGNORE ESC
               CMP   #RTARROW   ;IS IT A RIGHT ARROW
               BNE   CLRCURS    ;NOT RIGHT ARROW THEN DONE
               LDY   OURCH      ;GET HORIZONTAL CURSOR POSITION
               JSR   PICK       ;GRAB CHAR FROM SCREEN
               ORA   #$80       ;SET HIGH BIT
               STA   KEY

CLRCURS
               PUTC80 #" ";OURCH ;ERASE CURSOR

FINISH
               PLA              ;RESTORE Y
               TAY
               PLA              ;RESTORE X
               TAX
               LDA   KEY        ;LOAD RETURN VALUE
               RTS

********************************
*                              *
* GETKEY SUBROUTINE            *
*                              *
********************************

GETKEY
               BIT   KBD        ;TEST FOR KEY PRESSED
               BPL   GETKEY     ;WAIT FOR KEY PRESSED
               LDA   KBD        ;GET THE KEY THAT WAS PRESSED
               BIT   KBDSTRB    ;CLEAR KEYBOARD STROBE
               STA   KEY        ;STORE THE KEY THAT WAS READ
               RTS

********************************
*                              *
* DEL2BS SUBROUTINE            *
*                              *
********************************

DEL2BS
               CMP   #DELETE    ;IS THE KEY IN A THE DELETE KEY
               BNE   D2BDONE
               LDA   #BKSPACE
               STA   KEY
D2BDONE
               RTS

********************************
*                              *
* DATA                         *
*                              *
********************************

LOADMSG        ASC   "LOADED DELETE KEY HANDLER",0D,00
KEY            DB    0
ORIGCURS       DB    0


