; ---------------------------------
; Mikrokontroller alapú rendszerek
; 8051 assembly hazi feladat
; Bircher Péter
; ---------------------------------
; FELADAT:
;
; Belso memoriaban lévő két darab 16
; bites előjeles szám osztása,
; 16 bites hányados és 16 bites
; maradék is szükséges. 
; Bemenet: operandusok, eredmény és
; maradék címei (mutatók).
; Kimenet: eredmény, maradék
; ---------------------------------

MAIN:
	MOV 0x40, #0x00	            ; BELSŐ MEMÓRIÁBAN LÉVŐ 16 BITES SZÁMOK
	MOV 0x41, #0x80             ; INICIALIZÁLÁSA
	MOV 0x42, #0x00				; OSZTANDO: 0x40-0x41
	MOV 0x43, #0x02             ; OSZTO: 0x42-0x43 CÍMEN TALÁLHATÓ
	
	
	MOV R0, #0x30               ; EREDMÉNYRE MUTATÓ CÍM
	MOV r1, #0x50               ; MARADÉKRA MUTATÓ CÍM
	MOV R4, 0x41               
	MOV R5, 0x40                ; OSZTANDÓ
	MOV R2, 0x43 
	MOV R3, 0x42                ; OSZTÓ
	
	CALL    S_DIV_16            ; SZUBRUTIN HÍVÁSA
	LJMP    ENDLESS_LOOP        ; VÉGTELEN CIKLUS

; -------------------------------
; SZUBRUTIN: S_DIV_16
;
; Bemeneti parameterek:
; 	R5/R4 regiszter: Osztandó
;   R3/R2 regiszter: Osztó
;	R1: maradék címei 
;	R0: eredmény címei 
;
; Kimeneti parameterek:
; 	Az r0 címén tároljuk az
;	eredményt
;	r1 címén pedig a
;	a maradékot
; --------------------------------	
	
S_DIV_16:      
		   PUSH 	0x24
	       PUSH    dpl             ; REGISZTEREK ELMENTÉSE
           PUSH    dph
           PUSH    B
			MOV 0x24, #0
           MOV     A, R3           ; OSZTÓ FELSŐ- ÉS ALSÓBÁJTJÁNAK
           ORL     A, R2           ; VAGY-OLÁSA
           JNZ     DIVIDE          ; HA NEM NULLA, FOLYTATHATJUK
           RET                     ; EGYÉBKÉNT NULLÁVAL NEM OSZTUNK

DIVIDE:
 
; -----------------------------------------
; SIGN_DIVIDEND: Osztandó előjelvizsgálata
;
; Bemenő paraméterek: R5 regiszter (osztandó felső bájtja)
; Ha legfelső bit 1-es, akkor
; Kettes-komplemens képzés (COMPL_DIVIDEND)
; És előjel-flag (Belső memória: 0x24) beállítása
;
; Kimenő paraméterek: R1 regiszter, előjel-flag (21h)
; -----------------------------------------
 
SIGN_DIVIDEND:         
			   MOV     A, R5                      ; FELSŐ BÁJT VIZSGÁLATA
               JB      ACC.7, COMPL_DIVIDEND      ; HA A LEGELSŐ BIT 1, NEGATÍV
			   CLR     21H                        ; ELŐJEL-FLAG TÖRLÉSE, HA POZITÍV
               JMP	   SIGN_DIVISOR                 

COMPL_DIVIDEND:
               SETB    21H             ; ELŐJEL-FLAG BEÁLLÍTÁSA
               MOV     A, R4           ; ALSÓBÁJT NEGÁLÁSA
               CPL     A               ; 
               ADD     A, #1           ; VESSZÜK A KETTES KOMPLEMENSÉT
               MOV     R4, A 
               MOV     A, R5           ; FELSŐBÁJT KETTES KOMPLEMENSE
               CPL     A               ;
               ADDC    A, #0		   ; HA AZ ALSÓ BÁJTNÁL KELETKEZETT TÚLCSORDULÁS,									
               MOV     R5, A		   ; AKKOR HOZZÁADJUK
			   
; -----------------------------------------
; SIGN_DIVISOR: Osztó előjelvizsgálata
;
; Bemenő paraméterek: R3 regiszter (osztó felső bájtja)
; Ha legfelső bit 1-es, akkor
; Kettes-komplemens képzés (COMPL_DIVISOR)
; És előjel-flag (Belső memória: 0x24) beállítása
;
; Kimenet: R3 regiszter, előjel-flag (22h)
; -----------------------------------------
			   
			   
SIGN_DIVISOR:         
			   MOV     A, R3           	         ; FELSŐ BÁJT VIZSGÁLATA
               JB      ACC.7, COMPL_DIVISOR      ; HA A LEGELSŐ BIT 1, NEGATÍV
               CLR     22H                       ; ELŐJEL-FLAG TÖRLÉSE, HA POZITÍV
               JMP	   US_16_DIV                     
COMPL_DIVISOR:           
		       SETB    22H                       ; ELŐJEL-FLAG BEÁLLÍTÁSA
               MOV     A, R2                     ; ALSÓBÁJT NEGÁLÁSA
               CPL     A                         ; VESSZÜK A KETTES KOMPLEMENSÉT
               ADD     A, #1                     ; AND ADD +1
               MOV     R2, A 
               MOV     A, R3                     ; FELSŐBÁJT KETTES KOMPLEMENSE
               CPL     A               
               ADDC    A, #0		             ; HA AZ ALSÓ BÁJTNÁL KELETKEZETT TÚLCSORDULÁS,	
               MOV     R3, A		             ; AKKOR HOZZÁADJUK

