********************************
*                              *
* DELETE KEY HANDLER           *
*                              *
* AUTHOR:  BILL CHATFIELD      *
* LICENSE: GPL                 *
*                              *
********************************

*********************************************************
* INPUT SUBROUTINE CALL SEQUENCE:
* GETLN ($FD6A) - READS A LINE INTO IN ($200) LENGTH IN X
* '->RDCHAR ($FD35) - HANDLES ESC SEQUENCES FOR 40 COLUMN
*    '->RDKEY ($FD0C) - READS CHAR INTO ACCUMULATOR
*       '->KSW ($38) - POINTS TO KEYIN ($FD1B) FOR 40-COL
*                      OR BASICIN ($C305) FOR 80-COL,
*                      DELHNDLR IN THIS FILE, OTHER OTHER
*                      CUSTOM SUBROUTINE. BASICIN HANDLES
*                      ESC SEQUENCES FOR 80-COLUMN.
*********************************************************

               ORG   $300
               TYP   $06        	;BINARY TYPE
               DSK   delkey.clr.left	;OUTPUT FILE NAME

WINWIDTH       EQU   $21
CH             EQU   $24        ;HORIZ CHAR POS (40-COL)
BASL           EQU   $28        ;BASE ADDR FOR CURR VIDEO LINE
KSWL           EQU   $38        ;KEYBOARD SWITCH LOW BYTE
KSWH           EQU   $39        ;KEYBOARD SWITCH HIGH BYTE
OURCH          EQU   $57B       ;HORIZONTAL POSITION (80-COL)
OURCV          EQU   $5FB       ;VERTICAL POSITION (80-COL)
KBD            EQU   $C000      ;KEYBOARD DATA + STROBE
CXROMOFF       EQU   $C006      ;ENABLE EXPANSION SLOTS AT $C100-$C7FF
CXROMON        EQU   $C007      ;ENABLE INTERNAL ROM AT $C100-$C7FF
RDCXROM        EQU   $C015      ;READ CXROM SWITCH (1 = SLOTS, 0 = ROM)
80COLOFF       EQU   $C00C      ;Off: display 40 columns
80COLON        EQU   $C00D      ;On: display 80 columns
ALTCHAROFF     EQU   $C00E      ;USE PRIMARY CHARACTER SET
ALTCHARON      EQU   $C00F      ;USE ALTERNATE CHARACTER SET
KBDSTRB        EQU   $C010      ;CLEAR KEYBOARD STROBE
RDALTCHAR      EQU   $C01E      ;READ STATE OF Alt char set (1 = on)
RD80COL        EQU   $C01F      ;READ 80COL SWITCH
COUT           EQU   $FDED      ;WRITE A CHARACTER

* 80-COL SUBS INSIDE THE INTERNAL ROM
GETKEY         EQU   $CB15      ;THIS DOES NOT SEEM TO EXIST
INVERT         EQU   $CE26      ;TOGGLE NORMAL/INVERSE
PICK           EQU   $CE44      ;PICK CHAR OFF SCREEN

* INPUT SUBS
RDKEY          EQU   $FD0C
RDCHAR         EQU   $FD35
KEYIN          EQU   $FD1B
BASICIN        EQU   $C305
GETLN          EQU   $FD6A
GETLN1         EQU   $FD6F      ;GETLN WITH NO PROMPT
NOESC          EQU   $C9B7      ;HANDLES KEY OTHER THAN ESC
BINPUT         EQU   $C8F6
ESCAPING       EQU   $C918
IN             EQU   $200       ;256-CHAR INPUT BUFFER
RD80VID        EQU   $C01F

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

SET80COL       EQU   $C001      ;ENABLE AUXILIARY MEM SWITCHING
PAGE2OFF       EQU   $C054      ;TURN ON MAIN MEMORY
PAGE2ON        EQU   $C055      ;TURN ON AUXILIARY MEMORY

DEBUG          EQU   1
DEBUG2         EQU   0


********************************
* PUSHY MACRO                  *
********************************
PUSHY	mac
	tya
	pha
	<<<

********************************
* POPY MACRO                   *
********************************
POPY	mac
	pla
	tay
	<<<

********************************
* PUSHXY MACRO                 *
********************************
PUSHXY	mac
	txa
	pha
	tya
	pha
	<<<

********************************
* POPYX MACRO                  *
********************************
POPYX	mac
	pla
	tay
	pla
	tax
	<<<

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

PUTS	MAC
	PUSHY
	LDA	#<]1	;PUT LOW BYTE INTO A
	LDY	#>]1	;PUT HIGH BYTE INTO Y
	JSR	STROUT	;CALL APPLESOFT'S STRING PRINT
	POPY
	<<<

