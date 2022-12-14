;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Luis Pablo Carranza
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: Proyecto de laboratorio 1
; Hardware PIC16F887
; Creado: 23/08/22
; Última Modificación: 04/09/22
; ******************************************************************************

PROCESSOR 16F887
#include <xc.inc> 
; ******************************************************************************
; Palabra de configuración
; ******************************************************************************
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSC oscillator 
				; without clock out)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and 
				; can be enabled by SWDTEN bit of the WDTCON 
				; register)
  CONFIG  PWRTE = OFF           ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR 
				; pin function is digital input, MCLR internally 
				; tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code 
				; protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code 
				; protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/
				; External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit 
				; (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF             ; Low Voltage Programming Enable bit (RB3 pin 
				; has digital I/O, HV on MCLR must be used for 
				; programming)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset 
				; set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits 
				; (Write protection off)

; ******************************************************************************
; Variables
; ******************************************************************************
PSECT udata_bank0
 VDISP1:
    DS 1
 VDISP2:
    DS 1
 VDISP3:
    DS 1
 VDISP4:
    DS 1
 VDISP5:
    DS 1
 VDISP6:	; Variables para controlar el número que muestra el display
    DS 1
 VRELOJ:	; Variable para indicar que debe serguir contando para el reloj
    DS 1
 DETMES:	; Variable auxiliar para saber si el mes tiene 31, 28 o 30 días
    DS 1
 CONT5MSLED:	; Variable para saber cuándo llega a 500 ms para encender led
    DS 1
 VALARMA_H1:	; Variables para saber cuándo debe sonar la alarma
    DS 1
 VALARMA_H2:
    DS 1
 VALARMA_M1:
    DS 1
 VALARMA_M2:
    DS 1
 HORA1_TEMP:	; Variables que almacenan temporalmente los valores de hora
    DS 1	; y minutos mientras se configura la alarma
 HORA2_TEMP:
    DS 1
 MIN1_TEMP:
    DS 1
 MIN2_TEMP:
    DS 1
    
PSECT udata_shr
 W_TEMP:	; Variable para almacenar W durante interrupciones
    DS 1
 STATUS_TEMP:	; Variable para almacenar STATUS durante interrupciones
    DS 1
 CONT4MS:	; Contador de 4 ms
    DS 1
 CONTMUX:	; Contador para la multiplexación cada 50 ms
    DS 1
 CONTSEG:	; Contador para el display de segundos
    DS 1
 CONTSEG2:	; Contador para el segundo display de segundos
    DS 1
 CONTMIN:	; Contador para el display de minutos
    DS 1
 CONTMIN2:	; Contador para el segundo display de minutos
    DS 1
 CONTHOR:	; Contador para el display de horas
    DS 1
 CONTHOR2:	; Contador para el segundo display de horas
    DS 1
 CONTDIA:	; Contador para el display de días
    DS 1
 CONTDIA2:	; Contador para el segundo display de días
    DS 1
 CONTMES:	; Contador para el display de mes
    DS 1
 CONTMES2:	; Contador para el segundo display de mes
    DS 1
 ESTADO:	; Controlar el estado actual
    DS 1
 CAMBIO:	; Variable para antirrebotes de botones
    DS 1
    
; ******************************************************************************
; Vector Reset
; ******************************************************************************
    
PSECT CODE, delta=2, abs
 ORG 0x0000
    GOTO MAIN
    
; ******************************************************************************
; Vector Interrupciones
; ******************************************************************************
   
PSECT CODE, delta=2, abs
 ORG 0x0004
 
PUSH:			; Almacenar temporalmente W y STATUS
    MOVWF W_TEMP	
    SWAPF STATUS, W
    MOVWF STATUS_TEMP
    
ISR:			; Vector principal de interrupciones
    BTFSC INTCON, 2
    GOTO RTMR0
    BTFSC INTCON, 0
    GOTO RRBIF
    GOTO POP
    
RTMR0:
    BCF INTCON, 2	; Limpia la bandera de interrupción
    BANKSEL TMR0	
    INCF CONT4MS	; Incrementa la variable de 10 ms
    MOVLW 7		; Carga el valor de n al TMR0
    MOVWF TMR0	
    INCF CONTMUX, F	; Incrementa variable para el multiplexor
    INCF CONT5MSLED, F	; Incrementa variable para los led de 500ms
    GOTO POP
    
RRBIF:		
    MOVF ESTADO, W	; Revisa el valor de Estado
    SUBLW 0
    BTFSC STATUS, 2	; Si resta es cero llama al modo 0 si no revisa de nuevo
    GOTO ESTADO0_ISR	; Estado de reloj
    
    MOVF ESTADO, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO ESTADO1_ISR	; Estado de fecha
    
    MOVF ESTADO, W
    SUBLW 2
    BTFSC STATUS, 2
    GOTO ESTADO2_ISR	; Estado de cambio de hora/minutos
    
    MOVF ESTADO, W
    SUBLW 3
    BTFSC STATUS, 2
    GOTO ESTADO2_ISR	; Estado de cambio de fecha
    
    MOVF ESTADO, W
    SUBLW 4
    BTFSC STATUS, 2
    GOTO ESTADO2_ISR	; Estado de set de alarma
    
    MOVF ESTADO, W
    SUBLW 5
    BTFSC STATUS, 2
    GOTO ESTADO2_ISR	; Estado de set de alarma
    
    GOTO POP
   
ESTADO0_ISR:		; Reloj normal
    BANKSEL PORTB
    BTFSS PORTB, 0	; Revisa si se presiona el cambio de modo
    CALL PUSH0_PRESSED	; 
    BCF INTCON, 0	; Apaga bandera de interrupción de puerto b
    GOTO POP
    
ESTADO1_ISR:		; Reloj normal
    BANKSEL PORTB
    BTFSS PORTB, 0	; Revisa si se presiona el cambio de modo
    CALL PUSH0_PRESSED	;
    BCF INTCON, 0	; Apaga bandera de interrupción de puerto b
    GOTO POP

ESTADO2_ISR:		; Cambio de minutos (también funciona para el cambio de
			; fecha y el set de la alarma)
    BANKSEL PORTB
    BTFSS PORTB, 0	; Revisa si se presiona el cambio de modo
    CALL PUSH0_PRESSED	;
    
    BTFSS PORTB, 1	; Revisa si se presiona el botón de incremento min
    CALL PUSH1_PRESSED	; Si si llama función para antirrebotes
    BTFSS PORTB, 2	; Revisa si se presionó el botón de decremento min
    CALL PUSH2_PRESSED	
    BTFSS PORTB, 3	; Revisa si se presionó el botón de incremento hor
    CALL PUSH3_PRESSED
    BTFSS PORTB, 4	; Revisa si se presionó el botón de decremento hor
    CALL PUSH4_PRESSED
    
    BCF INTCON, 0	; Apaga bandera de interrupción del puerto
    GOTO POP

PUSH0_PRESSED:		; Subrutina de antirrebotes
    BTFSS PORTB, 0	; Revisa si sigue presionado el botón
    GOTO $-1		; Si sigue presionado revisa de nuevo
    INCF ESTADO, F
    MOVF ESTADO, W
    
    RETURN		; Regresa de la subrutina
    
PUSH1_PRESSED:		; Subrutina de antirrebotes
    BTFSS PORTB, 1	; Revisa si sigue presionado el botón
    GOTO $-1		; Si sigue presionado revisa de nuevo
    BSF CAMBIO, 0	; Si ya se soltó enciende bandera de cambio
    RETURN		; Regresa de la subrutina
 
PUSH2_PRESSED:		; Subrutina de antirrebotes del botón 2
    BTFSS PORTB, 2
    GOTO $-1
    BSF CAMBIO, 1
    RETURN

PUSH3_PRESSED:		; Subrutina de antirrebotes del botón 3
    BTFSS PORTB, 3
    GOTO $-1
    BSF CAMBIO, 2
    RETURN
 
PUSH4_PRESSED:		; Subrutina de antirrebotes del botón 4
    BTFSS PORTB, 4
    GOTO $-1
    BSF CAMBIO, 3
    RETURN
    
POP:			    ; Regresar valores de W y de STATUS
    SWAPF STATUS_TEMP, W
    MOVWF STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE		    ; Regresa de la interrupción

; ******************************************************************************
; Código Principal
; ******************************************************************************

PSECT CODE, delta=2, abs
 ORG 0x0100
    
MAIN:	
    BANKSEL OSCCON  ; Configuración del oscilador 4MHz
    BSF OSCCON, 6   ; IRCF2
    BSF OSCCON, 5   ; IRCF1
    BCF OSCCON, 4   ; IRCF0
    
    BSF OSCCON, 0   ; SCS Reloj Interno
    
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH	    ; Todas las I/O son digitales
    
    BANKSEL TRISB
    MOVLW 00011111B ; Bits del 0 al 4 son entradas, el resto salidas
    MOVWF TRISB		
    CLRF TRISA
    CLRF TRISC
    CLRF TRISD	    
    CLRF TRISE	    ; El resto de puertos configurados como salidas
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 5	; T0CS FOSC/4 modo temporizador
    BCF OPTION_REG, 3	; PSA asignar presscaler para TMR0
    
    BCF OPTION_REG, 2	
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	; Prescaler 1:16
    
    BCF OPTION_REG, 7	; NO RBPU
    
    BANKSEL PORTB
    CLRF PORTA
    CLRF PORTB
    CLRF PORTD
    CLRF PORTC
    CLRF PORTE	    ; Iniciar todos los puertos en 0

    BANKSEL INTCON
    BSF INTCON, 7   ; GIE Habilitar interrupciones globales
    BSF INTCON, 5   ; Habilitar interrupción de TMR0
    BSF INTCON, 3   ; RBIE Habilitar interrupciones de PORTB
    BCF INTCON, 2   ; Bandera T0IF apagada
    BCF INTCON, 0   ; Bandera de interrupción de puerto B apagada
    
    BANKSEL WPUB
    MOVLW 00011111B ; Bits del 0 al 4 son entradas con pull-up e ITO
    MOVWF IOCB	    ; Interrupt on change
    MOVWF WPUB	    ; Pull ups del puerto B
    
    BANKSEL TMR0
    MOVLW 7	    ; Valor calculado para 4 ms
    MOVWF TMR0	    ; Se carga el valor de TMR0
	
    
    CLRF ESTADO	    ; Inicia en el estado 0
    
    CLRF VDISP1	    ; Limpia los valores iniciales del display
    CLRF VDISP2
    CLRF VDISP3
    CLRF VDISP4
    CLRF VDISP5
    CLRF VDISP6
    
    CLRF VRELOJ	    ; Inicia en modo reloj
    
    MOVLW 1
    MOVWF CONTDIA   ; El día mes es 1	
    MOVWF CONTMES   ; El primer ems es 1
    MOVWF DETMES    ; El primer mes es del tipo 1 (31 días)
    
    CLRF CONTDIA2   ; Limpia variables que inician en 0
    CLRF CONTMES2
    
    CLRF CONT4MS   
    CLRF CONTMUX
    CLRF CONT5MSLED
    CLRF CONTSEG
    CLRF CONTSEG2
    CLRF CONTMIN
    CLRF CONTMIN2   
    CLRF CONTHOR
    CLRF CONTHOR2
    
    CLRF VALARMA_H1
    CLRF VALARMA_H2
    CLRF VALARMA_M1
    CLRF VALARMA_M2
    CLRF HORA1_TEMP
    CLRF HORA2_TEMP
    CLRF MIN1_TEMP
    CLRF MIN2_TEMP
    
; ******************************************************************************
; LOOP PRINCIPAL
; ******************************************************************************   
    
LOOP:    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 0		; Lo resta a 0
    BTFSC STATUS, 2	; Si es 0 está en modo reloj
    CALL MRELOJ		; Estado de cambio de minutos
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 1		; Lo resta a 1
    BTFSC STATUS, 2	; Si es 0 está en modo mostrar fecha
    CALL MFECHA		; Estado de cambio de minutos
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 2		; Lo resta a 2
    BTFSC STATUS, 2	; Si es 0 está en modo cambio de hora/min
    GOTO CAMBIOMIN	; Estado de cambio de minutos
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 3		; Lo resta a 3
    BTFSC STATUS, 2	; Si es 0 está en modo cambio de fecha
    GOTO CAMBIODIA	; Estado de cambio de minutos
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 4		; Lo resta a 4
    BTFSC STATUS, 2	; Si es 0 está en modo cambio de set alarma
    GOTO SET_ALARMA	; Estado de cambio de minutos
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 5		; Lo resta a 4
    BTFSC STATUS, 2	; Si es 0 está en modo cambio de set alarma
    GOTO CAMBIOMIN	; Estado de cambio de minutos
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 6		; Lo resta a 6
    BTFSC STATUS, 2	; Si es 0 está en modo alarma seted
    GOTO ALARMASETED	; Estado de cambio de minutos

; ******************************************************************************
; MODO RELOJ
; ******************************************************************************      
VERIRELOJ:
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 0		; Revisa si está en modo reloj-fecha
    BTFSC STATUS, 2
    BCF VRELOJ, 0	; Enciende bit que indica que está en modo reloj-fecha
    
    MOVF ESTADO, W	; Revisa de nuevo el valor de ESTADO
    SUBLW 2		; Si está en el modo cambio minutos
    BTFSC STATUS, 2
    CALL MRELOJ		; Carga las variables de seg, min y hor al display
    
    MOVF ESTADO, W	; Revisa de nuevo el valor de ESTADO
    SUBLW 3		; Si está en el modo cambio minutos
    BTFSC STATUS, 2
    CALL MFECHA		; Carga las variables de día y mes a los displays
    
    MOVF ESTADO, W	; Revisa de nuevo el valor de ESTADO
    SUBLW 5		; Si está en el modo de set alarma
    BTFSC STATUS, 2
    CALL MRELOJ		; Carga las variables de min y hor al display
    
    MOVF CONTMUX, W	; Carga el valor de la variable a W
    SUBLW 1		; Resta el valor a 1
    BTFSC STATUS, 2	; Revisa si el resultado es 0
    CALL MULTIPLEX	; Llama para la multiplexación cada 5ms
    
    PAGESEL REVISIONALARMA  ; Revisa continuamente si la alarma está activada 
    CALL REVISIONALARMA	    ; y si ya es hora de que suena
    CALL PULSOSALARMA	    ; Envía pulsos al buzzer cada vez que se repite la 
    PAGESEL VERIRELOJ	    ; instrucción
    PAGESEL APAGARALARMA    ; Si la alarma está encendida la debe apagar
    CALL APAGARALARMA
    PAGESEL VERIRELOJ
    
    BTFSS VRELOJ, 0
    CALL ENCENDERLEDS	; Revisa si está en modo reloj para encender leds
    
    BTFSS VRELOJ, 0
    CALL APAGARLEDSMODO	; Revisa si está en modo reloj para encender leds
    
    BTFSS VRELOJ, 0	; Revisa si está en el modo reloj
    GOTO RELOJ		; Si sí, continua con el contador de s, min, h, d, m
    
    GOTO LOOP		; Si no está en ese modo solo realiza la multiplexación
			; y regresa al LOOP
			
; ******************************************************************************
; CONTADOR DE RELOJ
; ******************************************************************************     
RELOJ:    
    MOVF CONT4MS, W	; Carga el valor de la variable a W
    SUBLW 250		; Resta el valor a 250
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    GOTO VERIRELOJ	; Si no es 0 regresa a verificación del reloj
    CLRF CONT4MS	; Si es 0 limpia la variable (Ya pasó 1 segundo)
     
    INCF CONTSEG, F	; Incrementa la variable de segundos
    MOVF CONTSEG, W
    SUBLW 10		; Resta a 10 para verificar si debe incrementar el cseg2
    BTFSS STATUS, 2	
    GOTO LOOP		; Si no es 0 regresa al loop
    INCF CONTSEG2	; Si es 0 incrementa CONTSEG2
    CLRF CONTSEG	; Reinicia la primera variable
    
    MOVF CONTSEG2, W	; Mueve el valor de CONTSEG2 a W
    SUBLW 6		; Lo resta a 6
    BTFSS STATUS, 2	; Si el resultado es 0 salta la instrucción 
    GOTO LOOP		; Si no es 0 regresa al loop
    INCF CONTMIN, F	; Incrementa el contador de minutos
    CLRF CONTSEG	; Limpia ambos contadores de segundos
    CLRF CONTSEG2
    
INCREMENTOMIN:    
    MOVF CONTMIN, W	; Mueve el valor CONTMIN a W
    SUBLW 10		; Lo resta a 10
    BTFSS STATUS, 2
    GOTO LOOP		; Si el resultado no es 0 regresa al loop
    INCF CONTMIN2, F	; Si es 0 incrementa CONTMIN2
    CLRF CONTMIN	; Limpia la primera variable
    
    MOVF CONTMIN2, W	; Mueve el valor del segundo display de minutos a W
    SUBLW 6		; Resta el valor a 6
    BTFSS STATUS, 2	
    GOTO LOOP		; Si el resultado es 0 regresa al loop
    CLRF CONTMIN	; Limpia el resto de variables del reloj
    CLRF CONTMIN2
    
    BTFSS VRELOJ, 0	; Revisa si está en modo reloj o fecha
    GOTO INCREMENTOHOR	; Si lo está debe incrementar la hora
    
    GOTO LOOP		; Si no, está en cambio de hora/min, entonces regresa
			; al LOOP
    
INCREMENTOHOR:  
    INCF CONTHOR, F	; Incrementa contador de hora
    MOVF CONTHOR, W	; Mueve el valor CONTHOR a W   
    SUBLW 10		; Resta el valor a 10
    BTFSS STATUS, 2	
    GOTO REVCAMBIOHOR	; Si el resultado no es 0 regresa al loop
    INCF CONTHOR2, F	; Incrementa la segunda variable de horas
    CLRF CONTHOR	; Limpia la primera variable de horas
  
    GOTO LOOP
    
REVCAMBIOHOR:
    MOVF CONTHOR2, W	; Revisa si decenas de minutos es 2
    SUBLW 2
    BTFSS STATUS, 2
    GOTO LOOP		; si no lo es regresa al loop solo incrementado CONTHOR
    
    MOVF CONTHOR, W	; Si es 2 revisa si unidades de minutos es 4
    SUBLW 4
    BTFSS STATUS, 2	; Si no es 4 regresa al loop
    GOTO LOOP
    
    CLRF CONTHOR	; Si es 4 regresa a la hora 00:00
    CLRF CONTHOR2
    
    BTFSS VRELOJ, 0	; Revisa si está en modo reloj-fecha
    GOTO INCREMENTODIA	; Si lo está entonces debe incrementar el día
    
    GOTO LOOP		; Si no lo está solo regresa al loop
    
; ******************************************************************************
; Tabla para multiplexor
; ******************************************************************************   
Table:
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F	    ; Se asegura que hay 8 bits
    ADDWF PCL
    RETLW 00111111B ; Regresa 0
    RETLW 00000110B ; Regresa 1
    RETLW 01011011B ; Regresa 2
    RETLW 01001111B ; Regresa 3
    RETLW 01100110B ; Regresa 4
    RETLW 01101101B ; Regresa 5
    RETLW 01111101B ; Regresa 6
    RETLW 00000111B ; Regresa 7
    RETLW 01111111B ; Regresa 8
    RETLW 01101111B ; Regresa 9    
    
; ******************************************************************************
; MULTIPLEXADO
; ******************************************************************************  
MULTIPLEX:		; Subrutina para el multiplexado
    MOVF PORTD, W	; Revisa el valor actual del puerto D
    SUBLW 0		; Si está en 0 carga el valor del display 1 al puerto A
    BTFSC STATUS, 2
    GOTO DISP1
    
    MOVF PORTD, W
    SUBLW 1		; Revisa cuál display está encendido
    BTFSC STATUS, 2	; Si está en 1 carga el valor del display 2 al puerto A
    GOTO DISP2
    
    MOVF PORTD, W
    SUBLW 2		; Revisa cuál display está encendido
    BTFSC STATUS, 2	; Si está en 2 carga el valor del display 3 al puerto A
    GOTO DISP3

    MOVF PORTD, W
    SUBLW 4		; Revisa cuál display está encendido
    BTFSC STATUS, 2	; Si está en 4 carga el valor del display 4 al puerto A
    GOTO DISP4
    
    MOVF PORTD, W
    SUBLW 8		; Revisa cuál display está encendido
    BTFSC STATUS, 2	; Si está en 8 carga el valor del display 5 al puerto A
    GOTO DISP5
    
    MOVF PORTD, W
    SUBLW 16		; Revisa cuál display está encendido
    BTFSC STATUS, 2
    GOTO DISP6		; Si está en 16 carga el valor del display 6 al puerto A
	
    MOVF PORTD, W
    SUBLW 32		; Revisa cuál display está encendido
    BTFSC STATUS, 2
    CLRF PORTD		; Si está en 32 regresa al display 1
    RETURN
    
DISP1:
    BSF PORTD, 0	; Enciende display 1
    MOVF VDISP1, W	; Mueve la variable de display 1 a W
    CALL Table		; Llama a la tabla
    MOVWF PORTA		; Carga el valor de la tabla al puerto A
    CLRF CONTMUX	; Limpia la variable de multiplexor
    RETURN		; Regresa a la etiqueta del reloj
    
DISP2:	    
    INCF PORTD, F	; Enciende display 2
    MOVF VDISP2, W	; Mueve la variable de display 2 a W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP3:
    MOVLW 4		; Enciende display 3
    MOVWF PORTD		
    MOVF VDISP3, W	; Mueve la variable de display 3 a W
    CALL Table
    MOVWF PORTA		; Carga el valor de la tabla al puerto A
    CLRF CONTMUX
    RETURN
    
DISP4:
    MOVLW 8		; Enciende display 4
    MOVWF PORTD
    MOVF VDISP4, W	; Mueve la variable de display 4 a W
    CALL Table
    MOVWF PORTA		; Carga el valor de la tabla al puerto A
    CLRF CONTMUX
    RETURN
    
DISP5:
    MOVLW 16		; Enciende display 5
    MOVWF PORTD
    MOVF VDISP5, W	; Mueve la variable de display 5 a W
    CALL Table
    MOVWF PORTA		; Carga el valor de la tabla al puerto A
    CLRF CONTMUX
    RETURN

DISP6:
    MOVLW 32		; Enciende display 6
    MOVWF PORTD
    MOVF VDISP6, W	; Mueve la variable de display 6 a W
    CALL Table
    MOVWF PORTA		; Carga el valor de la tabla al puerto A
    CLRF CONTMUX
    RETURN

; ******************************************************************************
; SUBRUTINA PARA ENCENDER LEDS
; ****************************************************************************** 
ENCENDERLEDS:
    MOVF CONT5MSLED, W	; Carga el valor de la variable a W
    SUBLW 100		; Resta el valor a 100
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    RETURN	    	; Si no es 0 regresa de la subrutina
    
    CLRF CONT5MSLED
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 1		; Lo resta a 1
    BTFSC STATUS, 2	; Si es 0 está en modo mostrar fecha
    GOTO LED_ON		; Estado de cambio de minutos
    
    BTFSS PORTE, 2	; Revisa el estado del bit 2 del puerto E
    GOTO LED_ON
    BCF PORTE, 2	; si no está en 1 lo enciende
    RETURN		; Regresa de la subrutina
    
LED_ON:
    BSF PORTE, 2	; Si está en 1 limpia el puerto
    RETURN 
    
; ******************************************************************************
; SUBRUTINA PARA APAGAR LEDS DE MODO
; ******************************************************************************     
APAGARLEDSMODO:
    BCF PORTC, 7
    BCF PORTC, 6
    BCF PORTC, 5
    RETURN
    
; ******************************************************************************
; MODO CAMBIO RELOJ
; ****************************************************************************** 
MRELOJ:		    
    MOVF CONTSEG, W	; Carga el contador de segundos a display 1
    MOVWF VDISP1
    
    MOVF CONTSEG2, W	; Carga el contador de decenas de segundos a display 2  
    MOVWF VDISP2
    
    MOVF CONTMIN, W	; Carga el contador de minutos a display 3
    MOVWF VDISP3    
    
    MOVF CONTMIN2, W	; Carga el contador de decenas de minutos a display 4
    MOVWF VDISP4
    
    MOVF CONTHOR, W	; Carga el contador de horas a display 5
    MOVWF VDISP5
    
    MOVF CONTHOR2, W	; Carga el contador decenas de horas a display 6
    MOVWF VDISP6
    
    RETURN
    
; ******************************************************************************
; MODO FECHA
; ****************************************************************************** 
MFECHA:
    MOVF CONTDIA, W	; Carga el contador de días a display 3
    MOVWF VDISP5 
    
    MOVF CONTDIA2, W	; Carga el contador de decenas de días a display 4
    MOVWF VDISP6
    
    MOVF CONTMES, W	; Carga el contador de meses a display 5
    MOVWF VDISP3
    
    MOVF CONTMES2, W	; Carga el contador de decenas de meses a display 6
    MOVWF VDISP4
    
    MOVLW 2		; Configurado para mostrar el año 22 (temporal)
    MOVWF VDISP1
    MOVWF VDISP2
    
    RETURN

; ******************************************************************************
; CONTADOR DE FECHA
; ******************************************************************************     
INCREMENTODIA:
    INCF CONTDIA, F	; Pasaron 24 horas entonces incrementa el día
    MOVF CONTDIA, W
    SUBLW 10		; Revisa si debe incrementar las decenas
    BTFSS STATUS, 2 
    GOTO REVCAMBIODIA	; Si no revisa qué día del mes está
    
    INCF CONTDIA2	; Si sí incrementa decenas de días
    CLRF CONTDIA	; Limpia variable de unidades de días
    GOTO LOOP		; Regresa al loop
    
REVCAMBIODIA:
    CALL DETERMINARMES	; Determina en qué tipo de mes está
    
    MOVF DETMES, W	; Si DETMES es 1 entonces tiene 31 días
    SUBLW 1
    BTFSC STATUS, 2
    GOTO CAMBIOMES31	; Revisa si está en 31 
    
    MOVF DETMES, W	; Si DETMES es 2 entonces tiene 28 días
    SUBLW 2
    BTFSC STATUS, 2 
    GOTO CAMBIOMES28	; Revisa si está en 28
    
    MOVF DETMES, W	; Si DETMES es 3 entonces tiene 30 días
    SUBLW 3
    BTFSC STATUS, 2
    GOTO CAMBIOMES30	; Revisa si está en 30
 
CAMBIOMES31:
    MOVF CONTDIA2, W	; Revisa si decenas de días está en 3
    SUBLW 3
    BTFSS STATUS, 2
    GOTO LOOP		; Si no, regresa al loop
    
    MOVF CONTDIA, W	; Si si revisa si unidades de días es 2
    SUBLW 2
    BTFSS STATUS, 2
    GOTO LOOP		; Si no es 2 regresa al loop
    
    MOVLW 1		; Si es 2 debe reiniciar el conteo de días
    MOVWF CONTDIA	; El primer día es 1
    CLRF CONTDIA2	; La variable de decenas debe regresar a 0
    
    BTFSS VRELOJ, 0	; Revisa si está en modo reloj-fecha
    GOTO INCREMENTOMES	; Si si debe incrementar el mes
    
    GOTO LOOP		; Si no regresa al loop
   
CAMBIOMES28:
    MOVF CONTDIA2, W	; Revisa si decenas de días está en 2
    SUBLW 2
    BTFSS STATUS, 2
    GOTO LOOP		; Si no, regresa al loop
    
    MOVF CONTDIA, W
    SUBLW 9		; Si si revisa si unidades de días es 9
    BTFSS STATUS, 2
    GOTO LOOP		; Si no es 9 regresa al loop
    
    MOVLW 1		; Si es 9 debe reiniciar el conteo de días
    MOVWF CONTDIA
    CLRF CONTDIA2
    
    BTFSS VRELOJ, 0	; Revisa si está en modo reloj-fecha
    GOTO INCREMENTOMES	; Si si debe incrementar el mes
    
    GOTO LOOP		; Si no regresa al loop

CAMBIOMES30:
    MOVF CONTDIA2, W	; Revisa si decenas de días está en 3
    SUBLW 3
    BTFSS STATUS, 2
    GOTO LOOP		; Si no, regresa al loop
    
    MOVF CONTDIA, W
    SUBLW 1		; Si si revisa si unidades de días es 1
    BTFSS STATUS, 2
    GOTO LOOP		; Si no, regresa al loop
    
    MOVLW 1		; Si es 1 debe reiniciar el conteo de días
    MOVWF CONTDIA
    CLRF CONTDIA2
    
    BTFSS VRELOJ, 0	; Revisa si está en modo reloj-fecha
    GOTO INCREMENTOMES	; Si si debe incrementar el mes
    
    GOTO LOOP		; Si no, regresa al loop

DETERMINARMES:		; Proceso para determinar mes
    MOVF CONTMES, W	; Mueve unidades de mes a W
    SUBLW 1		; Resta el valor a 1
    BTFSC STATUS, 2
    GOTO TMES1		; Si resta es 0 es ENERO o NOVIEMBRE, entonces revisa
    
    MOVF CONTMES, W
    SUBLW 2		; Revisa si CONTMES es 2
    BTFSC STATUS, 2
    GOTO TMES2		; Si resta es 0 es FEBRERO o DICIEMBRE, entonces revisa
    
    MOVF CONTMES, W	
    SUBLW 3		; Si CONTMES es 3
    BTFSC STATUS, 2	
    GOTO TMES11		; Es MARZO entonces es TMES11 y tiene 31 días
    
    MOVF CONTMES, W
    SUBLW 4		; Si CONTMES es 4
    BTFSC STATUS, 2
    GOTO TMES3		; Es ABRIL entonces es TMES3 y tiene 30 días
    
    MOVF CONTMES, W
    SUBLW 5		; Si CONTMES es 5
    BTFSC STATUS, 2
    GOTO TMES11		; Es MAYO entonces es TMES11 y tiene 31 días
    
    MOVF CONTMES, W
    SUBLW 6		; Si CONTMES es 6
    BTFSC STATUS, 2
    GOTO TMES3		; Es JUNIO entonces es TMES3 y tiene 30 días
    
    MOVF CONTMES, W
    SUBLW 7		; Si CONTMES es 7
    BTFSC STATUS, 2
    GOTO TMES11		; Es JULIO entonces es TMES11 y tiene 31 días
    
    MOVF CONTMES, W
    SUBLW 8		; Si CONTMES es 8
    BTFSC STATUS, 2
    GOTO TMES11		; Es AGOSTO entonces es TMES11 y tiene 31 días
    
    MOVF CONTMES, W
    SUBLW 9		; Si CONTMES es 9
    BTFSC STATUS, 2
    GOTO TMES3		; Es SEPTIEMBRE entonces es TMES3 y tiene 30 días
    
    MOVF CONTMES, W
    SUBLW 0		; Si CONTMES es 0
    BTFSC STATUS, 2
    GOTO TMES11		; Solo puede ser OCTUBRE, es TMES11 y tiene 31 días
    
TMES1:			; Puede ser Enero o Noviembre, entonces revisa
    MOVF CONTMES2, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO TMES3		; Si decenas de unidades es 1 solo puede ser noviembre
			; Entonces llama al tipo de mes con 30 días
			; Si no es 1 procede a asumir que es Enero
TMES11:
    MOVLW 1		; Si es TMES11 entonces carga 1 a DETMES
    MOVWF DETMES	; Si DETMES es 1 es tipo de mes con 31 días
    RETURN
    
TMES2:			; Puede ser Febrero o Diciembre, entonces revisa
    MOVF CONTMES2, W
    SUBLW 1		; Si decenas de meses es 1 es diciembre
    BTFSC STATUS, 2
    GOTO TMES11		; Si es diciembre va al tipo de mes de 31 días
    
    MOVLW 2		; Si no es 1 entonces es febrero y DEMES es 2
    MOVWF DETMES	; Si DETMES es 2 entonces tiene 28 días
    RETURN
 
TMES3:
    MOVLW 3		; Si es TMES3 tiene 30 días
    MOVWF DETMES	; Detmes vale 3 para este tipo de meses
    RETURN
    
INCREMENTOMES:
    INCF CONTMES, F	; Terminó un mes, entonces incrementa el contador
    MOVF CONTMES, W
    SUBLW 10		; Revisa si el contador de unidades llega a 10
    BTFSS STATUS, 2	; Si no es cero revisa si debe reiniciar el año
    GOTO REVMES
    
    INCF CONTMES2, F	; Si es cero entonces incrementa decenas
    CLRF CONTMES	; Limpia la variable de mes
    GOTO LOOP		; Regresa al LOOP
    
REVMES:
    MOVF CONTMES2, W	; Revisa si decenas está en 1
    SUBLW 1
    BTFSS STATUS, 2	; Si no está en uno regresa al loop
    GOTO LOOP
    
    MOVF CONTMES, W	; Si está en 1 revisa si quiere incrementar a 13    
    SUBLW 3
    BTFSS STATUS, 2	; Si no ha llegado regresa al loop
    GOTO LOOP
    
    MOVLW 1		; Si llegó cambia el mes a Enero de nuevo
    MOVWF CONTMES
    CLRF CONTMES2	; En enero CONTMES2 vale 0
    
    GOTO LOOP		; Regresa al LOOP
    
; ******************************************************************************
; MODO CAMBIO DE MINUTOS/HORA
; ******************************************************************************      
CAMBIOMIN:
    BSF VRELOJ, 0	; Indica que ya no está en modo contador de reloj-fecha
    CLRF CONTSEG	; Limpia variable de segundos para ajustar la hora
    CLRF CONTSEG2
    BCF PORTE, 2	; Apaga leds titilantes
    
    MOVF ESTADO, W	; Revisa el valor de ESTADO
    SUBLW 2		; Lo resta a 2
    BTFSC STATUS, 2	; Si es 0 está en modo cambio de hora/min
    GOTO LEDINDICADOR	; por lo tanto debe encender el led del estado
    GOTO CAMBIOMIN1	; Si no, está en modo set alarma y no enciende ese led
    
LEDINDICADOR:
    MOVLW 10000000B	; Pone el bit 7 del puerto c en HIGH
    MOVWF PORTC
    
CAMBIOMIN1:
    BTFSS CAMBIO, 0	; Revisa si se presionó el cambio de unidades de min
    GOTO DECMIN		; Si no revisa si se presionó el de decenas de min
    BCF CAMBIO, 0	; Si si limpia la bandera del botón
    INCF CONTMIN, F	; Incrementa unidades de minutos
    GOTO INCREMENTOMIN	; Procede a revisar cómo debe hacer el incremento
			; Con ayuda de la subrutina del reloj
 
DECMIN:
    BTFSS CAMBIO, 1	; Revisa si se presionó el cambio de decenas de min
    GOTO CAMBIOHOR	; Si no se presionó revisa el cambio de horas
    BCF CAMBIO, 1	; Si se presionó limpia la bandera del botón
    DECF CONTMIN, F	; Decrementa el contador de minutos
    MOVF CONTMIN, W	
    SUBLW -1		; Revisa si el valor actual es 0 restándole -1
    BTFSS STATUS, 2	; Si la resta es cero es porque CONTMIN ya era -1
    GOTO VERIRELOJ	; Si no es cero regresa al loop del reloj para multiplex
    MOVLW 9		; Si es cero entonces reinicia a 9 unidades de minutos
    MOVWF CONTMIN
    
    DECF CONTMIN2, F	; Decrementa las decenas de minutos
    MOVF CONTMIN2, W
    SUBLW -1		; Revisa si decenas de minutos ya es -1
    BTFSS STATUS, 2
    GOTO VERIRELOJ	; Si no es -1 regresa al loop de reloj para multiplexar
    MOVLW 5		; Si ya es -1 entonces reinicia decenas de minutos a 5
    MOVWF CONTMIN2	
    GOTO VERIRELOJ	; Regresa al loop del reloj para multiplexar

CAMBIOHOR:
    BTFSS CAMBIO, 2	; Revisa si se presionó para incrementar la hora
    GOTO DECHOR		; Si no revisa si se presionó para decrementarla 
    BCF CAMBIO, 2	; Si si limpia la bandera del botón
    GOTO INCREMENTOHOR	; Llama a la subrutina del reloj que incrementa la hora
 
DECHOR:
    BTFSS CAMBIO, 3	; Revisa si se presionó el botón de decremento hora
    GOTO VERIRELOJ	; Si no regresa al loop de reloj para multiplexar
    BCF CAMBIO, 3	; Si si limpia la bandera del botón
    DECF CONTHOR, F	; Decrementa unidades de hora
    MOVF CONTHOR, W
    SUBLW -1		; Revisa si ya es -1
    BTFSS STATUS, 2 
    GOTO VERIRELOJ	; Si aún no lo es regresa al loop del reloj
    
    DECF CONTHOR2, F	; Si es -1 entonces decrementa las decenas de horas
    MOVF CONTHOR2, W
    SUBLW -1		; Revisa si decenas de horas es -1
    BTFSC STATUS, 2
    GOTO RESETHOR	; Si es -1 resetea la hora
    
    MOVLW 9		; Si no es -1 solo carga el valor de 9 a las unidades
    MOVWF CONTHOR
    GOTO VERIRELOJ	; Regresa al loop del reloj
    
RESETHOR:
    MOVLW 2		; Carga el valor de 2 a decenas
    MOVWF CONTHOR2  
    MOVLW 3		; Carga el valor de 3 a unidades
    MOVWF CONTHOR
    GOTO VERIRELOJ	; Regresa al loop del reloj
   
; ******************************************************************************
; MODO CAMBIO DE DIA/MES
; ******************************************************************************      
CAMBIODIA:
    BSF VRELOJ, 0	; Indica que ya no está en modo contador de reloj-fecha
    CALL REVISIONDIASMES
    BCF PORTE, 2	; Apaga leds titilantes
    MOVLW 01000000B
    MOVWF PORTC
    BTFSS CAMBIO, 2	; Revisa si se presionó el cambio de unidades de día
    GOTO DECDIA		; Si no revisa si se presionó el de decenas de día
    BCF CAMBIO, 2	; Si si limpia la bandera del botón
    GOTO INCREMENTODIA	; Procede a realizar el incremento
 
DECDIA:
    BTFSS CAMBIO, 3	; Revisa si se presionó el cambio de decenas de min
    GOTO CAMBIOMES	; Si no se presionó revisa el cambio de horas
    BCF CAMBIO, 3	; Si se presionó limpia la bandera del botón
    
    DECF CONTDIA, F	; Decrementa el contador de días
    MOVF CONTDIA, W	
    SUBLW 0		; Revisa si el valor luego del decremento es 0
    BTFSS STATUS, 2	;  
    GOTO DECDIA2	; Si no es cero regresa revisa si el valor luego del 
			; decremento es -1
    
    MOVF CONTDIA2, W	; Si es 0 revisa si las unidades del día es 0
    SUBLW 0
    BTFSC STATUS, 2
    GOTO REVDECMES	; Si es 0 revisa qué mes es para reiniciar a 31, 30 o 28
    
    CLRF CONTDIA	; Si no es 0 limpia el contador de unidades
    GOTO VERIRELOJ	; Regresa al loop del reloj
    
DECDIA2:
    MOVF CONTDIA, W	; Revisa si CONTDIA luego del decremento es -1
    SUBLW -1
    BTFSS STATUS, 2
    GOTO VERIRELOJ	; Si no lo es regresa al loop de reloj
    MOVLW 9		; Si es 0 entonces carga 9 a las unidades
    MOVWF CONTDIA
    DECF CONTDIA2, F	; Decrementa las decenas
    GOTO VERIRELOJ	; Regresa al loop de reloj
    
REVDECMES:
    CALL DETERMINARMES	; Revisa en qué tipo de mes se encuentra
    
    MOVF DETMES, W	; Si DETMES es 1 entonces tiene 31 días
    SUBLW 1
    BTFSC STATUS, 2
    GOTO DECDIA31	; Regresa a 31 
    
    MOVF DETMES, W	; Si DETMES es 2 entonces tiene 28 días
    SUBLW 2
    BTFSC STATUS, 2 
    GOTO DECDIA28	; Regresa a 28
    
    MOVF DETMES, W	; Si DETMES es 3 entonces tiene 30 días
    SUBLW 3
    BTFSC STATUS, 2
    GOTO DECDIA30	; Regresa a 30
        
DECDIA31:
    MOVLW 1		; Carga el 1 a las unidades
    MOVWF CONTDIA
    
    MOVLW 3		; Carga el 3 a las decenas
    MOVWF CONTDIA2
    
    GOTO VERIRELOJ
    
DECDIA28:
    MOVLW 8		; Carga el 8 a las unidades
    MOVWF CONTDIA
    
    MOVLW 2		; Carga el 2 a las decenas
    MOVWF CONTDIA2
    
    GOTO VERIRELOJ
    
DECDIA30:
    MOVLW 0		; Carga el 0 a las unidades
    MOVWF CONTDIA
    
    MOVLW 3		; Carga el 3 a las decenas
    MOVWF CONTDIA2
    
    GOTO VERIRELOJ	; Regresa al loop del reloj

CAMBIOMES:
    BTFSS CAMBIO, 0	; Revisa si se presionó para incrementar el mes
    GOTO DECMES		; Si no revisa si se presionó para decrementarlo
    BCF CAMBIO, 0	; Si si limpia la bandera del botón
    GOTO INCREMENTOMES	; Llama a la etiqueta que incrementa el mes
 
DECMES:
    BTFSS CAMBIO, 1	; Revisa si se presionó el botón de decremento mes
    GOTO VERIRELOJ	; Si no regresa al loop de reloj para multiplexar
    BCF CAMBIO, 1	; Si si limpia la bandera del botón
    
    DECF CONTMES, F	; Decrementa unidades del mes
    MOVF CONTMES, W
    SUBLW 0		; Revisa luego del decremento es 0
    BTFSS STATUS, 2 
    GOTO DECMES2	; Si no es 0 revisa si es -1
    
    MOVF CONTMES2, W	; Si es 0 revisa las decenas del mes
    SUBLW 0
    BTFSS STATUS, 2	; Si en las decenas no hay un cero regresa al loop
    GOTO VERIRELOJ	
    
    MOVLW 2		; Si hay un 0 debe cargar el 2 a las unidades
    MOVWF CONTMES
    MOVLW 1		; Y carga un 1 a las decenas de mes
    MOVWF CONTMES2
    GOTO VERIRELOJ	; Regresa al loop del reloj

DECMES2:
    MOVF CONTMES, W
    SUBLW -1		; Revisa si unidades de mes es -1
    BTFSS STATUS, 2
    GOTO VERIRELOJ	; Si no lo es solo regresa al loop
    
    DECF CONTMES2, F	; Si lo es es porque debe decrementar las decenas
    
    MOVLW 9		; Y pasar las unidades a 9
    MOVWF CONTMES
    GOTO VERIRELOJ	; Regresa al loop del reloj

REVISIONDIASMES:	; Revisa que no existan valores prohibidos
    CALL DETERMINARMES
    
    MOVF DETMES, W	; Si DETMES es 2 entonces tiene 28 días
    SUBLW 2
    BTFSC STATUS, 2 
    GOTO COMPROBAR28	; Revisará que el contador de días no esté en 30 o 31
    
    MOVF DETMES, W	; Si DETMES es 3 entonces tiene 30 días
    SUBLW 3
    BTFSC STATUS, 2
    GOTO COMPROBAR30	; Revisará que el contador de días no esté en 31
    
    RETURN
    
COMPROBAR28:
    MOVF CONTDIA2, W	; Revisa si hay un 3 en las decenas de días
    SUBLW 3
    BTFSS STATUS, 2
    RETURN		; Si no lo hay regresa de la subrutina
    
    MOVLW 2		; Si lo hay carga un dos en las decenas de días
    MOVWF CONTDIA2
    MOVLW 8		; y carga un 8 en las unidades
    MOVWF CONTDIA
    RETURN
    
COMPROBAR30:
    MOVF CONTDIA2, W	; Revisa si hay un 3 en las decenas de días
    SUBLW 3
    BTFSS STATUS, 2
    RETURN		; Si no, regresa de la subrutina
    
    MOVF CONTDIA, W	; Si si revisa si hay un 1 en las unidades
    SUBLW 1
    BTFSS STATUS, 2
    RETURN		; Si no lo hay regresa de la subrutina
    
    MOVLW 3		; Si lo hay carga el 3 a las decenas de días
    MOVWF CONTDIA2
    MOVLW 0		; y carga 0 en las unidades
    MOVWF CONTDIA
    RETURN
  
; ******************************************************************************
; MODO CONFIGURACIÓN DE ALARMA
; ******************************************************************************  
SET_ALARMA:
    BCF PORTE, 2	; Apaga leds titilantes
    MOVLW 00100000B	; Enciende el bit 5 del puerto C
    MOVWF PORTC
    INCF ESTADO, F	; Incrementa el estado para avisar que guardó las 
			; variables del reloj
    MOVF CONTHOR, W	; Guarda variable de unidades de hora en var temporal
    MOVWF HORA1_TEMP
    
    MOVF CONTHOR2, W	; Guarda las decenas de hora en variable temporal
    MOVWF HORA2_TEMP
    
    MOVF CONTMIN, W	; Guarda las unidades de minuto en variable temporal
    MOVWF MIN1_TEMP
    
    MOVF CONTMIN2, W	; Guarda las decenas de minuto en variable temporal
    MOVWF MIN2_TEMP
    
    GOTO CAMBIOMIN	; Inicia los ajustes de la alarma
    
ALARMASETED:
    MOVF CONTHOR, W	; Guarda el valor elegido para la alarma de unidad hora
    MOVWF VALARMA_H1	
    
    MOVF CONTHOR2, W	; Guarda el valor de decenas de hora para la alarma
    MOVWF VALARMA_H2
    
    MOVF CONTMIN, W	; Guarda el valor de unidades de minuto para la alarma
    MOVWF VALARMA_M1
    
    MOVF CONTMIN2, W	; Guarda el valor de decenas de minuto para la alarma
    MOVWF VALARMA_M2
    
    
    MOVF HORA1_TEMP, W	; Regresa la hora del reloj de la variable temporal
    MOVWF CONTHOR
    
    MOVF HORA2_TEMP, W	; Regresa la hora del reloj de la variable temporal
    MOVWF CONTHOR2
    
    MOVF MIN1_TEMP, W	; Regresa los minutos del reloj de la variable temporal
    MOVWF CONTMIN
    
    MOVF MIN2_TEMP, W	; Regresa los minutos del reloj de la variable temporal
    MOVWF CONTMIN2
    
    BSF VRELOJ, 1	; Indica que la alarma se configuró
    CLRF ESTADO		; Limpia la variable estado para regresar al reloj
   
    GOTO LOOP
    
REVISIONALARMA:
    BTFSS VRELOJ, 1	; Revisa si la alarma está configurada
    RETURN		; Si no, regresa de la subrutina
	
    MOVF VALARMA_H2, W	; Si si, compara el valor de las decenas de horas
    SUBWF VDISP6, 0	; de la alarma con el valor que muestra el display
    BTFSS STATUS, 2	; Si no son iguales regresa
    RETURN	    
	
    MOVF VALARMA_H1, W	; Si son iguales compara las unidades de hora
    SUBWF VDISP5, 0
    BTFSS STATUS, 2	; Si no son iguales regresa de la subrutina
    RETURN
    
    MOVF VALARMA_M2, W	; Compara el valor de decenas de minutos
    SUBWF VDISP4, 0
    BTFSS STATUS, 2	; Si no son iguales regresa de la subrutina
    RETURN
    
    MOVF VALARMA_M1, W	; Compara el valor de las unidades de minutos
    SUBWF VDISP3, 0	
    BTFSS STATUS, 2	; Si no son iguales regresa de la subrutina
    RETURN
    
    BSF PORTC, 4	; Si son iguales todos los valores comparados, enciende
    BCF VRELOJ, 1	; la alarma e indica que ya se repita a la misma hora
    BSF VRELOJ, 2	; Avisa que mientras este bit esté encendido la alarma
			; debe seguir sonando
    RETURN		; Regresa de la subrutina
    
PULSOSALARMA:
    BTFSS VRELOJ, 2	; Revisa si debe seguir enviando pulsos al buzzer
    RETURN    
    BTFSC PORTC, 4	; Si el buzzer tiene un 1 lo manda a poner en 0
    GOTO ESTADODOWN
    BSF PORTC, 4	; Si tiene un 0 le pone un 1 cada vez que la instrucción
    RETURN		; Se repite (Debe sonar según la frecuencia con la que
			; se ejecutan las instrucciones < 4MHz
    
ESTADODOWN:
    BCF PORTC, 4
    RETURN
    
APAGARALARMA:
    BTFSS VRELOJ, 2	; Revisa si está sonando la alarma
    RETURN		; Si no, regresa de la subrutina
    
    BTFSC VRELOJ, 0	; Revisa si está en el estado de reloj-fecha
    GOTO APAGAR		; si no, apaga la alarma cuando se hacen cambios
    
    MOVF CONTSEG2, W	; Si si, compara el valor de decenas de segundos
    SUBLW 1		; con 1 para saber si pasaron 10 segundos
    BTFSS STATUS, 2	; Si no los han pasado, regresa de la subrutina
    RETURN
    
APAGAR:
    BCF VRELOJ, 2	; Si ya pasaron apaga la alarma y regresa al loop
    BCF PORTC, 4
    RETURN
;*******************************************************************************
; FIN DEL CÓDIGO
;*******************************************************************************     
END
