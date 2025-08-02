	INCLUDE "P16F84A.INC"					; include the default equates
	LIST P=16F84A, R=DEC						; initialize to the correct PIC type

	UDATA
delaycounter RES 1

	CODE
	
tenth_msecDelay	;	100us on 20MHz Crystal
	GLOBAL tenth_msecDelay
	movlw	d'123'
	movwf	delaycounter
tenth_msecDelay_inner
	nop
	decfsz	delaycounter, F
	goto	tenth_msecDelay_inner
	nop

	nop
	nop
	return



msecDelay	; delays 1 ms
	GLOBAL msecDelay
	movlw	185
	movwf	delaycounter

msecDelay_inner	;2+((inner2)+3)*delaycounter+2
	movlw	-6
msecDelay_inner2	; (4*6) = inner2
	addlw	1
	btfss	STATUS,Z
	goto	msecDelay_inner2

	decfsz	delaycounter, F
	goto	msecDelay_inner
	
	return
	
	
	END
