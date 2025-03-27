#include <xc.inc>
global	Spawn_Manager_Init
global	Update_Spawn_Timer, Render_Agent_1, Render_Agent_2, Get_Agent_1_type, Get_Agent_2_type, Update_Agent_1, Update_Agent_2
global	agent_1_y, agent_2_y, agent_1_type, agent_2_type, agent_1_bird_h, agent_2_bird_h
global	used_rng_ob, used_rng_bird, Update_Agent_Freq, Display_Agent_Freq
global	Agent_Freq, active_agent_flag
extrn	Initialize_RNG, Next_RNG, Display_RNG, Get_Random_Obstacle, Get_Random_Height
extrn	GLCD_Set_Page, GLCD_Set_Y, GLCD_Data, GLCD_Clear_Screen
extrn	GLCD_Render_Cactus_Large, GLCD_Render_Cactus_Medium, GLCD_Render_Cactus_Small, GLCD_Render_Bird1, GLCD_Render_Bird2
extrn	GLCD_Clear_Cactus_Large, GLCD_Clear_Cactus_Medium, GLCD_Clear_Cactus_Small, GLCD_Clear_Bird1, GLCD_Clear_Bird2
extrn	GLCD_Render_Speed, Render_Digit, Display_Speed
extrn	page_coord, y_coord
; Variables in access bank
psect   udata_acs
agent_1_type:	ds 1
agent_1_y:	ds 1
agent_1_cnt:	ds 1
agent_1_bird_h:	ds 1
agent_1_bird_1_2:ds 1
agent_2_type:	ds 1
agent_2_y:	ds 1
agent_2_cnt:	ds 1
agent_2_bird_h:	ds 1
agent_2_bird_1_2:   ds	1
active_agent_flag:  ds	1 ;0-no 1-1 2-2 3-both
bird_h:		ds 1
bird_1_2:	ds 1
spawn_counter:	ds 1
obstacle_type_tmp:  ds	1
render_type_tmp:    ds	1
tmp:		    ds	1
used_rng_ob:	    ds	1
used_rng_bird:	    ds	1
Agent_Freq:	    ds	1
Freq_Update_cnt:    ds	1

;current_agent_freq: ds 1
    
; Bitmap data for digits 0-9 (5x8 pixels)
psect   data    
Digit_Data:
    db  0x3E, 0x51, 0x49, 0x45, 0x3E  ; 0
    db  0x00, 0x42, 0x7F, 0x40, 0x00  ; 1
    db  0x42, 0x61, 0x51, 0x49, 0x46  ; 2
    db  0x21, 0x41, 0x45, 0x4B, 0x31  ; 3
    db  0x18, 0x14, 0x12, 0x7F, 0x10  ; 4
    db  0x27, 0x45, 0x45, 0x45, 0x39  ; 5
    db  0x3C, 0x4A, 0x49, 0x49, 0x30  ; 6
    db  0x01, 0x71, 0x09, 0x05, 0x03  ; 7
    db  0x36, 0x49, 0x49, 0x49, 0x36  ; 8
    db  0x06, 0x49, 0x49, 0x29, 0x1E  ; 9
    
    SPAWN_FREQ	EQU 50
    AGENT1_FREQ	EQU 4
    AGENT2_FREQ	EQU 4
    
psect   spawn_code,class=CODE


Spawn_Manager_Init:
    call    Initialize_RNG
    movlw   0
    movwf   agent_1_type, A
    movwf   agent_2_type, A
    movwf   agent_1_y, A
    movwf   agent_2_y, A
    movwf   active_agent_flag, A
    movwf   Freq_Update_cnt, A
    movwf   spawn_counter, A
    
    movlw   20
    movwf   Agent_Freq, A ; initial speed
    
    clrf    used_rng_ob, A
    clrf    used_rng_bird, A
;     movlw   INITIAL_AGENT_FREQ
;     movwf   current_agent_freq, A
    return

Update_Spawn_Timer:
    incf    spawn_counter, F, A
    movlw   SPAWN_FREQ
    cpfseq  spawn_counter, A
    return
    
    clrf    spawn_counter, A
    
    call    Next_RNG
    call    Get_Random_Obstacle
    movwf   obstacle_type_tmp, A
    
    movlw   0
    cpfseq  obstacle_type_tmp, A
    bra     _check_agent_1
    goto    _end_update
 
_check_agent_1:
    movlw   0
    cpfseq  active_agent_flag, A
    bra	    _check_agent_2
    bra	    Agent_1_init
_check_agent_2:
    movlw   1
    cpfseq  active_agent_flag, A
    bra	    _check_agent_3
    bra	    _check_y_add_1
_check_agent_3:
    movlw   2
    cpfseq  active_agent_flag, A
    bra	    _end_update
    bra	    _check_y_add_2
_check_y_add_1:
    movlw   64
    cpfslt  agent_1_y, A
    bra	    _end_update
    bra	    Agent_2_init
