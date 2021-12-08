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
	DSK	del2bs40	;OUTPUT FILE NAME
	USE	symbols
	USE	register.macs
	USE	string.macs

********************************
*                              *
* INSTALL VECTOR TO DEL2BS40   *
* SUBROUTINE                   *
*                              *
********************************
MAIN	BIT	RDALTCHAR
	BMI	EIGHTY
	LDA	#<DEL2BS40
	STA	KSWL
	LDA	#>DEL2BS40
	STA	KSWH
	WRSTR	LOADMSG
	JMP	DONE
EIGHTY	WRSTR	WRONGMODE
DONE	RTS

********************************
*                              *
* KEYBOARD INPUT SUBROUTINE    *
*                              *
* PRECONDITIONS:               *
* 1. CURSOR AT CH & BASL       *
*    - only works with 40-col  *
* 2. ACCUM = ORIG SCREEN BYTE  *
*    - only works with 40-col  *
* 3. Y = VALUE IN CH           *
*    - only works with 40-col  *
*                              *
* POSTCONDITIONS:              *
* 1. MUST RETURN CHAR IN ACCUM *
* 2. X & Y MUST NOT BE CHANGED *
*                              *
********************************
DEL2BS40
	STA	CURSOR		;STORE THE ORIGINAL CURSOR CHAR
	STY	CURSPOS
	JSR	GETKEY		;STORE USER-ENTERED KEY IN A
	JSR	CONV_DELETE
	STA	KEY		;STORE IT BECAUSE A WILL GET WIPED
	JSR	REPLACE_CURSOR
	LDA	KEY		;SETUP RETURN VALUE
	RTS

********************************
*                              *
* CONV_DELETE SUBROUTINE       *
*                              *
* INPUTS:                      *
*   A - CONTAINS A CHARACTER   *
*                              *
* OUTPUTS:                     *
*   A - BACKSPACE CHAR IF      *
*       ACCUMULATOR CONTAINED  *
*       A DELETE CHAR, OTHER-  *
*       WISE IT IS UNCHANGED   *
*                              *
* REGISTERS:                   *
*   A - CHANGED. SEE ABOVE     *
*   X - PRESERVED              *
*   Y - PRESERVED              *
*                              *
********************************
CONV_DELETE
	CMP	#DELETE		;IS THE KEY IN A THE DELETE KEY
	BNE	D2BDONE
	LDA	#BKSPACE
D2BDONE	RTS

********************************
*                              *
* REPLACE_CURSOR SUBROUTINE    *
*                              *
* INPUTS:                      *
*   CURSOR                     *
*   CURSPOS                    *
*                              *
* OUTPUTS:                     *
*   NONE                       *
*                              *
* REGISTERS:                   *
*   A - CONTAINS CURSOR        *
*   X - PRESERVED              *
*   Y - CONTAINS CURSPOS       *
*                              *
********************************
REPLACE_CURSOR
	LDA	CURSOR
	LDY	CURSPOS
	STA	(BASL),Y
	RTS

********************************
*                              *
* DATA                         *
*                              *
********************************
LOADMSG	ASC	"LOADED DELETE TO BACKSPACE CONVERTER",0D,00
WRONGMODE
	ASC	"THIS WILL NOT WORK IN 80-COLUMN MODE",0D,00
KEY	DB	0
CURSOR	DB	0
CURSPOS	DB	0
