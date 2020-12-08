;
; Daniel Audet
; Juillet 2010
;
;****************************************************************************
; MCU TYPE
;****************************************************************************
	LIST	p=18F4680     ; définit le numéro du PIC pour lequel ce programme sera assemblé

;****************************************************************************
; INCLUDES
;****************************************************************************
#include	 <p18f4680.inc>	;  La directive "include" permet d'insérer la librairie "p18f4680.inc" dans le présent programme.
				; Cette librairie contient l'adresse de chacun des SFR ainsi que l'identité (nombre) de chaque bit 
				; de configuration portant un nom prédéfini.

;****************************************************************************
; MCU DIRECTIVES   (définit l'état de certains bits de configuration qui seront chargés lorsque le PIC débutera l'exécution)
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
ZONE1_UDATA	udata 0x60 	; La directive "udata" (unsigned data) permet de définir l'adresse du début d'une zone-mémoire
				; de la mémoire-donnée (ici 0x60).
				; Les directives "res" qui suivront, définiront des espaces-mémoire à partir de cette adresse.
				; La zone doit porter un nom unique (ici "ZONE1_UDATA") car on peut en définir plusieurs.
				
Count	 	res 1 		; La directive "res" réserve un seul octet qui pourra être référencé à l'aide du mot "Count".
				; L'octet sera localisé à l'adresse 0x60 (dans la banque 0).

Output		res 1
Delay_pointer	res 1
		
ZONE2_UDATA	udata 0x70

GREEN_DELAY	res 1
YELLOW_DELAY	res 1	
RED_DELAY	res 1				

;************************************************************
; reset vector
 
Zone1	code 00000h		; La directive "code" définit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionnées à la suite.
				; Elles formeront une zone dont le nom sera "Zone1".
				; Ici, l'instruction "goto" sera donc stockée à l'adresse 00000h dans la mémoire-programme. 
				
	goto Start		; Le micro-contrôleur saute à l'adresse-programme définie par l'étiquette "Start".

;************************************************************
; interrupt vector
 
Zone2	code	00008h		; La directive "code" définit l'adresse de la prochaine instruction qui suit cette directive.
				; Toutes les autres instructions seront positionnées à la suite.
				; Elles formeront une zone dont le nom sera "Zone2".
				; Ici, l'instruction "btfss" sera donc stockée à l'adresse 00008h dans la mémoire-programme.
				;
				; NOTE IMPORTANTE: Lorsque le micro-contrôleur subit une interruption, il interrompt le programme
				;                  en cours et saute à l'adresse 00008h pour exécuter l'instruction qui s'y trouve.
				;                  
	
	btfsc INTCON,TMR0IF	; Teste la valeur du bit nommé "TMR0IF" de l'espace-mémoire associée à INTCOM. Ce bit est en fait 
				; le bit numéro 2 selon la description détaillée du micro-contrôleur PIC. 
				; Ainsi, si ce bit est à 1, le temporisateur 0 est bien la source de l'interruption.
				; Si ce bit est à 0 (clear), on sautera l'instruction suivante (call TO_ISR). 
	
	call TO_ISR		; Exécute la sous-routine débutant à l'adresse "TO_ISR"
	retfie			; Cette instruction force le retour à l'instruction qui a été interrompue lors de l'interruption.


;************************************************************
;program code starts here

Zone3	code 00020h		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 020h
				; Cette nouvelle zone de code est nommée "Zone3".

