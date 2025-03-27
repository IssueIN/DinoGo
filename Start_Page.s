#include <xc.inc>
extrn	GLCD_Render_Slogan, GLCD_Render_DinoGo, GLCD_Clear_Screen
extrn	Button_Read
extrn	pressed_button
extrn	GLCD_Read_Screen_UART
global	StartLoop_Initialize, StartLoop
psect	udata_acs		
SLOGAN_1_2:	    ds 1
frame_cnt:	    ds 1

psect	data
	
psect	start_loop_code,class=CODE

StartLoop_Initialize:
    movlw   0
    movwf   SLOGAN_1_2, A

StartLoop:
    ;call    GLCD_Clear_Screen       ; Clear the screen for the new frame
    call    Button_Read
    call    GLCD_Render_DinoGo   
    
    movf    pressed_button, W, A
    movlw   0
    cpfseq  pressed_button, A
    goto    end_StartLoop
    
_slogan:  
    ; Check which dinosaur sprite to render:
    movlw   0                    
    cpfseq  SLOGAN_1_2, A            ; If Dino_1_2 == 0 (Z flag set), branch to Use_RUN1
    goto    Use_slogan2
    
Use_slogan1:
    call    GLCD_Render_Slogan
    goto    After_sl
Use_slogan2:
    goto    After_sl

After_sl:
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

    ; Update positions for next frame
    call    Update_Slogan
        
    ;call    GLCD_Read_Screen_UART

    goto    StartLoop
end_StartLoop:
    return

Update_Slogan:
    ; Increment the frame counter
    incf    frame_cnt, F, A      ; FrameCounter = FrameCounter + 1
    
    movlw   80                  
    cpfseq  frame_cnt, A            ; If result is NOT zero, FrameCounter != 20
    goto    End_Update            ; Skip update if not equal

    ; Otherwise, if FrameCounter == 20, update the cactus position
    movlw   1
    xorwf   SLOGAN_1_2, F, A       ; Toggle Dino_1_2 (0 becomes 1, 1 becomes 0)
    call    GLCD_Clear_Screen
    clrf    frame_cnt, A    ; Reset FrameCounter

End_Update:
    return
