;; Panasonic CD Changer Emulator
;;
;; Copyright (c) 2003, Kristoffer Sjöberg <kristoffer@netstar.se>
;; Inspired by Edward Schlunder <zilym@yahoo.com>

; Note:	20MHz / 4 = 5MHz. 1/5MHz = 0.2us.
;       So each PIC instruction takes 0.2 microseconds long.
	
	LIST P=16F84A, R=DEC
	__CONFIG _WDT_OFF & _PWRTE_ON & _CP_OFF & _HS_OSC

#include <p16f84a.inc>
	EXTERN	send_RS232, receive_RS232, rxbyte
	EXTERN	msecDelay, tenth_msecDelay


;--------------------------------------------------------------------------
; Connections
;--------------------------------------------------------------------------
; PIC16F84A Pin  1 RA2 -> DIN8C Pin 2 SCLK to Head Unit
; PIC16F84A Pin  2 RA3 -> DIN8C Pin 1 STX  to Head Unit
; PIC16F84A Pin 18 RA1 -> DIN8C Pin 4 SYNC to Head Unit
; PIC16F84A Pin ?? RB0 <- DIN8C Pin ? RM to Head Unit


; RS232-Connections
; 57600bps, 8n1
;
; Table describes a 9 pin DSUB connector (female, same applies to male)
;
; Short DB9F Pin 4 	<> 	DB9F Pin 6  (DSR follows DTR)
; PIC TX out 	RB1 	-> 	DB9F Pin 2, RXD
; PIC RX in	RB2  	<- 	DB9F Pin 3, TXD
; PIC RTS in	RB3  	<- 	DB9F Pin 7, RTS
; PIC CTS out	RB4  	-> 	DB9F Pin 8, CTS
;
;
;

; 
; Make sure PIC and Head Unit have common GND.
;--------------------------------------------------------------------------

SCLK		EQU	2 ; PORTA
STX		EQU	3 ; PORTA
SYNC		EQU	1 ; PORTA

#DEFINE	CDC_RM		PORTB,0
#DEFINE DCE_RX		PORTB,2		; PICs RX-pin
#DEFINE DTE_CTS		PORTB,4

;--------------------------------------------------------------------------
; Variables
;--------------------------------------------------------------------------

; RAM MEMORY MAP
	UDATA
;Temporary register for transmit to head unit
txreg	RES	1

; Display information
cdc_disc	RES	1
cdc_track	RES	1
cdc_minute	RES	1
cdc_second	RES	1
cdc_mode	RES	1

;RM data
RM_temp		RES	1
RM_byte0	RES	1
RM_byte1	RES	1
RM_byte2	RES	1
RM_byte3	RES	1

RM_bitnum	RES	1
RM_pulse_length	RES	1
RM_count	RES	1
RM_tempbyte	RES	1

receive_state	RES	1


IdleLoop1	RES	1
IdleLoop2	RES	1

; Interrupt RAM, used for saving registers during an interrupt
W_TEMP		RES	1	; temporarily holds value of W
STATUS_TEMP	RES	1	; temporarily holds value of STATUS



;--------------------------------------------------------------------------
; Program Code
;--------------------------------------------------------------------------
Reset	CODE	0x000
	goto	Start

;--------------------------------------------------------------------------
; Interrupt Service Routine at 0x004
;--------------------------------------------------------------------------
ISV	CODE	0x004
	retfie



Intrrpt	CODE
;--------------------------------------------------------------------------
; Interrupt handler
;--------------------------------------------------------------------------
interrupt
	;Save W and STATUS-registers
	movwf	W_TEMP
	swapf	STATUS, W	; Without changing STATUS, it's moved (will be swapped back at restore)
	movwf	STATUS_TEMP


	btfss	INTCON, T0IF
	goto	interrupt_done	; It wasn't a Timer-interrupt - go to next interrupt handler

timer_interrupt
	call	ReceiveRM
	movf	RM_temp,F	; RM_temp is non-zero if data has been received
	btfss	STATUS,Z	; Skip next line if zero...
	call	SendRM_RS232	; Send data by RS232

