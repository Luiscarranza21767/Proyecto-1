;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Luis Pablo Carranza
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: Proyecto de laboratorio 1
; Hardware PIC16F887
; Creado: 23/08/22
; Última Modificación: 03/09/22
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
 VDISP6:
    DS 1
 VRELOJ:
    DS 1
 DETMES:
    DS 1
    
PSECT udata_shr
 W_TEMP:	; Variable para almacenar W durante interrupciones
    DS 1
 STATUS_TEMP:	; Variable para almacenar STATUS durante interrupciones
    DS 1
 CONT10MS:	; Contador de 10 ms
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
 CONTDIA:
    DS 1
 CONTDIA2:
    DS 1
 CONTMES:
    DS 1
 CONTMES2:
    DS 1
 ESTADO:
    DS 1
 CAMBIO:
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
    
ISR:
    BTFSC INTCON, 2
    GOTO RTMR0
    BTFSC INTCON, 0
    GOTO RRBIF
    GOTO POP
    
RTMR0:
    BCF INTCON, 2	; Limpia la bandera de interrupción
    BANKSEL TMR0	
    INCF CONT10MS	; Incrementa la variable de 10 ms
    MOVLW 217		; Carga el valor de n al TMR0
    MOVWF TMR0	
    INCF CONTMUX	; Incrementa variable para el multiplexor
    GOTO POP
    
RRBIF:
    MOVF ESTADO, W
    SUBLW 0
    BTFSC STATUS, 2
    GOTO ESTADO0_ISR	; Estado de reloj
    
    MOVF ESTADO, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO ESTADO1_ISR	; Estado de fecha
    
    MOVF ESTADO, W
    SUBLW 2
    BTFSC STATUS, 2
    GOTO ESTADO2_ISR	; Estado de cambio de minutos
    
    GOTO POP
   
ESTADO0_ISR:		; Reloj normal
    BANKSEL PORTB
    BTFSS PORTB, 0
    INCF ESTADO, F
    BCF INTCON, 0
    GOTO POP
    
ESTADO1_ISR:		; Reloj normal
    BANKSEL PORTB
    BTFSS PORTB, 0
    INCF ESTADO, F
    BCF INTCON, 0
    GOTO POP

ESTADO2_ISR:		; Cambio de minutos
    BANKSEL PORTB
    BTFSS PORTB, 0
    CLRF ESTADO	; TEMPORALLLLL
    
    BTFSS PORTB, 1
    CALL PUSH1_PRESSED
    BTFSS PORTB, 2
    CALL PUSH2_PRESSED
    BTFSS PORTB, 3
    CALL PUSH3_PRESSED
    BTFSS PORTB, 4
    CALL PUSH4_PRESSED
    
    BCF INTCON, 0
    GOTO POP
  
PUSH1_PRESSED:
    BTFSS PORTB, 1
    GOTO $-1
    BSF CAMBIO, 0
    RETURN
 
PUSH2_PRESSED:
    BTFSS PORTB, 2
    GOTO $-1
    BSF CAMBIO, 1
    RETURN

PUSH3_PRESSED:
    BTFSS PORTB, 3
    GOTO $-1
    BSF CAMBIO, 2
    RETURN
 
PUSH4_PRESSED:
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
    MOVLW 00011111B ; El bit 6 y 7 son entradas, el resto salidas
    MOVWF TRISB		
    CLRF TRISA
    CLRF TRISC
    CLRF TRISD	    ; El resto de puertos configurados como salidas
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 5	; T0CS FOSC/4 modo temporizador
    BCF OPTION_REG, 3	; PSA asignar presscaler para TMR0
    
    BSF OPTION_REG, 2	
    BSF OPTION_REG, 1
    BCF OPTION_REG, 0	; Prescaler 1:128
    
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
    MOVLW 00011111B ; Solo bit 7 y 6 son entradas con pull-up e ITO
    MOVWF IOCB	    ; Interrupt on change
    MOVWF WPUB	    ; Pull ups del puerto B
    
    BANKSEL TMR0
    MOVLW 217	    ; Valor calculado para 10 ms
    MOVWF TMR0	    ; Se carga el valor de TMR0
	
    
    CLRF ESTADO
    
    CLRF VDISP1
    CLRF VDISP2
    CLRF VDISP3
    CLRF VDISP4
    CLRF VDISP5
    CLRF VDISP6
    
    CLRF VRELOJ
    
    MOVLW 1
    MOVWF CONTDIA
    MOVWF CONTMES
    MOVWF DETMES
    
    CLRF CONTDIA2
    CLRF CONTMES2
    
    CLRF CONT10MS   ; Se limpian todas las variables antes de iniciar
    CLRF CONTMUX
    CLRF CONTSEG
    CLRF CONTSEG2
    CLRF CONTMIN
    CLRF CONTMIN2   
    CLRF CONTHOR
    CLRF CONTHOR2
    
