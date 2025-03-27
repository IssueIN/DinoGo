#include <xc.inc>
extrn	GLCD_Render_Cactus, GLCD_Render_DINO_RUN1, GLCD_Clear_Screen, GLCD_Render_DINO_RUN2, GLCD_Render_DINO_JUMP, GLCD_Render_DINO_DUCK1, GLCD_Render_DINO_DUCK2 
extrn	GLCD_Render_Bird1, GLCD_Render_Bird2, GLCD_Clear_DINO_JUMP, GLCD_Render_ML
extrn	Button_Read
extrn	pressed_button
extrn	GLCD_Render_Cactus_Large, GLCD_Render_Cactus_Medium, GLCD_Render_Cactus_Small 
extrn	Update_Score, Display_Score, Display_High_Score, Check_Update_High_Score
extrn	Update_Spawn_Timer, Render_Agent_1,Render_Agent_2, Get_Agent_1_type, Get_Agent_2_type, Update_Agent_1, Update_Agent_2
extrn	Check_Collision, Is_Game_Over
extrn	GameOverHandler
extrn	GLCD_Read_Screen_UART, Display_RNG, Draw_Digit
extrn	Display_Agent_Freq
extrn	ML_Inference
extrn	delay_x4us, delay_ms
extrn	Prepare_State_Vector
 
global	page_coord, y_coord, DINO_y, DINO_page, DINO_STATE
global	FrameLoop, Initialize
psect	udata_acs		
page_coord:	    ds 1
y_coord:	    ds 1
frame_cnt:	    ds 1
DINO_page:	    ds 1
DINO_1_2:	    ds 1
score_update_cnt:   ds 1
DG_tmp:		    ds 1

; New variables:
DINO_STATE:	    ds 1    ; 0=idle, 1 = ascending, 2 = descending, 3=ducking
JUMP_DELAY:	    ds 1    ; frames to wait at this phases

psect	data
FRAME_DELAY	    EQU 3
SCORE_UPDATE_FREQ   EQU	30
DINO_y		    EQU 25
ML_STATE	    EQU	0

psect	game_display_code,class=CODE
 
Initialize:
    movlw   0
    movwf   DINO_1_2, A
    
    ; Initialize continuous jump:
    movlw   0
    movwf   DINO_STATE, A      
    movlw   6
    movwf   DINO_page, A      ; begin at page 6
    movlw   15
    movwf   JUMP_DELAY, A      ; initial delay
    
    clrf    score_update_cnt, A
   
    return


FrameLoop:
    ;call    GLCD_Clear_Screen       ; Clear the screen for the new frame
    
    call    Display_Score
    call    Display_High_Score
    call    _Update_Score
    
    call    Is_Game_Over
    movwf   DG_tmp, A
    movlw   0
    cpfseq  DG_tmp, A
    goto    GameOverHandler
    
    movlw   0
    cpfseq  ML_STATE, A
    goto    ML_Mode
    
Manual_Mode:
    call    Button_Read
    goto    DINO_Action
    ;movf    DINO_STATE, W, A

ML_Mode:
    call    Prepare_State_Vector
    call    ML_Inference
    movwf   pressed_button, A
    call    GLCD_Render_ML
    movf    pressed_button, W, A
    call    Draw_Digit
    
DINO_Action:
    movlw   1
    cpfseq  DINO_STATE, A
    goto    _StateUpdateCheck2
    goto    _SkipStateUpdate
    
_StateUpdateCheck2:
    movlw   2
    cpfseq  DINO_STATE, A
    goto    _StateUpdate
    goto    _SkipStateUpdate

_StateUpdate: 
    movf    pressed_button, W, A
    movwf   DINO_STATE, A
    
_SkipStateUpdate:
    movf    DINO_STATE, W, A
    movlw   3
    cpfseq  DINO_STATE, A
    bra	    _state_check_2
    goto    DINO_DUCK           ; state=3

 _state_check_2:
    movlw   1
    cpfseq  DINO_STATE, A
    bra	    _state_check_3
    goto    DINO_JUMP           ; state=1

 _state_check_3:
    movlw   2
    cpfseq  DINO_STATE, A
    goto    DINO_RUN		; state=0
    goto    DINO_JUMP           ; state=2
    
