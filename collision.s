#include <xc.inc>

; Export symbols
global Check_Collision, Is_Game_Over, Reset_Game_Over, Init_Collision
    
; Import symbols
extrn page_coord, y_coord, DINO_y, DINO_page, DINO_STATE
extrn agent_1_type, agent_1_y, agent_1_bird_h
extrn agent_2_type, agent_2_y, agent_2_bird_h

; Constants for hitbox sizes
#define DINO_WIDTH 10      ; Width of dinosaur hitbox
#define DINO_HEIGHT 16     ; Height of dinosaur hitbox
#define DUCK_HEIGHT 12     ; Height of dinosaur while ducking
#define CACTUS_WIDTH 10    ; Width of cactus hitbox
#define CACTUS_HEIGHT 20   ; Height of cactus hitbox
#define CACTUS_M_WIDTH 15    ; Width of cactus hitbox
#define CACTUS_M_HEIGHT 20   ; Height of cactus hitbox
#define CACTUS_S_WIDTH 20    ; Width of cactus hitbox
#define CACTUS_S_HEIGHT 14   ; Height of cactus hitbox
#define BIRD_WIDTH 18      ; Width of bird hitbox
#define BIRD_HEIGHT 14     ; Height of bird hitbox

; Game state variables
psect udata_acs
game_over_flag:    ds 1    ; Flag to indicate game over state
temp1:             ds 1    ; Temporary variables for calculations
temp2:             ds 1
dino_right:        ds 1    ; Rightmost edge of dino
dino_bottom:       ds 1    ; Bottom edge of dino
obstacle_left:     ds 1    ; Leftmost edge of obstacle
obstacle_right:    ds 1    ; Rightmost edge of obstacle
obstacle_top:      ds 1    ; Top edge of obstacle
obstacle_bottom:   ds 1    ; Bottom edge of obstacle

psect collision_code,class=CODE

; Initialize collision detection
Init_Collision:
    clrf    game_over_flag, A     ; Clear game over flag
    return

; Check if game is over
Is_Game_Over:
    movf    game_over_flag, W, A
    return

; Reset game over state
Reset_Game_Over:
    clrf    game_over_flag, A
    return

; Main collision detection function
Check_Collision:
    ; Check collision with agent 1 if active
    movf    agent_1_type, W, A
    movwf   temp1, A
    movlw   0
    cpfseq  temp1, A              ; Skip if agent_1_type == 0 (inactive)
    call    Check_Agent_1_Collision
    
    ; If collision detected, return
    movf    game_over_flag, W, A
    movlw   0
    cpfseq  WREG, A
    return
    
    ; Check collision with agent 2 if active
    movf    agent_2_type, W, A
    movwf   temp1, A
    movlw   0
    cpfseq  temp1, A              ; Skip if agent_2_type == 0 (inactive)
    call    Check_Agent_2_Collision
    
    return

; Check collision with agent 1
Check_Agent_1_Collision:
    ; Calculate dinosaur hitbox
    call    Calculate_Dino_Hitbox
    
    ; Calculate obstacle hitbox
    movf    agent_1_type, W, A
    movf    agent_1_y, W, A
    movwf   obstacle_left, A
    
    ; Choose hitbox based on obstacle type
    movlw   4                     ; Bird type
    cpfseq  agent_1_type, A
    goto    Agent1_hitbox_check_2
    goto    Agent1_Bird_Hitbox
    
Agent1_hitbox_check_2:
    movlw   3
    cpfseq  agent_1_type, A
    goto    Agent1_hitbox_check_3
    goto    Agent1_Cactus_S_Hitbox

Agent1_hitbox_check_3:
    movlw   2
    cpfseq  agent_1_type, A
    goto    Agent1_Cactus_Hitbox
    goto    Agent1_Cactus_M_Hitbox

Agent1_Cactus_M_Hitbox:
    movf    agent_1_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   CACTUS_M_WIDTH
    movwf   obstacle_right, A
    
    ; Cactus is always on the ground (page 5-7)
    movlw   5
    movwf   obstacle_top, A
    movlw   7
    movwf   obstacle_bottom, A
    
    goto    Agent1_Check_Overlap
 
Agent1_Cactus_S_Hitbox:
    movf    agent_1_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   CACTUS_S_WIDTH
    movwf   obstacle_right, A
    
    ; Cactus is always on the ground (page 6-7)
    movlw   6
    movwf   obstacle_top, A
    movlw   7
    movwf   obstacle_bottom, A
    
    goto    Agent1_Check_Overlap
    
Agent1_Cactus_Hitbox:
    ; Cactus hitbox
    movf    agent_1_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   CACTUS_WIDTH
    movwf   obstacle_right, A
    
    ; Cactus is always on the ground (page 5-7)
    movlw   5
    movwf   obstacle_top, A
    movlw   7
    movwf   obstacle_bottom, A
    
    goto    Agent1_Check_Overlap
    
Agent1_Bird_Hitbox:
    ; Bird hitbox
    movf    agent_1_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   BIRD_WIDTH
    movwf   obstacle_right, A
    
    ; Use bird height from object
    movf    agent_1_bird_h, W, A
    movwf   obstacle_top, A
    
    ; Calculate bottom edge
    movf    obstacle_top, W, A
    addlw   2                     ; Bird height in pages
    movwf   obstacle_bottom, A
    
