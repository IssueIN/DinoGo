;===============================================================================
; ML Inference for Dino Runner Game
;===============================================================================
; This file implements the ML inference routine for the Dino Runner game.
; It takes the current game state as input and outputs an action (duck, idle, jump).
;
; Input:
; - 4 state variables stored in memory (obstacle_distance, obstacle_height, 
;   dino_vertical_pos, game_speed)
;
; Output:
; - WREG = action code: 0 (duck), 1 (idle), or 2 (jump)
;
; Architectural Overview:
; - 4 inputs
; - 6 hidden neurons
; - 3 outputs
;
; Fixed-Point Format:
; - 8-bit signed integers
; - Simple fixed-point math with appropriate scaling
;===============================================================================

#include <xc.inc>

extrn	ML_Inference
extrn	Get_Agent_1_type, Get_Agent_2_type
;extrn	DINO_page
extrn	Agent_Freq, active_agent_flag
extrn	agent_1_y, agent_2_y, agent_1_bird_h, agent_2_bird_h
    
global	Prepare_State_Vector
global	obstacle_distance, obstacle_height, game_speed
    
psect   udata_acs
 ; Game state vector for ML inference
obstacle_distance:  ds 1    ; Distance to nearest obstacle
obstacle_height:    ds 1    ; Height of the obstacle (page number)
;dino_vertical_pos:  ds 1    ; Current dinosaur vertical position
game_speed:         ds 1    ; Current game speed
tmp:		    ds 1

psect   mlhandler_code,class=CODE
    

Prepare_State_Vector:
     ; Get distance to nearest obstacle
     call    Get_Nearest_Obstacle_Distance
     movwf   obstacle_distance, A
     
     ; Get height of obstacle
     call    Get_Nearest_Obstacle_Height
     movwf   obstacle_height, A
     
;     ; Set dinosaur vertical position
;     movf    DINO_page, W, A
;     movwf   dino_vertical_pos, A
     
     ; Get current game speed (from spawn.s current_agent_freq)
     ; For now, just use a simple value based on score
;     movf    Agent_Freq, W, A
;     movwf   game_speed, A
;     sublw   21
;     movwf   game_speed, A
;     
     return
 
 ; Function to find nearest obstacle distance
Get_Nearest_Obstacle_Distance:
     ; Check if agent_1 is active
    movf    active_agent_flag, W, A
    movlw   0
    cpfseq  active_agent_flag, A
    goto    check_nearest_ob_2 
    goto    no_active
check_nearest_ob_2:
    movlw   1
    cpfseq  active_agent_flag, A
    goto    check_nearest_ob_3
    goto    Use_Agent_1_Distance
check_nearest_ob_3:
    movlw   2
    cpfseq  active_agent_flag, A
    goto    check_nearest_ob_4
    goto    Use_Agent_2_Distance
check_nearest_ob_4:
    movf    agent_1_y, W, A
    cpfslt  agent_2_y, A
    goto    Use_Agent_1_Distance
    goto    Use_Agent_2_Distance
     
no_active:
     ; No active obstacles, return a large distance
    movlw   128
    return
     
Use_Agent_1_Distance:
     ; Access agent_1_y from spawn.s (external variable)
     ; For this prototype, we'll just use a simple approximation
     ; Return a value representing distance (0-127)
    movf   agent_1_y, W, A                  ; Placeholder value
    return
     
Use_Agent_2_Distance:
     ; Access agent_2_y from spawn.s (external variable)
    movf   agent_2_y, W, A                   ; Placeholder value
    return
 
 ; Function to get obstacle height
Get_Nearest_Obstacle_Height:
     ; Determine which obstacle is nearest and get its type
     ; Check if agent_1 is active
    movf    active_agent_flag, W, A
    movlw   0
    cpfseq  active_agent_flag, A
    goto    check_nearest_h_2 
    goto    no_active_h
check_nearest_h_2:
    movlw   1
    cpfseq  active_agent_flag, A
    goto    check_nearest_h_3
    goto    Use_Agent_1_Height
check_nearest_h_3:
    movlw   2
    cpfseq  active_agent_flag, A
    goto    check_nearest_h_4
    goto    Use_Agent_2_Height
check_nearest_h_4:
    movf    agent_1_y, W, A
    cpfslt  agent_2_y, A
    goto    Use_Agent_1_Height
    goto    Use_Agent_2_Height
no_active_h:
    movlw   0
    return
     
Use_Agent_1_Height:
     ; Based on agent_1_type, determine height
     ; 1=large cactus (3 pages), 2=medium cactus (3 pages), 
     ; 3=small cactus (2 pages), 4=bird (depends on agent_1_bird_h)
                  ; Default height (placeholder)
    call    Get_Agent_1_type
    movwf   tmp, A
    movlw   4
    cpfseq  tmp, A
    goto    check_1_h_2
    goto    use_agent_1_bird
check_1_h_2:
    movlw   3
    cpfseq  tmp, A
    goto    use_cactus
    goto    use_cactus_small
use_agent_1_bird:
    movf   agent_1_bird_h, W, A
    return

     
Use_Agent_2_Height:
     ; Based on agent_2_type, determine height
    call    Get_Agent_2_type
    movwf   tmp, A
    movlw   4
    cpfseq  tmp, A
    goto    check_2_h_2
    goto    use_agent_2_bird
check_2_h_2:
    movlw   3
    cpfseq  tmp, A
    goto    use_cactus
    goto    use_cactus_small
use_agent_2_bird:
    movf    agent_2_bird_h, W, A
    return
 
use_cactus:
    movlw   5
    return
use_cactus_small:
    movlw   6
    return