; ******************************************************************************
; LOOP PRINCIPAL
; ******************************************************************************   
    
LOOP:
    MOVF ESTADO, W
    SUBLW 0
    BTFSC STATUS, 2
    CALL MRELOJ		; Estado de cambio de minutos
    
    MOVF ESTADO, W
    SUBLW 1
    BTFSC STATUS, 2
    CALL MFECHA		; Estado de cambio de minutos
    
    MOVF ESTADO, W
    SUBLW 2
    BTFSC STATUS, 2
    GOTO CAMBIOMIN	; Estado de cambio de minutos

; ******************************************************************************
; MODO RELOJ
; ******************************************************************************      
VERIRELOJ:
    MOVF ESTADO, W
    SUBLW 2
    BTFSC STATUS, 2
    CALL MRELOJ		; Estado de cambio de minutos
    
    MOVF CONTMUX, W	; Carga el valor de la variable a W
    SUBLW 14		; Resta el valor a 5
    BTFSC STATUS, 2	; Revisa si el resultado es 0
    CALL MULTIPLEX	; Llama para la multiplexación cada 50ms
    
    BTFSS VRELOJ, 0
    GOTO RELOJ
    
    GOTO LOOP
    
RELOJ:    
    MOVF CONT10MS, W	; Carga el valor de la variable a W
    SUBLW 200		; Resta el valor a 100
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    GOTO VERIRELOJ	; Si no es 0 regresa a verificación del reloj
    CLRF CONT10MS	; Si es 0 limpia la variable
     
    INCF CONTSEG, F	; Incrementa el primer display de segundos
    MOVF CONTSEG, W
    SUBLW 10		; Resta a 10 para verificar si debe incrementar el 2do
    BTFSS STATUS, 2
    GOTO LOOP		; Si no es 0 regresa al loop
    INCF CONTSEG2	; Si es 0 incrementa segundo display
    CLRF CONTSEG	; Reinicia el primer display
    
    MOVF CONTSEG2, W	; Mueve el valor del display 2 a W
    SUBLW 6		; Lo resta a 6
    BTFSS STATUS, 2	; Si el resultado es 0 salta la instrucción 
    GOTO LOOP		; Si no es 0 regresa al loop
    INCF CONTMIN, F	; Incrementa el contador de minutos
    CLRF CONTSEG	; Limpia ambos contadores de segundos
    CLRF CONTSEG2
    
INCREMENTOMIN:    
    MOVF CONTMIN, W	; Mueve el valor del display de minutos a W
    SUBLW 10		; Lo resta a 10
    BTFSS STATUS, 2
    GOTO LOOP		; Si el resultado no es 0 regresa al loop
    INCF CONTMIN2, F	; Si es 0 incrementa el segundo display de minutos
    CLRF CONTMIN	; Limpia el contador de minutos
    
    MOVF CONTMIN2, W	; Mueve el valor del segundo display de minutos a W
    SUBLW 6		; Resta el valor a 6
    BTFSS STATUS, 2	
    GOTO LOOP		; Si el resultado es 0 regresa al loop
    CLRF CONTMIN	; Limpia el resto de variables del reloj
    CLRF CONTMIN2
    
    BTFSS VRELOJ, 0
    GOTO INCREMENTOHOR
    
    GOTO LOOP
    
INCREMENTOHOR:  
    INCF CONTHOR, F	; Si es 0 incrementa el contador de hora
    MOVF CONTHOR, W	; Mueve el valor del display de horas a W   
    SUBLW 10		; Resta el valor a 10
    BTFSS STATUS, 2	
    GOTO REVCAMBIOHOR	; Si el resultado no es 0 regresa al loop
    INCF CONTHOR2, F	; Incrementa el segundo display de horas
    CLRF CONTHOR	; Limpia todas
  
    MOVF ESTADO, W
    SUBLW 0
    BTFSS STATUS, 2
    GOTO LOOP
    
