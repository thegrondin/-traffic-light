;
; Thomas Dion-Grondin
; D�cembre 2020
;
;****************************************************************************
; MCU TYPE
;****************************************************************************
	LIST	p=18F4680     ; d�finit le num�ro du PIC pour lequel ce programme sera assembl�

;****************************************************************************
; INCLUDES
;****************************************************************************
#include	 <p18f4680.inc>	;  La directive "include" permet d'ins�rer la librairie "p18f4680.inc" dans le pr�sent programme.
				; Cette librairie contient l'adresse de chacun des SFR ainsi que l'identit� (nombre) de chaque bit 
				; de configuration portant un nom pr�d�fini.

;****************************************************************************
; MCU DIRECTIVES   (d�finit l'�tat de certains bits de configuration qui seront charg�s lorsque le PIC d�butera l'ex�cution)
;****************************************************************************
    CONFIG	OSC = ECIO           
    CONFIG	FCMEN = OFF        
    CONFIG	IESO = OFF       
    CONFIG	PWRT = ON           
    CONFIG	BOREN = OFF        
    CONFIG	BORV = 2          
    CONFIG	WDT = OFF          
    CONFIG	WDTPS = 256       
    CONFIG	MCLRE = ON          
    CONFIG	LPT1OSC = OFF      
    CONFIG	PBADEN = OFF        
    CONFIG	STVREN = ON     
    CONFIG	LVP = OFF         
    CONFIG	XINST = OFF       
    CONFIG	DEBUG = OFF         
  

;************************************************************
ZONE1_UDATA	udata 0x60 	; La directive "udata" (unsigned data) permet de d�finir l'adresse du d�but d'une zone-m�moire
				; de la m�moire-donn�e (ici 0x60).
				; Les directives "res" qui suivront, d�finiront des espaces-m�moire � partir de cette adresse.
				; La zone doit porter un nom unique (ici "ZONE1_UDATA") car on peut en d�finir plusieurs.
				
Count	 	res 1 		; La directive "res" r�serve un seul octet qui pourra �tre r�f�renc� �l'aide du mot "Count".
				; L'octet sera localis� � l'adresse 0x60 (dans la banque 0).

Output		res 1
Delay_pointer	res 1
		
ZONE2_UDATA	udata 0x70

GREEN_DELAY	res 1
YELLOW_DELAY	res 1	
RED_DELAY	res 1				

;************************************************************
; reset vector
 
Zone1	code 00000h		; La directive "code" d�finit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionn�es �la suite.
				; Elles formeront une zone dont le nom sera "Zone1".
				; Ici, l'instruction "goto" sera donc stock�e � l'adresse 00000h dans la m�moire-programme. 
				
	goto Start		; Le micro-contr�leur saute � l'adresse-programme d�finie par l'�tiquette "Start".

;************************************************************
; interrupt vector
 
Zone2	code	00008h		; La directive "code" d�finit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionn�es �la suite.
				; Elles formeront une zone dont le nom sera "Zone2".
				; Ici, l'instruction "btfss" sera donc stock�e � l'adresse 00008h dans la m�moire-programme.
				;
				; NOTE IMPORTANTE: Lorsque le micro-contr�leur subit une interruption, il interrompt le programme
				;                  en cours et saute � l'adresse 00008h pour ex�cuter l'instruction qui s'y trouve.
				;                  
	
	btfsc	INTCON, TMR0IF	; Teste la valeur du bit nomm� "TMR0IF" de l'espace-m�moire associ�e � INTCOM. Ce bit est en fait 
				; le bit num�ro 2 selon la description d�taill�e du micro-contr�leur PIC. 
				; Ainsi, si ce bit est � 1, le temporisateur 0 est bien la source de l'interruption.
				; Si ce bit est � 0 (clear), on sautera l'instruction suivante (call TO_ISR). 
	
	call	TO_ISR		; Ex�cute la sous-routine d�butant � l'adresse "TO_ISR"
	retfie			; Cette instruction force le retour � l'instruction qui a �t� interrompue lors de l'interruption.


;************************************************************
;program code starts here

Zone3	code	00020h		; Ici, la nouvelle directive "code" d�finit une nouvelle adresse (dans la m�moire-programme) pour 
				; la prochaine instruction. Cette derni�re sera ainsi localis�e � l'adresse 020h
				; Cette nouvelle zone de code est nomm�e "Zone3".