PRINTHEX       MAC
               PHA
               PUSHXY
               lda   ]1
               JSR   PRBYTE
               POPYX
               PLA
               <<<

********************************
*                              *
* INSTALL VECTOR TO HANDLER    *
*                              *
********************************

MAIN           LDA   #<DELHNDLR
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

DELHNDLR       STA   ORIGCURS   ;STORE THE ORIGINAL CURSOR CHAR
               STY   CURSPOS
               PUSHXY

               LDA   ORIGCURS   ;FOLLOWING CODE NEEDS THIS
               BIT   RDALTCHAR  ;TEST FOR 80-COL ON
               BMI   COL80

***********************************************************************
COL40          JSR   GETKEY40   ;LOAD "KEY" VARIABLE
               JSR   DEL2BS     ;CONVERT DELETE TO BACKSPACE
               STA   KEY        ;STORE IT BECAUSE A WILL GET WIPED
               JMP   FINISH
***********************************************************************

***********************************************************************
COL80          
               LDY   OURCH
               JSR   PICK
               STA   CURSOR80
               JSR   INVERT
*               JSR   PUTCHAR80

NEXTKEY        JSR   GETKEY80   ;GET KEYBOARD KEY IN ACCUMULATOR
               JSR   DEL2BS
               STA   KEY
               CMP   #ESC       ;IS IT ESC?
               BNE   NOT_ESC    ;IGNORE ESC
               LDA   #" "       ;PREP FOR PUTCHAR80
               LDY   OURCH      ;PREP FOR PUTCHAR80
               JSR   PUTCHAR80  ;ERASE CURSOR SO ESCAPEING WORKS PROPERLY
               JSR   ESCAPING   ;HANDLE ESCAPE SEQUENCES
               JMP   FINISH
NOT_ESC        CMP   #RTARROW   ;IS IT A RIGHT ARROW
               BNE   NOTRTARROW ;NOT RIGHT ARROW THEN DONE
RTARROWHIT     LDY   OURCH      ;GET HORIZONTAL CURSOR POSITION
               JSR   PICK       ;GRAB CHAR FROM SCREEN
               ORA   #$80       ;SET HIGH BIT
               STA   KEY
NOTRTARROW
               LDY   OURCH
               JSR   INVERT
*               JSR   PUTCHAR80
***********************************************************************

FINISH         POPYX            ;RESTORE X AND Y
               LDA   KEY        ;LOAD RETURN VALUE
               RTS

********************************
*                              *
* GETKEY40 SUBROUTINE          *
* ORIGINAL CURSOR MUST BE IN A *
* KEY TYPED IS PUT INTO A      *
*                              *
********************************

GETKEY40       BIT   KBD        ;TEST FOR KEY PRESSED
               BPL   GETKEY40   ;WAIT FOR KEY PRESSED
               STA   (BASL),Y   ;CLEAR CURSOR
               LDA   KBD        ;GET THE KEY THAT WAS PRESSED
               BIT   KBDSTRB    ;CLEAR KEYBOARD STROBE
               RTS

********************************
*                              *
* GETKEY80 SUBROUTINE          *
* ORIGINAL CURSOR MUST BE IN A *
* KEY TYPED IS PUT INTO A      *
*                              *
********************************

GETKEY80       BIT   KBD        ;TEST FOR KEY PRESSED
               BPL   GETKEY80   ;WAIT FOR KEY PRESSED
               LDA   KBD        ;GET THE KEY THAT WAS PRESSED
               BIT   KBDSTRB    ;CLEAR KEYBOARD STROBE
               RTS

********************************
*                              *
* DEL2BS SUBROUTINE            *
*                              *
* PRECONDITIONS:               *
* 1. KEY IS IN ACCUMULATOR     *
*                              *
* POSTCONDITIONS:              *
* 1. KEY IS IN ACCUMULATOR     *
*                              *
********************************

DEL2BS         CMP   #DELETE    ;IS THE KEY IN A THE DELETE KEY
               BNE   D2BDONE
               LDA   #BKSPACE
D2BDONE        RTS

********************************
*                              *
* PUTC80 SUBROUTINE            *
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

INVERSECHAR
            CMP #0
            BMI NORM2INV
            ORA #%10000000
            RTS
NORM2INV    AND #%01111111
            RTS

********************************
*                              *
* DATA                         *
*                              *
********************************

LOADMSG        ASC   "LOADED DELETE KEY HANDLER",0D,00
KEY            DB    0
ORIGCURS       DB    0
CURSPOS        DB    0
CURSOR80       DB    0


