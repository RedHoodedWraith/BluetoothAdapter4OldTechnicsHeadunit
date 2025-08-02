#DEFINE	_RS232_TX	PORTB, 1
#DEFINE	_RS232_RX	PORTB, 2
#DEFINE _RS232_RTS	PORTB, 3
#DEFINE _RS232_CTS	PORTB, 4

	INCLUDE "P16F84A.INC"					; include the default equates
	LIST P=16F84A						; initialize to the correct PIC type

baudrate	equ	.26	; (([instructionrate]/.2400)/3-2) ;2400 is the baud rate (26=57600@5MHz instruction rate (20MHz))



	UDATA
txbyte		RES	1
rxbyte		RES	1
count		RES	1
delay_len	RES	1

	
	GLOBAL	txbyte, rxbyte
	CODE

;******RS232 SEND (TRANSMIT) ROUTINE *******
send_RS232
	GLOBAL	send_RS232
	movwf   txbyte
	bcf     _RS232_TX             ;send start bit
	movlw   baudrate
	movwf   delay_len
	movlw   .9
	movwf   count
txbaudwait
	decfsz  delay_len,F
	goto    txbaudwait ; waits (3*baudrate)+1 instruction
	movlw   baudrate   ; 
	movwf   delay_len
	decfsz  count,F
	goto    sendnextbit
	movlw   .9
	movwf   count
	bsf     _RS232_TX             ;send stop bit
	retlw   0
sendnextbit
	rrf     txbyte,F
	btfss   STATUS,C              ;check next bit to tx
	goto    setlo
	bsf     _RS232_TX             ;send a high bit
	goto    txbaudwait
setlo
	bcf     _RS232_TX             ;send a low bit
	goto    txbaudwait

;*******RS232 RECEIVE ROUTINE *********
receive_RS232
	GLOBAL	receive_RS232
receive_RS232_wait		; Wait for data
	btfsc   _RS232_RX
	goto    receive_RS232_wait

	movlw   baudrate
	movwf   delay_len
rxbaudwait
	decfsz  delay_len,F
	goto    rxbaudwait
	movlw   baudrate
	movwf   delay_len
	decfsz  count,F
	goto    recvnextbit
	movlw   .9
	movwf   count
	retlw   0		; ^-- Return to callee
recvnextbit
	bcf     STATUS, C
	btfsc   _RS232_RX
	bsf     STATUS, C
	rrf     rxbyte,F

	goto    rxbaudwait


	END
