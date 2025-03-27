#include <xc.inc>
extrn	Pre_Game_Init
extrn	GLCD_Clear_Screen
extrn	Button_Read
extrn	pressed_button
extrn	GLCD_Render_GameOver, GLCD_Render_RestartMessage
extrn	Display_Score, Display_High_Score, Check_Update_High_Score
extrn	delay_ms
global	GameOverHandler
psect	udata_acs		
rm_1_2:	    ds	1
frame_cnt:  ds	1

psect	data
	
psect	game_over_code,class=CODE

GameOverHandler:
    call    GLCD_Render_GameOver 
    movlw   100
    call    delay_ms
    call    GLCD_Clear_Screen
    movlw   0
    movwf   rm_1_2, A

_game_over_loop:
    call    Check_Update_High_Score
    call    Display_Score
    call    Display_High_Score
    call    GLCD_Render_GameOver
    movlw   0                    
    cpfseq  rm_1_2, A            ; If Dino_1_2 == 0 (Z flag set), branch to Use_RUN1
    goto    Use_RM2
    
Use_RM1:
    call    GLCD_Render_RestartMessage
    goto    After_rm
Use_RM2:
    goto    After_rm

After_rm:
    movlw   5
    call    delay_ms

    ; Update positions for next frame
    call    Update_RestartMessage
 
    call    Button_Read
    
    movf    pressed_button, W, A
    movlw   0
    cpfseq  pressed_button, A
    goto    Pre_Game_Init

    goto    _game_over_loop
end_game_over:
    return

Update_RestartMessage:
    ; Increment the frame counter
    incf    frame_cnt, F, A      ; FrameCounter = FrameCounter + 1
    
    movlw   80                  
    cpfseq  frame_cnt, A            ; If result is NOT zero, FrameCounter != 20
    goto    End_Update            ; Skip update if not equal

    ; Otherwise, if FrameCounter == 20, update the cactus position
    movlw   1
    xorwf   rm_1_2, F, A       ; Toggle Dino_1_2 (0 becomes 1, 1 becomes 0)
    call    GLCD_Clear_Screen
    clrf    frame_cnt, A    ; Reset FrameCounter

End_Update:
    return