#include <xc.inc>
extrn	Pre_Game_Init
extrn	GLCD_Clear_Screen
extrn	Button_Read
extrn	pressed_button
extrn	GLCD_Render_GameOver, GLCD_Render_RestartMessage
extrn	Display_Score, Display_High_Score, Check_Update_High_Score
extrn	delay_ms
    
global	GameOverHandler

psect	data
	
psect	game_over_code,class=CODE

GameOverHandler:
    call    GLCD_Render_GameOver 
    movlw   100
    call    delay_ms
    call    GLCD_Clear_Screen

_game_over_loop:
    call    Check_Update_High_Score
    call    Display_Score
    call    Display_High_Score
    call    GLCD_Render_GameOver

    call    GLCD_Render_RestartMessage

    call    Button_Read
    
    movf    pressed_button, W, A
    movlw   0
    cpfseq  pressed_button, A
    goto    Pre_Game_Init

    goto    _game_over_loop
end_game_over:
    return
  
END