; --------------------------------------------------------------------------------
; US_16_DIV: 16 bites előjel nélküli osztás
; Bemenő paraméterek: R0, R1, R2, R3
; További felhasznált regiszterek: R4, R5 - eredménynek, R6, R7 - maradéknak
; Lényege, hogy az osztandó bitjeit egyesével beforgatjuk egy másik regiszterbe,
; és minden egyes alkalommal megpróbáljuk belőle kivonni az osztót. (kacsacsőr helyetti összehasonlítás)
; Ha a kérdéses
; szám kisebb, mint az osztó, akkor keletkezik átvitel (CY = 1), ilyenkor nullát mozgatunk
; az eredmény regisztereibe. Ha nincs túlcsordulás, tehát a számunk nagyobb vagy egyenlő, mint az osztót,
; akkor egyest mozgatunk az eredmény regisztereibe, és a kivonás eredményével frissítjük a parciális maradék
; regisztert.
; Kimenete: r4/r5 + R0 címen - eredmény, R2,R3 + r1 címen - maradék
; ---------------------------------------------------------------------------------			   
			   
US_16_DIV:    
				MOV		@R1, #0x00
				INC      R1	
				MOV		@R1, #0x00
				DEC		R1
				MOV		@R0, #0x00
				INC     R0	
				MOV		@R0, #0x00
				DEC		R0
                MOV     B, #16          ; CIKLUSSZÁMLÁLÓ: 16

DIV_LOOP:      CLR     C               ; CARRY FLAG TÖRLÉSE
               MOV     A, R4           ; A MAGASABB BÁJTJÁT AZ OSZTANDÓNAK SHIFTELJÜK
               RLC     A               ; ...
               MOV     R4, A
               MOV     A, R5
               RLC     A
               MOV     R5, A
               MOV     A, @R1          ; ... A PARCIÁLIS MARADÉK
               RLC     A               ; ALSÓ BÁJTJÁBA
               MOV     @R1, A
			   INC 		R1
               MOV     A, @R1
               RLC     A
               MOV     @R1, A
			   DEC		R1
               MOV     A, @R1          ; MEGPRÓBÁLJUK KIVONNI AZ OSZTÓT
               CLR     C               ; A PARCIÁLIS MARADÉKBÓL
               SUBB    A, R2
               MOV     DPL, A
			   INC 	   R1
               MOV     A, @R1
			   DEC     R1
               SUBB    A, R3
               MOV     DPH, A
               CPL     C               ; NEGÁLJUK A CARRY-T, MERT HA NEM KELETKEZETT ÁTVITEL
               JNC     DIV_1           ; AKKOR SZÜKSÉGÜNK LESZ A CARRY = 1-RE
               MOV     @R1, DPL 
			   INC     R1              ; ILYENKOR FRISSÍTJÜK A
               MOV     @R1, DPH
			   DEC 	   R1              ; PARCIÁLIS MARADÉKOT
DIV_1:         MOV     A, @R0          ; EREDMÉNY FORGATÁSA ...
               RLC     A               
               MOV     @R0, A
			   INC	   R0
               MOV     A, @R0
               RLC     A
               MOV     @R0, A
			   DEC     R0	           ; ... A KVÓCIENS REGISZTEREKBE
               DJNZ    B, DIV_LOOP     ; HA B = 0, AKKOR VÉGEZTÜNK, EGYÉBKÉNT FOLYTATJUK
               MOV     A, @R0          ; EREDMÉNY BEÍRÁSA R5/R4-BE
               MOV     R4, A
			   INC	   R0
               MOV     A, @R0
               MOV     R5, A
               MOV     A, @R1           ; AZ UTOLSÓ KIVONÁSNÁL KELETKEZETT MARADÉK
               MOV     R2, A  
			   INC     R1               ; MOZGATÁSA R3/R2-BE
               MOV     A, @R1
               MOV     R3, A
			   DEC		R0
			   DEC        R1

; ------------------------------------------
; MR4R5: Eredmény előjelkorrekciója
;
; Bemenő paraméterek: R4, R5
; Ha mind az osztó, mind az osztandó
; Negatív/pozitív előjelű volt, nincs dolgunk
; Egyébként kettes-komplemens képzés, mentés
; Majd visszatérés
;
; Kimenő paraméterek: r0 címén
; -------------------------------------------			   
			   
MR4R5:         JB      21H, MR4R5B     ; HA AZ OSZTÓ, NEGATÍV
               JB      22H, MR4R5A     ; HA AZ OSZTANDÓ VOLT NEGATÍV
               JMP	   NEXT 

MR4R5B:        JNB     22H, MR4R5A	   ; HA AZ OSZTANDÓ POZITÍV, AKKOR NEGATÍV AZ EREDMÉNY
               JMP	   NEXT		   ; HA AZ OSZTANDÓ IS NEGATÍV VOLT, NINCS TÖBB DOLGUNK, POZITÍV A VÉGEREDMÉNY

MR4R5A:        MOV     A, R4           ; VESSZÜK AZ EREDMÉNY KETTES KOMPLEMENSÉT
               CPL     A               ; 
               ADD     A, #1           ; MAJD VISSZAUGRUNK
               MOV     r4, A 
               MOV     A, R5            
               CPL     A               
               ADDC    A, #0
               MOV     r5, A
				MOV	   a, r4
				MOV		@r0, a
				inc		r0
				mov a, r5
				mov 	@r0, a
				dec r0
			   

NEXT:         CLR    C			      ; CARRY FLAG TÖRLÉSE
	          POP    B
              POP    dph
              POP    dpl
			  POP    0x24
			RET
			
; ---------------------------------
; ENDLESS LOOP: Vegtelen ciklus - törésépont, előáll a megoldás
; ---------------------------------			
			
ENDLESS_LOOP:
ENDLESS:      LJMP ENDLESS			