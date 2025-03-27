#include <xc.inc>

extrn	UART_Setup, UART_Transmit_Byte ; external subroutines
extrn	Button_Setup, Button_Read
extrn	GLCD_Setup, GLCD_Data, GLCD_Display_On, GLCD_Clear_Screen, GLCD_Render_DINO_RUN1, GLCD_Render_DinoGo, GLCD_Render_Slogan
extrn	FrameLoop, Initialize
extrn	StartLoop, StartLoop_Initialize
extrn	Initialize_Score
extrn	Spawn_Manager_Init
extrn	Init_Collision
extrn	pressed_button
global	Pre_Game_Init
	
;psect	udata_acs   ; reserve data space in access ram
;TempVal:    ds 1
;counter:    ds 1    ; reserve one byte for a counter variable
;delay_count:ds 1    ; reserve one byte for counter in the delay routine

psect	code, abs	
rst: 	org 0x0
 	goto	setup
	
setup:	bcf	CFGS	; point to Flash program memory  
	bsf	EEPGD 	; access Flash program memory
	call	UART_Setup	; setup UART
	call	Button_Setup	; setup button
	call	GLCD_Setup
	call	Initialize_Score
	call	StartLoop_Initialize
	call	StartLoop
Pre_Game_Init:
	call	Initialize
	call	Spawn_Manager_Init
	call	Init_Collision
	goto	loop
	
loop:	
	;call	Button_Read
	;movf    pressed_button, W, A  ; Load key_value into WREG
	
	;call	LFSR_Shift
	;call	LFSR_Read
	
	; glcd test
;	movlw	3
	;call	GLCD_MOVE_CACTUS
	call	FrameLoop
	;call	GLCD_DINO_RUN1
	; Send via UART
;	movlw   0x53
;	addlw	'0'
;	call    UART_Transmit_Byte

	;call	delay
	goto	loop		; Repeat indefinitely
	


;delay:	movlw	0xFF
;	movwf	delay_count, A
;	
;delay_loop:	
;	decfsz	delay_count, A	; decrement until zero
;	bra	delay_loop
;	return
;
	end	rst