_check_y_add_2:
    movlw   64
    cpfslt  agent_2_y, A
    bra	    _end_update
    bra	    Agent_1_init
    
;_check_agent_1:
;    movlw   0
;    cpfseq  agent_1_type, A
;    bra	    _check_agent_2
;    goto    Agent_1_init    
;
;_check_agent_2:
;    movlw   0
;    cpfseq  agent_2_type, A
;    bra	    _end_update
;    goto    Agent_2_init
;
_end_update:
    return
 
Agent_1_init:
    clrf    agent_1_type, A
    clrf    agent_1_y, A
    clrf    agent_1_bird_h, A
    clrf    agent_1_cnt, A
    clrf    agent_1_bird_1_2, A
    
    movlw   1
    call    update_active_flag
    
    call    Update_Agent_Freq
    
    movf    obstacle_type_tmp, W, A
    movwf   agent_1_type, A
    movwf   used_rng_ob, A
    
    movlw   4
    cpfseq  agent_1_type, A
    goto    _continue_init_1
    call    Get_Random_Height
    movwf   agent_1_bird_h, A
    movwf   used_rng_bird, A
    
_continue_init_1:
    movlw   138
    movwf   agent_1_y, A
    return
 
Render_Agent_1:
    movf    agent_1_y, W, A
    movwf   y_coord, A
    movf    agent_1_bird_1_2, W, A
    movwf   bird_1_2, A
    movf    agent_1_bird_h, W, A
    movwf   bird_h, A
    movf    agent_1_type, W, A
    call    Get_Render_Sprite
    return

Update_Agent_1:
    incf    agent_1_cnt, F, A
    
    movlw   Agent_Freq                   
    cpfseq  agent_1_cnt, A            
    goto    End_Update_1  
    
;    movf    agent_2_y, W, A
;    movwf   y_coord, A
;    movf    agent_2_bird_1_2, W, A
;    movwf   bird_1_2, A
;    movf    agent_2_bird_h, W, A
;    movwf   bird_h, A
;    movf    agent_2_type, W, A
;    call    Clear_Render_Sprite
    movf    agent_1_y, W, A
    movwf   y_coord, A
    movf    agent_1_bird_1_2, W, A
    movwf   bird_1_2, A
    movf    agent_1_bird_h, W, A
    movwf   bird_h, A
    movf    agent_1_type, W, A
    call    Clear_Render_Sprite
    
    movlw   1
    xorwf   agent_1_bird_1_2, F, A
    
    movlw   8
    movwf   tmp, A

dec_Loop_agent_1:
    decf    agent_1_y, F, A
    decfsz  tmp, F, A
    goto    dec_Loop_agent_1
    
    movlw   8
    cpfslt  agent_1_y, A
    goto    continue_update_1
    goto    End_Agent_1
continue_update_1:
    clrf    agent_1_cnt, A  
    goto    End_Update_1
End_Update_1:
    return
    
End_Agent_1:
    movlw   0
    movwf   agent_1_type, A
    movlw   1
    call    remove_active_flag
    return
    

Agent_2_init:
    clrf    agent_2_type, A
    clrf    agent_2_y, A
    clrf    agent_2_bird_h, A
    clrf    agent_2_cnt, A 
    clrf    agent_2_bird_1_2, A
    
    movlw   2
    call    update_active_flag
    
    call    Update_Agent_Freq
    
    movf    obstacle_type_tmp, W, A
    movwf   agent_2_type, A
    movwf   used_rng_ob, A
    
    movlw   4
    cpfseq  agent_2_type, A
    goto    _continue_init_2
    call    Get_Random_Height
    movwf   agent_2_bird_h, A
    movwf   used_rng_bird, A
    
_continue_init_2:
    movlw   138
    movwf   agent_2_y, A
    return
 
Render_Agent_2:
    movf    agent_2_y, W, A
    movwf   y_coord, A
    movf    agent_2_bird_1_2, W, A
    movwf   bird_1_2, A
    movf    agent_2_bird_h, W, A
    movwf   bird_h, A
    movf    agent_2_type, W, A
    call    Get_Render_Sprite
    return

Update_Agent_2:
    incf    agent_2_cnt, F, A
    
    movlw   Agent_Freq                   
    cpfseq  agent_2_cnt, A            
    goto    End_Update_2
    
    movf    agent_2_y, W, A
    movwf   y_coord, A
    movf    agent_2_bird_1_2, W, A
    movwf   bird_1_2, A
    movf    agent_2_bird_h, W, A
    movwf   bird_h, A
    movf    agent_2_type, W, A
    call    Clear_Render_Sprite
    
    movlw   1
    xorwf   agent_2_bird_1_2, F, A
    
    movlw   8
    movwf   tmp, A