REVCAMBIOHOR:
    MOVF CONTHOR2, W
    SUBLW 2
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVF CONTHOR, W
    SUBLW 4
    BTFSS STATUS, 2
    GOTO LOOP
    
    CLRF CONTHOR
    CLRF CONTHOR2
    
    BTFSS VRELOJ, 0
    GOTO INCREMENTODIA
    
    
    GOTO LOOP

; ******************************************************************************
; MULTIPLEXADO
; ******************************************************************************  
MULTIPLEX:
    MOVF PORTD, W
    SUBLW 0
    BTFSC STATUS, 2
    GOTO DISP1
    
    MOVF PORTD, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO DISP2
    
    MOVF PORTD, W
    SUBLW 2
    BTFSC STATUS, 2
    GOTO DISP3

    MOVF PORTD, W
    SUBLW 4
    BTFSC STATUS, 2
    GOTO DISP4
    
    MOVF PORTD, W
    SUBLW 8
    BTFSC STATUS, 2
    GOTO DISP5
    
    MOVF PORTD, W
    SUBLW 16
    BTFSC STATUS, 2
    GOTO DISP6
    
    MOVF PORTD, W
    SUBLW 32
    BTFSC STATUS, 2
    CLRF PORTD
    RETURN
    
DISP1:
    BSF PORTD, 0
    MOVF VDISP1, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP2:   
    INCF PORTD, F
    MOVF VDISP2, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP3:
    MOVLW 4
    MOVWF PORTD
    MOVF VDISP3, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP4:
    MOVLW 8
    MOVWF PORTD
    MOVF VDISP4, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP5:
    MOVLW 16
    MOVWF PORTD
    MOVF VDISP5, W
    CALL Table
    MOVWF PORTA    
    CLRF CONTMUX
    RETURN

DISP6:
    MOVLW 32
    MOVWF PORTD
    MOVF VDISP6, W
    CALL Table
    MOVWF PORTA    
    CLRF CONTMUX
    RETURN

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
; MODO CAMBIO RELOJ
; ****************************************************************************** 
MRELOJ:
    MOVF CONTSEG, W
    MOVWF VDISP1
    
    MOVF CONTSEG2, W
    MOVWF VDISP2
    
    MOVF CONTMIN, W
    MOVWF VDISP3 
    
    MOVF CONTMIN2, W
    MOVWF VDISP4
    
    MOVF CONTHOR, W
    MOVWF VDISP5
    
    MOVF CONTHOR2, W
    MOVWF VDISP6
    
    RETURN
    
; ******************************************************************************
; MODO FECHA
; ****************************************************************************** 
MFECHA:
    MOVF CONTDIA, W
    MOVWF VDISP3 
    
    MOVF CONTDIA2, W
    MOVWF VDISP4
    
    MOVF CONTMES, W
    MOVWF VDISP5
    
    MOVF CONTMES2, W
    MOVWF VDISP6
    
    RETURN
    
INCREMENTODIA:
    INCF CONTDIA, F
    MOVF CONTDIA, W
    SUBLW 10
    BTFSS STATUS, 2
    GOTO REVCAMBIODIA
    
    INCF CONTDIA2
    CLRF CONTDIA
    GOTO LOOP
    
REVCAMBIODIA:
    CALL DETERMINARMES
    
    MOVF DETMES, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO CAMBIOMES31
    
    MOVF DETMES, W
    SUBLW 2
    BTFSC STATUS, 2
    GOTO CAMBIOMES28
    
    MOVF DETMES, W
    SUBLW 3
    BTFSC STATUS, 2
    GOTO CAMBIOMES30
 
CAMBIOMES31:
    MOVF CONTDIA2, W
    SUBLW 3
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVF CONTDIA, W
    SUBLW 2
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVLW 1
    MOVWF CONTDIA
    CLRF CONTDIA2
    
    BTFSS VRELOJ, 0
    GOTO LOOP
    
    GOTO LOOP
   