Agent1_Check_Overlap:
    call    Check_Overlap
    return

; Check collision with agent 2
Check_Agent_2_Collision:
    ; Calculate dinosaur hitbox
    call    Calculate_Dino_Hitbox
    
    ; Calculate obstacle hitbox
    movf    agent_2_type, W, A
    movf    agent_2_y, W, A
    movwf   obstacle_left, A
    
    ; Choose hitbox based on obstacle type
    movlw   4                     ; Bird type
    cpfseq  agent_2_type, A
    goto    Agent2_hitbox_check_2
    goto    Agent2_Bird_Hitbox

Agent2_hitbox_check_2:
    movlw   3
    cpfseq  agent_2_type, A
    goto    Agent2_hitbox_check_3
    goto    Agent2_Cactus_S_Hitbox

Agent2_hitbox_check_3:
    movlw   2
    cpfseq  agent_2_type, A
    goto    Agent2_Cactus_Hitbox
    goto    Agent2_Cactus_M_Hitbox

Agent2_Cactus_M_Hitbox:
    movf    agent_2_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   CACTUS_M_WIDTH
    movwf   obstacle_right, A
    
    ; Cactus is always on the ground (page 5-7)
    movlw   5
    movwf   obstacle_top, A
    movlw   7
    movwf   obstacle_bottom, A
    
    goto    Agent2_Check_Overlap
 
Agent2_Cactus_S_Hitbox:
    movf    agent_2_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   CACTUS_S_WIDTH
    movwf   obstacle_right, A
    
    ; Cactus is always on the ground (page 6-7)
    movlw   6
    movwf   obstacle_top, A
    movlw   7
    movwf   obstacle_bottom, A
    
    goto    Agent2_Check_Overlap
    
Agent2_Cactus_Hitbox:
    ; Cactus hitbox
    movf    agent_2_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   CACTUS_WIDTH
    movwf   obstacle_right, A
    
    ; Cactus is always on the ground (page 5-7)
    movlw   5
    movwf   obstacle_top, A
    movlw   7
    movwf   obstacle_bottom, A
    
    goto    Agent2_Check_Overlap
    
Agent2_Bird_Hitbox:
    ; Bird hitbox
    movf    agent_2_y, W, A
    movwf   obstacle_left, A
    
    ; Calculate right edge
    movf    obstacle_left, W, A
    addlw   BIRD_WIDTH
    movwf   obstacle_right, A
    
    ; Use bird height from object
    movf    agent_2_bird_h, W, A
    movwf   obstacle_top, A
    
    ; Calculate bottom edge
    movf    obstacle_top, W, A
    addlw   2                     ; Bird height in pages
    movwf   obstacle_bottom, A
    
Agent2_Check_Overlap:
    call    Check_Overlap
    return

; Calculate dinosaur hitbox based on current state
Calculate_Dino_Hitbox:
    ; Left edge of dino is fixed at DINO_y
    movf    DINO_y, W, A
    movwf   temp1, A
    
    ; Calculate right edge
    movf    temp1, W, A
    addlw   DINO_WIDTH
    movwf   dino_right, A
    
    ; Top edge is at current page
    movf    DINO_page, W, A
    movwf   temp2, A
    
    ; Calculate bottom edge based on state (ducking or not)
    movlw   3
    cpfseq  DINO_STATE, A         ; Check if ducking (state 3)
    goto    Dino_Standing_Height
    goto    Dino_Ducking_Height
    
Dino_Standing_Height:
    ; Regular height - add 2 pages
    movf    temp2, W, A
    addlw   2                    ; Standing dino height in pages
    movwf   dino_bottom, A
    return
    
Dino_Ducking_Height:
    ; Reduced height for ducking - add 1 page
    movf    temp2, W, A
    addlw   1                    ; Ducking dino height in pages
    movwf   dino_bottom, A
    return

; Check for overlap between dinosaur and obstacle hitboxes
Check_Overlap:
    ; No collision if dino right < obstacle left
    movf    dino_right, W, A
    subwf   obstacle_left, W, A   ; obstacle_left - dino_right
    btfsc   STATUS, 0, A          ; Skip if carry clear (dino_right >= obstacle_left)
    return
    
    ; No collision if dino left > obstacle right
    movf    DINO_y, W, A
    subwf   obstacle_right, W, A  ; obstacle_right - DINO_y
    btfss   STATUS, 0, A          ; Skip if carry set (DINO_y <= obstacle_right)
    return
    
    ; No collision if dino bottom < obstacle top
    movf    dino_bottom, W, A
    subwf   obstacle_top, W, A    ; obstacle_top - dino_bottom
    btfsc   STATUS, 0, A          ; Skip if carry clear (dino_bottom >= obstacle_top)
    return
    
    ; No collision if dino top > obstacle bottom
    movf    DINO_page, W, A
    subwf   obstacle_bottom, W, A ; obstacle_bottom - DINO_page
    btfss   STATUS, 0, A          ; Skip if carry set (DINO_page <= obstacle_bottom)
    return
    
    ; If we got here, collision detected!
    movlw   1
    movwf   game_over_flag, A
    
    return