dec_Loop_agent_2:
    decf    agent_2_y, F, A
    decfsz  tmp, F, A
    goto    dec_Loop_agent_2
    
    movlw   8
    cpfslt  agent_2_y, A
    goto    continue_update_2
    goto    End_Agent_2
    
continue_update_2:
    clrf    agent_2_cnt, A  
    goto    End_Update_2
End_Update_2:
    return
    
End_Agent_2:
    movlw   0
    movwf   agent_2_type, A
    movlw   2
    call    remove_active_flag
    return
    
; 1 -> L, 2 -> M, 3 -> S, 4 -> B
Get_Render_Sprite:
    movwf   render_type_tmp, A
    movlw   1
    cpfseq  render_type_tmp, A
    goto    _check_type_2
    goto    Render_Large_Cactus

_check_type_2:    
    movlw   2
    cpfseq  render_type_tmp, A
    goto    _check_type_3
    goto    Render_Medium_Cactus

_check_type_3:    
    movlw   3
    cpfseq  render_type_tmp, A
    goto    _check_type_4
    goto    Render_Small_Cactus

_check_type_4:
    movlw   4
    cpfseq  render_type_tmp, A
    goto    _end_render_sprite
    goto    Render_Bird
   
_end_render_sprite:
    return
 
Render_Large_Cactus:
    movlw   5
    movwf   page_coord, A         
    call    GLCD_Render_Cactus_Large
    return

Render_Medium_Cactus:
    movlw   5
    movwf   page_coord, A         
    call    GLCD_Render_Cactus_Medium
    return

Render_Small_Cactus:
    movlw   6
    movwf   page_coord, A         
    call    GLCD_Render_Cactus_Small
    return

Render_Bird:
    movf    bird_h, W, A
    movwf   page_coord, A

    movlw   0                    
    cpfseq  bird_1_2, A           
    goto    Use_BIRD2
Use_BIRD1:
    call    GLCD_Render_Bird1
    goto    End_Render_Bird
Use_BIRD2:
    call    GLCD_Render_Bird2
    goto    End_Render_Bird
End_Render_Bird:
    return

    
Clear_Render_Sprite:
    movwf   render_type_tmp, A   ; store type

    movlw   1
    cpfseq  render_type_tmp, A
    goto    _clr_check_type_2
    goto    Clear_Large_Cactus

_clr_check_type_2:
    movlw   2
    cpfseq  render_type_tmp, A
    goto    _clr_check_type_3
    goto    Clear_Medium_Cactus

_clr_check_type_3:
    movlw   3
    cpfseq  render_type_tmp, A
    goto    _clr_check_type_4
    goto    Clear_Small_Cactus

_clr_check_type_4:
    movlw   4
    cpfseq  render_type_tmp, A
    goto    _clr_end
    goto    Clear_Bird

_clr_end:
    return
    
Clear_Large_Cactus:
    movlw   5
    movwf   page_coord, A         
    call    GLCD_Clear_Cactus_Large
    return

Clear_Medium_Cactus:
    movlw   5
    movwf   page_coord, A         
    call    GLCD_Clear_Cactus_Medium
    return

Clear_Small_Cactus:
    movlw   6
    movwf   page_coord, A         
    call    GLCD_Clear_Cactus_Small
    return

Clear_Bird:
    movf    bird_h, W, A
    movwf   page_coord, A

    movlw   0                    
    cpfseq  bird_1_2, A           
    goto    _clr_BIRD2
_clr_BIRD1:
    call    GLCD_Clear_Bird1
    goto    End_Clear_Bird
_clr_BIRD2:
    call    GLCD_Clear_Bird2
    goto    End_Clear_Bird
End_Clear_Bird:
    return
    
update_active_flag:
    movwf   tmp, A
    movlw   0
    cpfseq  active_agent_flag, A
    bra	    _update_two
    bra	    _update_tmp
_update_tmp:
    movf    tmp, W, A
    movwf   active_agent_flag, A
    return
_update_two:
    movlw   3
    movwf   active_agent_flag, A
    return

remove_active_flag:
    subwf   active_agent_flag, W, A                      ; WREG = active_agent_flag - tmp
    movwf   active_agent_flag, A           ; store result
    return
 
    
Update_Agent_Freq:
    incf    Freq_Update_cnt, F, A 
    
    movlw   2                  
    cpfseq  Freq_Update_cnt, A
    goto    _End_Update_Freq 
    
    movlw   2
    cpfseq  Agent_Freq, A
    goto    _Update_Freq
    goto    _End_Update_Freq
 
_Update_Freq:
    decf    Agent_Freq, A
    clrf    Freq_Update_cnt, A
_End_Update_Freq:
    return
    
Display_Agent_Freq:
    call    GLCD_Render_Speed
    call    Display_Speed
    return
    
    
Get_Agent_1_type:
    movf    agent_1_type, W, A
    return

Get_Agent_2_type:
    movf    agent_2_type, W, A
    return

end
    
    