DINO_DUCK:
    movlw   7     
    movwf   page_coord, A           ; Set page coordinate for dinosaur
    movwf   DINO_page, A
    movlw   30         
    movwf   y_coord, A            ; Set y coordinate for dinosaur
    
    ; Check which dinosaur sprite to render:
    movlw   0                    
    cpfseq  DINO_1_2, A            ; If Dino_1_2 == 0 (Z flag set), branch to Use_RUN1
    goto    Use_DUCK2
    
Use_DUCK1:
    call    GLCD_Render_DINO_DUCK1
    goto    After_Dino
Use_DUCK2:
    call    GLCD_Render_DINO_DUCK2
    goto    After_Dino

DINO_RUN: 
    ; Render Dinosaur:
    movlw   6     
    movwf   page_coord, A           ; Set page coordinate for dinosaur
    movwf   DINO_page, A   
    movlw   DINO_y     
    movwf   y_coord, A            ; Set y coordinate for dinosaur
    
    ; Check which dinosaur sprite to render:
    movlw   0                    
    cpfseq  DINO_1_2, A            ; If Dino_1_2 == 0 (Z flag set), branch to Use_RUN1
    goto    Use_RUN2
Use_RUN1:
    call    GLCD_Render_DINO_RUN1 ; Render dinosaur RUN1 sprite
    goto    After_Dino
Use_RUN2:
    call    GLCD_Render_DINO_RUN2 ; Render dinosaur RUN2 sprite
    goto    After_Dino
 
DINO_JUMP:    
    call    Update_Jump
    ; Set a fixed horizontal coordinate for the dinosaur (y_coord remains same)
    movlw   DINO_y
    movwf   y_coord, A 
    movf    DINO_page, W, A
    movwf   page_coord, A
;   movwf   page_coord, A            ; Set x coordinate for obstacle 1

    ; Render the dinosaur jump sprite using the updated page_coord
    call    GLCD_Render_DINO_JUMP

  
After_Dino: 
    call    Get_Agent_1_type
    movwf   DG_tmp, A
    movlw   0
    cpfseq  DG_tmp, A
    goto    Activate_Agent_1
    goto    check_agent_2_state

Activate_Agent_1:
    call    Render_Agent_1
    call    Update_Agent_1
 
check_agent_2_state:
    call    Get_Agent_2_type
    movwf   DG_tmp, A
    movlw   0
    cpfseq  DG_tmp, A
    goto    Activate_Agent_2
    goto    After_Agent
   
Activate_Agent_2:
    call    Render_Agent_2
    call    Update_Agent_2

After_Agent:
    ;call    Check_Collision
    
    ; Delay for a short period (frame duration)
    movlw   FRAME_DELAY
    call    delay_x4us
    
    call    Update_Spawn_Timer
    ; Update positions for next frame
    call    Update_Sprite_Position

    ; Render Bird:    
;    movlw   2   
;    movwf   page_coord, A           ; Set page coordinate for dinosaur
;    movf    BIRD_Y, W, A    
;    movwf   y_coord, A            ; Set y coordinate for dinosaur
;    
;     ; Check which dinosaur sprite to render:
;    movlw   0                    
;    cpfseq  BIRD_1_2, A            ; If Dino_1_2 == 0 (Z flag set), branch to Use_RUN1
;    goto    Use_BIRD2
;Use_BIRD1:
;    call    GLCD_Render_Bird1 ; Render dinosaur RUN1 sprite
;    goto    After_Bird
;Use_BIRD2:
;    call    GLCD_Render_Bird2 ; Render dinosaur RUN2 sprite
;    goto    After_Bird
;
;After_Bird:
;    ; Render Obstacle 1
;    movlw   5
;    movwf   page_coord, A            ; Set x coordinate for obstacle 1
;    movf    CACTUS_Y, W, A
;    movwf   y_coord, A            ; Set y coordinate for obstacle 1
;    call    GLCD_Render_Cactus    ; Render obstacle sprite
;    
;    movlw   5
;    movwf   page_coord, A            ; Set x coordinate for obstacle 1
;    movlw   30
;    movwf   y_coord, A            ; Set y coordinate for obstacle 1
;    call    GLCD_Render_Cactus_Large    ; Render obstacle sprite
;    
;    movlw   5
;    movwf   page_coord, A            ; Set x coordinate for obstacle 1
;    movlw   70
;    movwf   y_coord, A            ; Set y coordinate for obstacle 1
;    call    GLCD_Render_Cactus_Medium    ; Render obstacle sprite
;    
;    movlw   6
;    movwf   page_coord, A            ; Set x coordinate for obstacle 1
;    movlw   110
;    movwf   y_coord, A            ; Set y coordinate for obstacle 1
;    call    GLCD_Render_Cactus_Small    ; Render obstacle sprite
;    
;    call    Update_Bird
    
    ; Delay for a short period (frame duration)
    movlw   FRAME_DELAY
    ;call    Display_Game_delay_x4us
    call    delay_ms

    
    call    Update_Spawn_Timer
    ; Update positions for next frame
    call    Update_Sprite_Position
    call    Display_RNG
    call    Display_Agent_Freq
    
    ;call    GLCD_Read_Screen_UART

    goto    FrameLoop