CAMBIOMES28:
    MOVF CONTDIA2, W
    SUBLW 2
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVF CONTDIA, W
    SUBLW 9
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVLW 1
    MOVWF CONTDIA
    CLRF CONTDIA2
    
    BTFSS VRELOJ, 0
    GOTO LOOP
    
    GOTO LOOP

CAMBIOMES30:
    MOVF CONTDIA2, W
    SUBLW 3
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVF CONTDIA, W
    SUBLW 1
    BTFSS STATUS, 2
    GOTO LOOP
    
    MOVLW 1
    MOVWF CONTDIA
    CLRF CONTDIA2
    
    BTFSS VRELOJ, 0
    GOTO LOOP
    
    GOTO LOOP

DETERMINARMES:
    MOVF CONTMES, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO TMES1
    
    MOVF CONTMES, W
    SUBLW 2
    BTFSC STATUS, 2
    GOTO TMES2
    
    MOVF CONTMES, W
    SUBLW 3
    BTFSC STATUS, 2
    GOTO TMES11
    
    MOVF CONTMES, W
    SUBLW 4
    BTFSC STATUS, 2
    GOTO TMES3
    
    MOVF CONTMES, W
    SUBLW 5
    BTFSC STATUS, 2
    GOTO TMES11
    
    MOVF CONTMES, W
    SUBLW 6
    BTFSC STATUS, 2
    GOTO TMES3
    
    MOVF CONTMES, W
    SUBLW 7
    BTFSC STATUS, 2
    GOTO TMES11
    
    MOVF CONTMES, W
    SUBLW 8
    BTFSC STATUS, 2
    GOTO TMES11
    
    MOVF CONTMES, W
    SUBLW 9
    BTFSC STATUS, 2
    GOTO TMES3
    
    MOVF CONTMES, W
    SUBLW 0
    BTFSC STATUS, 2
    GOTO TMES11
    
TMES1:
    MOVF CONTMES2, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO TMES3
    
TMES11:
    MOVLW 1
    MOVWF DETMES
    RETURN
    
TMES2:
    MOVF CONTMES2, W
    SUBLW 1
    BTFSC STATUS, 2
    GOTO TMES11
    
    MOVLW 2
    MOVWF DETMES
    RETURN
 
TMES3:
    MOVLW 3
    MOVWF DETMES
    RETURN
    
; ******************************************************************************
; MODO CAMBIO DE MINUTOS/HORA
; ******************************************************************************      
CAMBIOMIN:
    BCF VRELOJ, 0
    CLRF CONTSEG
    CLRF CONTSEG2
    BTFSS CAMBIO, 0
    GOTO DECMIN
    BCF CAMBIO, 0
    INCF CONTMIN, F
    GOTO INCREMENTOMIN
 
DECMIN:
    BTFSS CAMBIO, 1
    GOTO CAMBIOHOR
    BCF CAMBIO, 1
    DECF CONTMIN, F
    MOVF CONTMIN, W
    SUBLW -1
    BTFSS STATUS, 2
    GOTO VERIRELOJ
    MOVLW 9
    MOVWF CONTMIN
    
    DECF CONTMIN2, F
    MOVF CONTMIN2, W
    SUBLW -1
    BTFSS STATUS, 2
    GOTO VERIRELOJ
    MOVLW 5
    MOVWF CONTMIN2
    GOTO VERIRELOJ

CAMBIOHOR:
    BTFSS CAMBIO, 2
    GOTO DECHOR
    BCF CAMBIO, 2
    GOTO INCREMENTOHOR
 
DECHOR:
    BTFSS CAMBIO, 3
    GOTO VERIRELOJ
    BCF CAMBIO, 3
    DECF CONTHOR, F
    MOVF CONTHOR, W
    SUBLW -1
    BTFSS STATUS, 2
    GOTO VERIRELOJ
    
    DECF CONTHOR2, F
    MOVF CONTHOR2, W
    SUBLW -1
    BTFSC STATUS, 2
    GOTO RESETHOR
    
    MOVLW 9
    MOVWF CONTHOR
    GOTO VERIRELOJ
    
RESETHOR:
    MOVLW 2
    MOVWF CONTHOR2
    MOVLW 3
    MOVWF CONTHOR
    GOTO VERIRELOJ

;*******************************************************************************
; FIN DEL CÓDIGO
;******************************************************************************* 
END
