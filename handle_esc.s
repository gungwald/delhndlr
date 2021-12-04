HANDLE_ESC
               JSR   ESC_ON
               JSR   GETKEY
               JSR   ESC_OFF
               JSR   UPSHFT
               AND   #$7F
               LDY   #$10
ESC2           CMP   ESCTAB,Y
               BEQ   ESC3
               DEY
               BPL   ESC2
               BMI   ESCSPEC
ESC3           LDA   ESCCHAR,Y
               AND   #$7F
               JSR   CTLCHAR
               LDA   ESCCHAR,Y
               BMI   HANDLE_ESC
               RTS               ;WAS JMP B.INPUT
ESCSPEC        TAY
               LDA   DOS33_MODE
               CPY   #$11
               BNE   ESCSP1
               JSR   X_NAK
               LDA   #$98
               STA   A2C_CHAR
               RTS               ;WAS JMP BIORET
ESCSP1         CPY   #$05
               BNE   ESCSP4
               AND   #$DF
ESCSP2         STA   DOS33_MODE
ESCSP3         RTS               ;WAS JMP B.INPUT
ESCSP4         CPY   #$04
               BNE   ESCSP3
               ORA   #$20
               BNE   ESCSP2
               RTS               ;DID NOT EXIST IN ORIGINAL