interrupt_done
	swapf	STATUS_TEMP, W	; Move to W, without changing flags
	movwf	STATUS		; And restore STATUS-register
	swapf	W_TEMP, F	; Do a swap
	swapf	W_TEMP, W	; And swap it into W-register (moves W without changing STATUS flags)

	bcf	INTCON, T0IF	; Clear the Timer0-flag
	retfie

Main	CODE
;--------------------------------------------------------------------------
; Main Program
;--------------------------------------------------------------------------

Start
	clrf	INTCON		; Disable all interrupts 

	clrf	STATUS		; Force data bank 0
	clrf	PORTA		; initialize port a to 0
	clrf	PORTB		; initialize port b to 0

	bsf	STATUS, RP0	; select data bank 1

	movlw	b'00001101'	; moves 0x00 into the W register
	movwf	TRISB		; tri-states portb pins to be mostly outputs, RB0&RB3 input (RB3 is RS232-RTS)

	movlw	b'00000000'
	movwf	TRISA		; tri-states porta pins to be all inputs


;Enable the timer
	bcf	OPTION_REG, T0CS ; Use the internal instruction cycle clock for the timer
	bsf	OPTION_REG, PSA  ; We do not want to use our prescaler

	bcf	OPTION_REG, PS2  ; Set Prescaler
	bcf	OPTION_REG, PS1  ; 
	bcf	OPTION_REG, PS0  ; 


	bcf	INTCON, GIE	; Global Interrupts Disable
	bcf	INTCON, T0IE	; Disable Timer Interrupt On Overflow

	bcf	STATUS, RP0	; go back to data bank 0

	movlw	0x41
	movwf	cdc_disc
	movlw	0x00
	movwf	cdc_track
	movwf	cdc_minute
	movwf	cdc_second
	movwf	cdc_mode	; 0x01=??, 0x02=CD blink, 0x04=Random, 0x08=Repeat, 0x10=Track blink, 0x20=??, 0x40=??, 0x80=??,

	movlw	5		; next received byte will reset the counter to save on
	movwf	receive_state



IdleLoop

	call	SendPacket

	;10ms = 5000 instructions

	movlw	2
	movwf	IdleLoop2

IdleLoopOuter
	movlw	250
	movwf	IdleLoop1

	bcf	DTE_CTS	; Enable Clear To Send
IdleLoopInner
	btfss	DCE_RX
	call	ReceiveData

	decfsz	IdleLoop1,F
	goto	IdleLoopInner

	bsf	DTE_CTS	; Disable Clear To Send

	call	ReceiveRM
	movf	RM_temp,F	; RM_temp is non-zero if data has been received
	btfss	STATUS,Z	; Skip next line if zero...
	call	SendRM_RS232	; Send data by RS232

	decfsz	IdleLoop2,F
	goto	IdleLoopOuter


	goto	IdleLoop

ReceiveData	; Get data from DTE, parse.
	bsf	DTE_CTS	; Disable Clear To Send

	call	receive_RS232
;	movf	rxbyte,W
;	call	send_RS232	; Echo, debug

	movlw	0xFF ; test for reset-byte
	subwf	rxbyte,W
	btfsc	STATUS,Z
	goto	ReceiveData_Reset

	
ReceiveData_DisplayByte
ReceiveData_CDC_Disc
	movlw	0x05	subwf	receive_state,W
	btfss	STATUS,Z
	goto	ReceiveData_CDC_Track
	movf	rxbyte,W
	movwf	cdc_disc
ReceiveData_CDC_Track
	movlw	0x04	subwf	receive_state,W
	btfss	STATUS,Z
	goto	ReceiveData_CDC_Minute
	movf	rxbyte,W
	movwf	cdc_track
ReceiveData_CDC_Minute
	movlw	0x03	subwf	receive_state,W
	btfss	STATUS,Z
	goto	ReceiveData_CDC_Second
	movf	rxbyte,W
	movwf	cdc_minute
ReceiveData_CDC_Second
	movlw	0x02	subwf	receive_state,W
	btfss	STATUS,Z
	goto	ReceiveData_CDC_Mode
	movf	rxbyte,W
	movwf	cdc_second
