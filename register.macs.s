********************************
*                              *
* APPLE II MACROS              *
*                              *
* AUTHOR:  BILL CHATFIELD      *
* LICENSE: GPL                 *
*                              *
********************************

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
* PUSHAXY MACRO                *
********************************
PUSHAXY	MAC
	PHA
	TXA
	PHA
	TYA
	PHA
	<<<

********************************
* POPYXA MACRO                  *
********************************
POPYXA	MAC
	PLA
	TAY
	PLA
	TAX
	PLA
	<<<
 