Update_Sprite_Position:
    ; Increment the frame counter
    incf    frame_cnt, F, A      ; FrameCounter = FrameCounter + 1
    
    movlw   30                   
    cpfseq  frame_cnt, A            ; If result is NOT zero, FrameCounter != 20
    goto    End_Update            ; Skip update if not equal

    ; Otherwise, if FrameCounter == 20, update the cactus position
    movlw   1
    xorwf   DINO_1_2, F, A       ; Toggle Dino_1_2 (0 becomes 1, 1 becomes 0)
    clrf    frame_cnt, A    ; Reset FrameCounter
    call    GLCD_Clear_Screen       ; Clear the screen for the new frame

End_Update:
    return
 
;Update_Bird:
;    incf    bird_delay_cnt, F, A          
;    movlw   30                    
;    cpfseq  bird_delay_cnt, A          
;    goto    End_Update_BIRD            
;
;    movlw   1       
;    xorwf   BIRD_1_2, F, A
;    decf    BIRD_Y, F, A      
;    clrf    bird_delay_cnt, A
    ;call    GLCD_Clear_Screen 

End_Update_BIRD:
    return

Update_Jump:
    ; Decrement delay ? if not zero, do nothing
    decfsz  JUMP_DELAY, F, A
    return
    
    call    GLCD_Clear_DINO_JUMP
    ; Delay expired: advance phase
    movlw   1
    cpfseq  DINO_STATE, A
    goto    DescendPhase

    ; Ascending
    decf    DINO_page, F, A
    movlw   2	    ; maximum page
    cpfseq  DINO_page, A
    goto    SetPhase
    movlw   2
    movwf   DINO_STATE, A
    goto    SetPhase

DescendPhase:
    ; Descending
    incf    DINO_page, F, A
    movlw   6
    cpfseq  DINO_page, A
    goto    SetPhase
    movlw   0
    movwf   DINO_STATE, A

SetPhase:
    ; Phase 0
    movlw   6
    cpfseq  DINO_page, A
    goto    Phase5
    movlw   15
    movwf   JUMP_DELAY, A
    return

Phase5:
    movlw   5
    cpfseq  DINO_page, A
    goto    Phase4
    movlw   20
    movwf   JUMP_DELAY, A
    return

Phase4:
    movlw   4
    cpfseq  DINO_page, A
    goto    Phase3
    movlw   25
    movwf   JUMP_DELAY, A
    return

Phase3:
    movlw   3
    cpfseq  DINO_page, A
    goto    Phase2
    movlw   30
    movwf   JUMP_DELAY, A
    return

Phase2:
    movlw   35
    movwf   JUMP_DELAY, A
    return
;    movlw   2
;    cpfseq  DINO_page, A
;    goto    Phase1
;    movlw   25
;    movwf   JUMP_DELAY, A
;    return
;
;Phase1:
;    movlw   25
;    movwf   JUMP_DELAY, A
;    return


_Update_Score:
    incf    score_update_cnt, F, A
    movlw   SCORE_UPDATE_FREQ
    cpfseq  score_update_cnt, A 
    goto    _End_Update_Score
    call    Update_Score
    clrf    score_update_cnt, A
_End_Update_Score:
    return


Delay:
    movlw   0xFF
    movwf   0x20, A
D_Loop:
    decfsz  0X20, F, A
    goto    D_Loop
    return
 