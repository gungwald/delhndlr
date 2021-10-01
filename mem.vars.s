********************************
*                              *
* PRINT MEMORY VARIABLES       *
*                              *
* AUTHOR:  BILL CHATFIELD      *
* LICENSE: GPL                 *
*                              *
********************************

            ORG $300
            TYP $06         ;BINARY TYPE
            DSK mem.vars    ;OUTPUT FILE NAME

RDALTCHAR   EQU $C01E
RD80COL     EQU $C01F
RD80STORE   EQU $C018

HEXDEC      EQU $ED24       ;HEX-TO-DECIMAL CONVERSION
CROUT       EQU $FD8E       ;PRINT A CARRIAGE RETURN
STROUT      EQU $DB3A       ;PRINT NULL-TERM STRING IN AY
* MONITOR SUBS
PRINTXY     EQU $F940       ;PRINT X & Y AS HEX
PRBYTE      EQU $FDDA       ;PRINT BYTE AS 2 HEX DIGITS

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

PUTS        MAC
            TYA             ;PRESERVE Y
            PHA
            LDA #<]1        ;PUT LOW BYTE INTO A
            LDY #>]1        ;PUT HIGH BYTE INTO Y
            JSR STROUT      ;CALL APPLESOFT'S STRING PRINT
            PLA             ;RESTORE Y
            TAY
            <<<

MAIN
            PUTS ALTCHLBL
            BIT RDALTCHAR
            JSR PRBYTE
            JSR CROUT

            PUTS 80COLLBL
            BIT RD80COL
            JSR PRBYTE
            JSR CROUT

            PUTS 80STOLBL
            BIT RD80STORE
            JSR PRBYTE
            JSR CROUT

            RTS

ALTCHLBL    ASC "ALTCHAR = ",00
80COLLBL    ASC "80COL   = ",00
80STOLBL    ASC "80STORE = ",00