ReceiveData_CDC_Mode
	movlw	0x01	subwf	receive_state,W
	btfss	STATUS,Z
	goto	ReceiveData_PrepareNextByte

	movf	rxbyte,W
	movwf	cdc_mode

ReceiveData_PrepareNextByte

		

	clrf	rxbyte


	decfsz	receive_state,F
	goto	ReceiveData_Done
	goto	ReceiveData_Reset


ReceiveData_Done

	return

ReceiveData_Reset
	movlw	0x05
	movwf	receive_state
	goto	ReceiveData_Done


TranslateRM
	movwf	RM_tempbyte

	movlw	0x54	; track <
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'<'

	movlw	0x58	; track >
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'>'

	movlw	0x60	; Disc Down
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'P'	; 'P'revious

	movlw	0x70	; Disc Up
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'N'	; 'N'ext

	movlw	0x48	; Random
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'R'	; 'R'andom

	movlw	0x40	; OFF
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'0'	; Turn off scanning and random


	movlw	0x2C	; Scan
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'S'	; 'S'can

	movlw	0x52	; Scan (OFF)
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	's'	; 'S'can


	movlw	0x64	; repeat
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'r'	; 'r'epeat


	movlw	0x1c	; Init
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'I'	; 'I'n

	movlw	0x14	; ON
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'O'	; 'O'n

	movlw	0x20	; Off (ping)
	subwf	RM_tempbyte,W
	btfsc	STATUS,Z
	retlw	'o'	; 'o'ff


;	movf	RM_tempbyte,W
;	return
	retlw	'?'	; catch-all
;--------------------------------------------------------------------------
; SendRM_RS232 - Sends the received RM signal over RS232 to DTE
;--------------------------------------------------------------------------
SendRM_RS232


	movlw	2
	subwf	RM_temp,W

	btfsc	STATUS,Z
	goto	SendRM_RS232_Repeat

	movlw	'.'
	call	send_RS232	




	goto	SendRM_RS232_Done

SendRM_RS232_Repeat
;	movlw	13
;	call	send_RS232	
;	movlw	10
;	call	send_RS232	
	movlw	':'
	call	send_RS232	

SendRM_RS232_Done

	movf	RM_byte2,W
	call	TranslateRM
	call	send_RS232	


	clrf	RM_temp
	return


;--------------------------------------------------------------------------
; ReceiveRM - Receives the remote control signal pulse...
;--------------------------------------------------------------------------
ReceiveRM
	btfss	CDC_RM
	return

	movlw	d'7'	;Bits in a byte
	movwf	RM_bitnum

	;time the first low pulse
	;first low is 4.5ms for a command, 2.25ms for a repeated button

	call	RM_time_pulse

	;check whether the pulse was too short to be a low pulse...
	movlw	d'20'	; 2.0ms
	subwf	RM_pulse_length, W
	btfss	STATUS,C	;If it was positive... skip next line
	goto	ReceiveRM_error	;pulse too short

	movf	RM_pulse_length,W	

	;22<=w<=25 if it was a repeated button... >40 if it was a command.
	movlw	d'40'	; 4.0ms
	subwf	RM_pulse_length, W
	btfss	STATUS,C		;If it was positive... skip next line
	goto	ReceiveRM_repeat	;pulse too short to be a command (and by the previous check long enough to be a repeat)


	;ok, now we have to time the pulses to retrieve the command

	call	RM_get_byte
	movwf	RM_byte0

	call	RM_get_byte
	movwf	RM_byte1

	call	RM_get_byte
	movwf	RM_byte2

	call	RM_get_byte
	movwf	RM_byte3

	movlw	0x01
	movwf	RM_temp
	
	return
ReceiveRM_repeat
	movlw	0x02
	movwf	RM_temp
	return

ReceiveRM_error
	movlw	0x00
	movwf	RM_temp
ReceiveRM_done

	return


RM_get_byte
	movlw	0x00
	movwf	RM_tempbyte
	movlw	0x07
	movwf	RM_bitnum
