********************************
*                              *
* DELETE KEY TO BACKSPACE      *
* CONVERTER                    *
*                              *
* AUTHOR:  BILL CHATFIELD      *
* LICENSE: GPL                 *
*                              *
********************************

***********************************************************
* INPUT SUBROUTINE CALL SEQUENCE:                         *
* GETLN ($FD6A) - READS A LINE INTO IN ($200) LENGTH IN X *
* '->RDCHAR ($FD35) - HANDLES ESC SEQUENCES FOR 40 COLUMN *
*    '->RDKEY ($FD0C) - READS CHAR INTO ACCUMULATOR       *
*       '->KSW ($38) - POINTS TO KEYIN ($FD1B) FOR 40-COL *
*                      OR BASICIN ($C305) FOR 80-COL,     *
*                      DELHNDLR IN THIS FILE, OTHER OTHER *
*                      CUSTOM SUBROUTINE. BASICIN HANDLES *
*                      ESC SEQUENCES FOR 80-COLUMN.       *
***********************************************************

	ORG	$300
	TYP	$06		;BINARY TYPE
	DSK	del2bs80        ;OUTPUT FILE NAME
	USE	symbols
	USE	register.macs
	USE	string.macs

********************************
*                              *
* INSTALL VECTOR TO DEL2BS     *
* SUBROUTINE                   *
*                              *
********************************
MAIN	BIT	RDALTCHAR
	BPL	FORTY
	LDA	#<DEL2BS80
	STA	KSWL
	LDA	#>DEL2BS80
	STA	KSWH
	WRSTR	LOADMSG
	JMP	DONE
FORTY	WRSTR	WRONGMODE
DONE	RTS

********************************
*                              *
* 80-COL DEL2BS SUBROUTINE     *
*                              *
********************************
DEL2BS80
	PUSHY
	LDY	OURCH		;GET CURSOR POSITION
	JSR	PICK		;GET CURSOR CHARACTER
	STA	CURSOR80	;REMEMBER CURSOR CHARACTER
	JSR	INVERT		;INVERT CHAR AT CURSOR POSITION
NEXTKEY	JSR	GETKEY		;GET KEYBOARD KEY IN ACCUMULATOR
	JSR	CONV_DEL2BS
	STA	KEY		;REMEMBER WHAT KEY WAS TYPED
	CMP	#ESC		;IS IT ESC?
	BNE	NOT_ESC		;KEY IS NOT ESC

	JSR	INVERT		;PREP FOR ESCAPING CURSOR
	JSR	HANDLE_ESC
	JMP	DEL2BS80
NOT_ESC	CMP	#RTARROW	;IS IT A RIGHT ARROW
	BNE	NOT_RT		;NOT RIGHT ARROW THEN DONE
	LDY	OURCH		;GET HORIZONTAL CURSOR POSITION
	JSR	PICK		;GRAB CHAR FROM SCREEN
	ORA	#$80		;SET HIGH BIT
	STA	KEY		;REMEMBER ARROW OVERED CHAR AS TYPED KEY
NOT_RT	LDY	OURCH		;SET CURSOR POSITION
	JSR	INVERT		;CURSOR CHAR MUST BE IN A
	POPY			;RESTORE X AND Y
	LDA	KEY		;LOAD RETURN VALUE
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
CONV_DEL2BS
	CMP	#DELETE		;IS THE KEY IN A THE DELETE KEY
	BNE	D2BDONE
	LDA	#BKSPACE
D2BDONE	RTS

********************************
*                              *
* HANDLE_ESC SUBROUTINE        *
*                              *
********************************
HANDLE_ESC
	PUSHY
	JSR	ESC_ON
	JSR	GETKEY
	JSR	ESC_OFF
	JSR	UPSHFT
	AND	#$7F
	LDY	#$10
ESC2	CMP	ESCTAB,Y
	BEQ	ESC3
	DEY
	BPL	ESC2
	JMP	ESCDONE
ESC3	LDA	ESCCHAR,Y
	AND	#$7F
	JSR	CTLCHAR
	LDA	ESCCHAR,Y
	BMI	HANDLE_ESC
ESCDONE	POPY
	RTS

********************************
*                              *
* DATA                         *
*                              *
********************************
LOADMSG	ASC	"LOADED DELETE TO BACKSPACE CONVERTER",0D,00
WRONGMODE
	ASC	"THIS WILL NOT WORK IN 40-COLUMN MODE",0D,00
KEY	DB	0
ORIGCURS DB	0
CURSPOS	DB	0
CURSOR80 DB	0
