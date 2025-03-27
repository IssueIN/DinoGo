#include <xc.inc>
    
global  Button_Setup, Button_Read
global  pressed_button

psect udata_acs	; reserve data space in access ram
button_value:	ds   1	; reserve 1 byte for variable button_value
pressed_button: ds   1

psect	button_code,class=CODE

Button_Setup:   
    clrf    LATE, A  
    movlw   00000111B	    ; Set RE0:2 as Inputs
    movwf   TRISE, A
    return

Button_Read:
    clrf    LATE, A
    movf    PORTE, W, A 
    andlw   0x07
    movwf   button_value, A
    call    Button_Decode
    movwf   pressed_button, A
    return

Button_Decode:    
    tstfsz  button_value, A   ; Test if button_value is 0 (no button pressed)
    goto    check_red
    movlw   0x00      ; No button pressed
    return

check_red:
    movlw   0x01           ; 0000 0001 (RE0 = 1)
    cpfseq  button_value, A
    goto    check_blue
    movlw   1            ; 'R' for Red
    return 

check_blue:
    movlw   0x02           ; 0000 0010 (RE1 = 1)
    cpfseq  button_value, A
    goto    check_yellow
    movlw   3            ; 'B' for Blue
    return 

check_yellow:
    movlw   0x04           ; 0000 0100 (RE2 = 1)
    cpfseq  button_value, A
    goto    err_pressed
    movlw   0            ; 'Y' for Yellow
    return

err_pressed: 
    ; Multiple keys pressed or no key pressed
    movlw   0x00
    return