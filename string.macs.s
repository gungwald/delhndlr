********************************
*                              *
* APPLE II MACROS              *
*                              *
* AUTHOR:  BILL CHATFIELD      *
* LICENSE: GPL                 *
*                              *
********************************

********************************
*                              *
* WRSTR MACRO                  *
*                              *
* WRITES AN ASCII 0 TERMINATED *
* STRING TO THE                *
* CURRENT OUTPUT DEVICE.       *
* THE STROUT SUBROUTINE IS     *
* USED, THE ADDRESS OF WHICH   *
* IS $DB3A. THAT IS IN THE     *
* APPLESOFT ROM LANGUAGE CARD, *
* WHICH CONSISTS OF THE        *
* FOLLOWING PROGRAMS:          *
*                              *
*   $D000-$F7FF APPLESOFT      *
*   $F800-$FFFF SYSTEM MONITOR *
*                              *
* INPUTS:                      *
*   ]1 - STRING TO WRITE       *
*                              *
* OUTPUTS:                     *
*   NONE                       *
*                              *
* REGISTERS:                   *
*   A - PRESERVED              *
*   X - PRESERVED              *
*   Y - PRESERVED              *
*                              *
********************************
WRSTR	MAC
	PUSHAXY
	LDA	#<]1	;PUT LOW BYTE INTO A
	LDY	#>]1	;PUT HIGH BYTE INTO Y
	JSR	STROUT	;CALL APPLESOFT'S STRING PRINT
	POPYXA
	<<<
