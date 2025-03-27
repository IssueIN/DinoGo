#include <xc.inc>
extrn	GLCD_Render_Slogan, GLCD_Render_DinoGo, GLCD_Clear_Screen
extrn	Button_Read
extrn	pressed_button
extrn	GLCD_Read_Screen_UART
global	StartLoop_Initialize, StartLoop

psect	data
	
psect	start_loop_code,class=CODE

StartLoop_Initialize:
    return
StartLoop:
    ;call    GLCD_Clear_Screen       ; Clear the screen for the new frame
    call    Button_Read
    call    GLCD_Render_DinoGo   
    
    movf    pressed_button, W, A
    movlw   0
    cpfseq  pressed_button, A
    goto    end_StartLoop
    call    GLCD_Render_Slogan

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

        
    ;call    GLCD_Read_Screen_UART

    goto    StartLoop
end_StartLoop:
    return

end