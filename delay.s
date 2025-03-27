#include <xc.inc>

global	delay_ms, delay_x4us
psect	udata_acs		
delay_cnt_ms:  ds	1
delay_cnt_l:   ds	1
delay_cnt_h:   ds	1

psect	data
	
psect	start_loop_code,class=CODE
	
delay_ms:		    ; delay given in ms in W
	movwf	delay_cnt_ms, A
lp2:	movlw	250	    ; 1 ms delay
	call	delay_x4us	
	decfsz	delay_cnt_ms, A
	bra	lp2
	return
    
delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	delay_cnt_l, A	; now need to multiply by 16
	swapf   delay_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	delay_cnt_l, W, A ; move low nibble to W
	movwf	delay_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	delay_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	delay
	return

delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lp1:	decf 	delay_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	delay_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc	lp1		; carry, then loop again
	return	

