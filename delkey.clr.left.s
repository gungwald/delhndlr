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
CXROMOFF       EQU   $C006      ;ENABLE SLOT ROMS
CXROMON        EQU   $C007      ;TURN ON INTERNAL ROM
80COLOFF       EQU   $C00C      ;Off: display 40 columns
80COLON        EQU   $C00D      ;On: display 80 columns
KBDSTRB        EQU   $C010      ;CLEAR KEYBOARD STROBE
ALTCHAR        EQU   $C01E      ;Alt char set (1 = on)
COUT           EQU   $FDED      ;WRITE A CHARACTER

* 80-COL SUBS INSIDE THE INTERNAL ROM
GETKEY         EQU   $CB15      ;THIS DOES NOT SEEM TO EXIST
INVERT         EQU   $CEDD      ;INVERT CHAR ON SCREEN - DOES NOT WORK
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
               PUSHY
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
               PUSHXY

               LDA   ORIGCURS   ;FOLLOWING CODE NEEDS THIS
               BIT   ALTCHAR    ;TEST FOR 80-COL ON
               BMI   COL80

***********************************************************************
COL40          JSR   GETKEY40   ;LOAD "KEY" VARIABLE
               JSR   DEL2BS     ;CONVERT DELETE TO BACKSPACE
               STA   KEY        ;STORE IT BECAUSE A WILL GET WIPED
               JMP   FINISH
***********************************************************************

***********************************************************************
COL80          
               STA   (BASL),Y
               PUTC80 #' ';OURCH
NEXTKEY        JSR   GETKEY80   ;GET KEYBOARD KEY IN ACCUMULATOR
               CMP   #ESC       ;IS IT ESC?
               BNE   NOT_ESC    ;IGNORE ESC
               JSR   ESCAPING   ;HANDLE ESCAPE SEQUENCES
               JMP   NEXTKEY
NOT_ESC        CMP   #RTARROW   ;IS IT A RIGHT ARROW
               BNE   NOTRTARROW ;NOT RIGHT ARROW THEN DONE
RTARROWHIT     LDY   OURCH      ;GET HORIZONTAL CURSOR POSITION
               JSR   PICK       ;GRAB CHAR FROM SCREEN
               ORA   #$80       ;SET HIGH BIT
NOTRTARROW     JSR   DEL2BS     ;CONVERT DELETE TO BACKSPACE
               STA   KEY        ;IT WILL GET WIPED
               PUTC80 #" ";OURCH
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
* DATA                         *
*                              *
********************************

LOADMSG        ASC   "LOADED DELETE KEY HANDLER",0D,00
KEY            DB    0
ORIGCURS       DB    0