RM_get_bit
	call	RM_time_pulse
	sublw	0x0A
	btfsc	STATUS, C	; if set, we got a 0 - else, we got a 1
	goto	RM_got_bit_0
	; We got a 1 - save it
	; We need to save it in reverse order - this is one way to do it.
	movlw	0x00
	movwf	RM_temp
	movf	RM_bitnum,W
	sublw	.8		; 8 bits in a byte. (We'll shift it 7-IR_bitnum steps to the right.)
	movwf	RM_count
	bsf	STATUS,C
RM_got_bit_1_shift_right	
	rlf	RM_temp,F
	decfsz	RM_count,F
	goto	RM_got_bit_1_shift_right
	movf	RM_temp,W
	iorwf	RM_tempbyte,F

RM_got_bit_0
	movf	RM_pulse_length, W
	sublw	d'20' ;2.0 ms, longer than that is timeout
	btfss	STATUS,C

	retlw	0xFF	; Timeout - bit too long (1,4ms)

	decfsz	RM_bitnum,F
	goto	RM_get_bit

	movf	RM_tempbyte,W
	return



;Routine times the length of an RM-pulse in multiples of 100uS
RM_time_pulse
	movlw	0x00
	movwf	RM_pulse_length
RM_wait_for_pulse
	btfsc	CDC_RM
	goto	RM_wait_for_pulse
RM_time_pulse_loop
	btfsc	CDC_RM	; If there's no activity (Bit set) the pulse has ended
	goto	RM_time_pulse_done

	call	tenth_msecDelay
	incfsz	RM_pulse_length, F
	goto	RM_time_pulse_loop
RM_time_pulse_done
	movf	RM_pulse_length, W
	return




;--------------------------------------------------------------------------
; SendSync - Sends synchronization bit to head unit
;--------------------------------------------------------------------------
SendSync
	bsf	PORTA, SYNC
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	bcf	PORTA, SYNC
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop

	nop
	return

;--------------------------------------------------------------------------
; SendPacket - sends a display update packet to the head unit
;              currently hard coded to display "CD 1 Tr 1" on head unit
;--------------------------------------------------------------------------
SendPacket


	call	SendSync


;	movlw	0xBD ; BE		; disc
;	movlw	0x41
	movf	cdc_disc, W
	call	SendByte

;	movlw	0xFE		; track
;	movlw	0x23
	movf	cdc_track, W
	call	SendByte


;	movlw	0xFE		; ??
;	movlw	0x45
	movf	cdc_minute, W
	call	SendByte


;	movlw	0xFE
;	movlw	0x60
	movf	cdc_second, W
	call	SendByte


;	movlw	0xFF		; mode (scan/mix)
;	movlw	0x00
	movf	cdc_mode, W
	call	SendByte


;	movlw	0x8F
	movlw	0x30
	call	SendByte


;	movlw	0x7C
	movlw	0xC3
	call	SendByte

	call	SendSync

	return

;--------------------------------------------------------------------------
; SendByte - sends a byte to head unit.
;            load byte to send to head unit into W register before 
calling
;--------------------------------------------------------------------------
SendByte
	movwf	txreg
	movlw	-8
	bcf	INTCON, GIE	; disable interrupts, timing critical

BitLoop
	rlf	txreg, 1	; load the next bit into the carry flag		;	4.0	LOW
	nop
	nop
	nop
	nop

	bsf	PORTA, SCLK	; SCLK high			;	1.0	HIGH
	nop
	nop
	nop
	nop

	bsf	PORTA, STX	; load the next bit onto STX	;	0.2	HIGH
	nop
	nop
	nop
	nop

	btfsc	STATUS, C					;	0.4	HIGH
	bcf	PORTA, STX					;	0.6	HIGH
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	nop
	nop
	nop
	nop
	nop
;	nop

	bcf	PORTA, SCLK	; SCLK low	;	0.2	LOW
	addlw	1	;	5.2		;	1	LOW

;	nop
;	nop
;	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop

	nop
	nop
	nop
	nop
	nop
	nop

	btfss	STATUS, Z	;5.4		;	1	LOW
	goto	BitLoop		;5.8		;	2	LOW

	bsf	INTCON, GIE	; re-enable interrupts
	

	
	movlw	-84		; wait 335us for head unit to store sent byte
DelayLoop	
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	addlw	1

	btfss	STATUS, Z
	goto	DelayLoop


	return

	END