Start				; Cette �tiquette pr�c�de l'instruction "bcf". Elle sert d'adresse destination � l'instruction "goto" apparaissant plus haut.
	
	clrf	TRISC		; 
	clrf	TRISD		; d�finit tous les bits du port D en sorties
	setf	TRISB		; d�finit tous les bits du port B en entr�es 
	
	movlw	d'10'
	movwf	GREEN_DELAY	; Transf�re le contenu de WREG dans l'espace m�moire GREEN_DELAY. Dans ce cas, 10 repr�sentant des secondes
	
	movlw	d'3'
	movwf	YELLOW_DELAY	; Transf�re le contenu de WREG dans l'espace m�moire GREEN_DELAY. Dans ce cas, 10 repr�sentant des secondes
	
	movlw	d'15'
	movwf	RED_DELAY	; Transf�re le contenu de WREG dans l'espace m�moire GREEN_DELAY. Dans ce cas, 10 repr�sentant des secondes
	
	movlw	0x71
	movwf	Delay_pointer	; Espace m�moire pointant vers le prochain d�lais a effectuer pour le controle du feu de circulation

	movlw	0x01		 
	movwf	PORTC		; Copier le contenu de WREG (dans ce cas 1) dans PORTC. Dans ce cas, le bit 0 de PORTC sera actif.
	
	movlw	0x02
	movwf	Output		; Copier le contenu de WREG (b(10)) dans l'espace m�moire Output. Permettra de signifier le prochain bit a activer dans PORTC

	movff	GREEN_DELAY, Count ; Copier le contenu de GREEN_DELAY dans Count. permet de d�finir le d�lais actuel en seconde dans l'espace m�moire Count.
	
	movlw	0x07		; Charge la valeur 0x07 dans le registre WREG
	movwf	T0CON		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � T0CON
				; Ces 8 bits (00000111) configure le micro-contr�leur de telle
				; sorte que le temporisateur 0 soit actif, qu'il op�re avec 16 bits,
				; qu'il utilise un facteur d'�chelle ainsi que l'horloge interne
				; => voir la page 149 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw	0xf6		; Charge la valeur 0xff dans le registre WREG
	movwf	TMR0H		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0H
	movlw	0xfF		; Charge la valeur 0xf2 dans le registre WREG
	movwf	TMR0L		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0L
				; (le temporisateur op�rant sur 16 bits, la valeur de d�part est dont 0xfff2)
				
	bcf	INTCON, TMR0IF	; Met � z�ro le bit appel� TMR0IF (bit 2 de l'espace-m�moire associ� � INTCON)
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc r�initialis� � 0.
				
	bsf	T0CON, TMR0ON	; Met � 1 le bit appel� TMR0ON (bit 7 de l'espace-m�moire associ� � T0CON)
				; => voir la page 149 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le temporisateur 0 est donc d�marr�.
				
	bsf	INTCON, TMR0IE	; Met � 1 le bit appel� TMR0IE (bit 5 de l'espace-m�moire associ� � INTCON)
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise le temporisateur � interrompre le micro-contr�leur lorsque le temporisateur viendra � �ch�ance (00000000).
				
	bsf	INTCON, GIE	; Met � 1 le bit appel� GIE (bit 7 de l'espace-m�moire associ� � INTCON)
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont �t� valid�es.

loop
	btg	PORTC, 3		; Inverse ("toggle") la valeur courante du bit 2 stock� dans l'espace-m�moire associ� au port C
	movff	PORTB, PORTD	; Copie le contenu du port B dans le port D
	bra	loop		; Saute � l'adresse "loop" (soit l'adresse de l'instruction "btg")

Zone4	code 0x100		; Ici, la nouvelle directive "code" d�finit une nouvelle adresse (dans la m�moire-programme) pour 
				; la prochaine instruction. Cette derni�re sera ainsi localis�e � l'adresse 0x100
				; Cette nouvelle zone de code est nomm�e "Zone4".

TO_ISR				; Cette �tiquette pr�c�de l'instruction "movlw". Elle sert d'adresse destination � l'instruction "goto" apparaissant plus haut.
				; Les instructions qui suivent forment la sous-routine de gestion des interruptions.
				
				; Tout d'abord, on commence par r�initialiser la valeur initiale du temporisateur
	movlw	0xf6		; Charge la valeur 0xff dans le registre WREG
	movwf	TMR0H		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0H
	movlw	0xff		; Charge la valeur 0xf2 dans le registre WREG
	movwf	TMR0L		; Copie le contenu du registre WREG dans l'espace-m�moire associ� � TMR0L
				; (le temporisateur op�rant sur 16 bits, la valeur de d�part est dont 0xfff2)
	
	bcf	INTCON, TMR0IF	; Met � z�ro le bit appel� TMR0IF (bit 2 de l'espace-m�moire associ� � INTCON)
				; => voir la page 105 de la documentation sur le micro-contr�leur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc r�initialis� � 0.

	decf	Count		; d�cr�mente le contenu de l'espace-m�moire associ� � "Count"
	bnz	saut		; saute � l'adresse associ�e � "saut" si le bit Z du registre de statut est � 0
				; Il y a donc un branchement si la valeur "Count" n'est pas nulle ("non zero").
	
	movff	Output, PORTC	; Copier le contenu de l'espace m�moire de Output dans PORTC. Permet de signifer quels pins de PORTC seront actifs

	movff	Delay_pointer, 	FSR0L ; Permet d'acc�der au d�lais a partir d'un pointeur pointant 
	movff	INDF0, Count	      ; vers une adresse m�moire entre GREEN_DELAY, YELLOW_DELAY et RED_DELAY a l'aide de L'adressage indirect.	Stocker le r�sulat dans Count
	incf	Delay_pointer	      ; Incr�menter le pointeur pour permettre d'acc�der au prochain d�lais de la prochain couleur.
	
	movlw	b'100'		      
	bcf	STATUS,C
	cpfslt	Output		       ; Si la sortie est inf�rieur a b(100), passer la prochaine instruction
	call	ResetCycle	       ; Sinon, executer ResetCycle. Si la sortie est sup�rieur a b(100), ceci signifit que le programme a fait un cycle complet. Nous devons le recommencer
	
	rlcf	Output		       ; Permet de faire une rotation de bits l'espace m�moire Output vers la gauche. 
				       ; Permet de signifier la nouvelle pin a activer pour le prochain cycle.

saut
	return			; Provoque le retour � l'instruction suivant l'appel de la sous-routine 
				; qui a d�but� � l'adresse "TO_ISR"

ResetCycle
	
	clrf	Output		 ; Clear l'espace m�moire Output
	bsf	STATUS,C	 ; Fixer a 1 le bit C de STATUS pour permettre d'avoir un bit a la position la moins significative lors de la rotation
	
	movlw	0x70		 
	movwf	Delay_pointer	 ; Faire �galer a 0x70 le pointeur des d�lais. Le commencement de cet espace m�moire
	
	return
	END



	


	