Start				; Cette étiquette précède l'instruction "bcf". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
	
	clrf TRISC
	clrf TRISD		; définit tous les bits du port D en sorties
	setf TRISB		; définit tous les bits du port B en entrées 
	
	movlw d'10'
	movwf GREEN_DELAY
	
	movlw d'3'
	movwf YELLOW_DELAY
	
	movlw d'15'
	movwf RED_DELAY
	
	movlw 0x71
	movwf Delay_pointer

	movlw 0x01
	movwf PORTC
	
	movlw 0x02
	movwf Output

	movff	GREEN_DELAY, Count
	
	movlw 0x07		; Charge la valeur 0x07 dans le registre WREG
	movwf T0CON		; Copie le contenu du registre WREG dans l'espace-mémoire associé à T0CON
				; Ces 8 bits (00000111) configure le micro-contrôleur de telle
				; sorte que le temporisateur 0 soit actif, qu'il opère avec 16 bits,
				; qu'il utilise un facteur d'échelle ainsi que l'horloge interne
				; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf

	movlw 0xf1		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movlw 0xfF		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0L
				; (le temporisateur opérant sur 16 bits, la valeur de départ est dont 0xfff2)
				
	bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc réinitialisé à 0.
				
	bsf T0CON,TMR0ON	; Met à 1 le bit appelé TMR0ON (bit 7 de l'espace-mémoire associé à T0CON)
				; => voir la page 149 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le temporisateur 0 est donc démarré.
				
	bsf INTCON,TMR0IE	; Met à 1 le bit appelé TMR0IE (bit 5 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise le temporisateur à interrompre le micro-contrôleur lorsque le temporisateur viendra à échéance (00000000).
				
	bsf INTCON,GIE		; Met à 1 le bit appelé GIE (bit 7 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Cette action autorise toutes les sources possibles d'interruptions qui ont été validées.

loop
	btg PORTC,3		; Inverse ("toggle") la valeur courante du bit 2 stocké dans l'espace-mémoire associé au port C
	movff PORTB,PORTD	; Copie le contenu du port B dans le port D
	bra loop		; Saute à l'adresse "loop" (soit l'adresse de l'instruction "btg")

Zone4	code 0x100		; Ici, la nouvelle directive "code" définit une nouvelle adresse (dans la mémoire-programme) pour 
				; la prochaine instruction. Cette dernière sera ainsi localisée à l'adresse 0x100
				; Cette nouvelle zone de code est nommée "Zone4".

TO_ISR				; Cette étiquette précède l'instruction "movlw". Elle sert d'adresse destination à l'instruction "goto" apparaissant plus haut.
				; Les instructions qui suivent forment la sous-routine de gestion des interruptions.
				
				; Tout d'abord, on commence par réinitialiser la valeur initiale du temporisateur
	movlw 0xf1		; Charge la valeur 0xff dans le registre WREG
	movwf TMR0H		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0H
	movlw 0xff		; Charge la valeur 0xf2 dans le registre WREG
	movwf TMR0L		; Copie le contenu du registre WREG dans l'espace-mémoire associé à TMR0L
				; (le temporisateur opérant sur 16 bits, la valeur de départ est dont 0xfff2)
	
	bcf INTCON,TMR0IF	; Met à zéro le bit appelé TMR0IF (bit 2 de l'espace-mémoire associé à INTCON)
				; => voir la page 105 de la documentation sur le micro-contrôleur http://ww1.microchip.com/downloads/en/DeviceDoc/39625c.pdf
				; Le drapeau ("flag") est donc réinitialisé à 0.

	decf Count		; décrémente le contenu de l'espace-mémoire associé à "Count"
	bnz saut		; saute à l'adresse associée à "saut" si le bit Z du registre de statut est à 0
				; Il y a donc un branchement si la valeur "Count" n'est pas nulle ("non zero").
	
	
	movff Output, PORTC

	movff	Delay_pointer, 	FSR0L
	movff	INDF0, Count
	incf Delay_pointer
	
	movlw b'100'
	bcf STATUS,C
	cpfslt Output
	call ResetCycle
	
	rlcf Output

saut
	return			; Provoque le retour à l'instruction suivant l'appel de la sous-routine 
				; qui a débuté à l'adresse "TO_ISR"

ResetCycle
	
	clrf Output
	bsf STATUS,C
	
	movlw	0x70
	movwf	Delay_pointer
	
	return
	END



	


	
