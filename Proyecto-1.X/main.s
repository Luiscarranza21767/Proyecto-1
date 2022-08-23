;*******************************************************************************
; Universidad del Valle de Guatemala
; IE2023 Programación de Microcontroladores
; Autor: Luis Pablo Carranza
; Compilador: PIC-AS (v2.4), MPLAB X IDE (v6.00)
; Proyecto: Proyecto de laboratorio 1
; Hardware PIC16F887
; Creado: 23/08/22
; Última Modificación: 23/08/22
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
    GOTO POP
    
RTMR0:
    BCF INTCON, 2	; Limpia la bandera de interrupción
    BANKSEL TMR0	
    INCF CONT10MS	; Incrementa la variable del TMR0
    MOVLW 217		; Carga el valor de n al TMR0
    MOVWF TMR0	
    INCF CONTMUX
    GOTO POP
    
POP:			    ; Regresar valores de W y de STATUS
    SWAPF STATUS_TEMP, W
    MOVWF STATUS
    SWAPF W_TEMP, F
    SWAPF W_TEMP, W
    RETFIE

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
    MOVLW 11111000B ; El bit 6 y 7 son entradas, el resto salidas
    MOVWF TRISB		
    CLRF TRISA
    CLRF TRISC
    CLRF TRISD	    ; El resto de puertos configurados como salidas
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 5	; T0CS FOSC/4 modo temporizador
    BCF OPTION_REG, 3	; PSA asignar presscaler para TMR0
    
    BSF OPTION_REG, 2	
    BSF OPTION_REG, 1
    BSF OPTION_REG, 0	; Prescaler 1:256
    
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
;    BSF INTCON, 3   ; RBIE Habilitar interrupciones de PORTB
    BCF INTCON, 2   ; Bandera T0IF apagada
;    BCF INTCON, 0   ; Bandera de interrupción de puerto B apagada
    
    BANKSEL WPUB
    MOVLW 11111000B ; Solo bit 7 y 6 son entradas con pull-up e ITO
    MOVWF IOCB
    MOVWF WPUB
    
    BANKSEL TMR0
    MOVLW 217
    MOVWF TMR0	    ; Se carga el valor de TMR0
    CLRF CONT10MS
    CLRF CONTMUX
    CLRF CONTSEG
    CLRF CONTSEG2
    CLRF CONTMIN
    CLRF CONTMIN2   
    CLRF CONTHOR
    CLRF CONTHOR2
    
LOOP:

    
VERIRELOJ:
    MOVF CONTMUX, W	; Carga el valor de la variable a W
    SUBLW 5		; Resta el valor a 5
    BTFSC STATUS, 2	; Revisa si el resultado es 0
    CALL MULTIPLEX	; Llama para la multiplexación cada 50ms
    
    MOVF CONT10MS, W	; Carga el valor de la variable a W
    SUBLW 100		; Resta el valor a 100
    BTFSS STATUS, 2	; Revisa si el resultado es 0
    GOTO VERIRELOJ	; Si no es 0 regresa a verificación del reloj
    CLRF CONT10MS	; Si es 0 limpia la variable y vuelve al loop
    
    
    INCF CONTSEG, F
    MOVF CONTSEG, W
    SUBLW 10
    BTFSS STATUS, 2
    GOTO LOOP
    INCF CONTSEG2
    CLRF CONTSEG
    
    MOVF CONTSEG2, W
    SUBLW 6
    BTFSS STATUS, 2
    GOTO LOOP
    INCF CONTMIN, F
    CLRF CONTSEG
    CLRF CONTSEG2
    
    MOVF CONTMIN, W
    SUBLW 10
    BTFSS STATUS, 2
    GOTO LOOP
    INCF CONTMIN2, F
    CLRF CONTMIN
    
    MOVF CONTMIN2, W
    SUBLW 6
    BTFSS STATUS, 2
    GOTO LOOP
    INCF CONTHOR, F
    CLRF CONTMIN
    CLRF CONTMIN2
    CLRF CONTSEG
    CLRF CONTSEG2
    
    MOVF CONTHOR, W
    SUBLW 10
    BTFSS STATUS, 2
    GOTO LOOP
    INCF CONTHOR2, F
    CLRF CONTHOR
    CLRF CONTMIN
    CLRF CONTMIN2
    CLRF CONTSEG
    CLRF CONTSEG2
    
    MOVF CONTHOR2, W
    SUBLW 24
    BTFSS STATUS, 2
    GOTO LOOP
    CLRF CONTHOR
    CLRF CONTHOR2
    CLRF CONTMIN
    CLRF CONTMIN2
    CLRF CONTSEG
    CLRF CONTSEG2
    
    
    GOTO LOOP
    
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
    MOVF CONTSEG, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP2:   
    INCF PORTD, F
    MOVF CONTSEG2, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP3:
    MOVLW 4
    MOVWF PORTD
    MOVF CONTMIN, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    
    RETURN
    
DISP4:
    MOVLW 8
    MOVWF PORTD
    MOVF CONTMIN2, W
    CALL Table
    MOVWF PORTA
    CLRF CONTMUX
    RETURN
    
DISP5:
    MOVLW 16
    MOVWF PORTD
    MOVF CONTHOR, W
    CALL Table
    MOVWF PORTA    
    CLRF CONTMUX
    RETURN

DISP6:
    MOVLW 32
    MOVWF PORTD
    MOVF CONTHOR2, W
    CALL Table
    MOVWF PORTA    
    CLRF CONTMUX
    RETURN
    
; ******************************************************************************
; Tablas
; ******************************************************************************   
Table:
    CLRF PCLATH
    BSF PCLATH, 0
    ANDLW 0x0F
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
    
;*******************************************************************************
; FIN DEL CÓDIGO
;******************************************************************************* 
END
