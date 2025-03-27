;===============================================================================
; ML Inference for Dino Runner Game - Quantized Model
;===============================================================================
; This file implements the ML inference routine for the Dino Runner game.
; It takes the current game state as input and outputs an action (duck, idle, jump).
;
; Input:
; - 3 state variables: obstacle_distance, obstacle_height, game_speed
;
; Output:
; - WREG = action code: 0 (duck), 1 (idle), or 2 (jump)
;
; Architectural Overview:
; - 3 inputs (normalized)
; - 8 hidden neurons with ReLU activation
; - 3 outputs
;
; Fixed-Point Format:
; - Q8.8 format (8 bits integer, 8 bits fractional)
; - Range: -128.0 to 127.99609375
; - Resolution: 1/256 ? 0.00390625
;===============================================================================
 
#include <xc.inc>

; External references for the ML parameters
extrn  fc1_weight, fc1_bias, fc2_weight, fc2_bias, scales

; External references for game state variables 
extrn	norm_distance, norm_height, norm_speed

; Global declaration for the inference function
GLOBAL  ML_Inference

; Memory allocation in Access RAM for intermediate results
psect   udata_acs_ovr

; Output from hidden layer (8 neurons)
hidden_out0:    ds 1
hidden_out1:    ds 1
hidden_out2:    ds 1
hidden_out3:    ds 1
hidden_out4:    ds 1
hidden_out5:    ds 1
hidden_out6:    ds 1
hidden_out7:    ds 1

; Output layer (3 neurons)
output_out0:    ds 1    ; Action: Duck
output_out1:    ds 1    ; Action: Idle
output_out2:    ds 1    ; Action: Jump

; Temporary variables
temp_w:         ds 1    ; Temporary weight value
temp_neuron:    ds 1    ; Temporary neuron output
counter_i:      ds 1    ; Loop counter for inputs
counter_h:      ds 1    ; Loop counter for hidden neurons
counter_o:      ds 1    ; Loop counter for output neurons
addr_ptr:       ds 2    ; Address pointer (low, high)
weight_idx:     ds 1    ; Weight matrix index
input_offset:   ds 1    ; Input offset calculator

psect   ml_code,class=CODE

;-------------------------------------------------------------------------------
; Normalize_Game_State - Convert raw game state to normalized inputs
;-------------------------------------------------------------------------------
Normalize_Game_State:
    ; In this implementation, we'll do a basic linear scaling
    ; from raw values to normalized values suitable for ML input
    
    ; Normalize obstacle distance (0-255 ? -128 to 127)
    ; For simplicity, we'll just use the raw value
    movf    norm_distance, W, A    
    ; Normalize obstacle height (0-7 ? -128 to 127)
    ; Scale by multiplying by ~25 to use more of the input range
    movf    norm_height, W, A
    mullw   25
    movf    PRODL, W, A
    movwf   norm_height, A
    
    ; Normalize game speed (0-255 ? -128 to 127)
    ; For simplicity, we'll just use the raw value
    movf    norm_speed, W, A
    
    return
    
;-------------------------------------------------------------------------------
; ML_Inference - Main entry point for ML inference
;-------------------------------------------------------------------------------
ML_Inference:
    ; Save any incoming value
    movwf   temp_w, A
    
    ; Step 0: Normalize the input state
    call    Normalize_Game_State
    
    ;---------------------------------------------------------------------------
    ; Step 1: Load biases into hidden neurons
    ;---------------------------------------------------------------------------
    
    ; Set up FSR0 to point to the hidden layer outputs
    movlw   LOW(hidden_out0)
    movwf   FSR0L, A
    movlw   HIGH(hidden_out0)
    movwf   FSR0H, A
    
    ; Set up FSR1 to point to the hidden layer biases
    movlw   LOW(fc1_bias)
    movwf   FSR1L, A
    movlw   HIGH(fc1_bias)
    movwf   FSR1H, A
    
    ; Initialize counter for hidden neurons
    movlw   8                 ; 8 hidden neurons
    movwf   counter_h, A
    
Hidden_Bias_Loop:
    ; Load bias into the current hidden neuron output
    movf    POSTINC1, W, A    ; Get bias and increment FSR1
    movwf   POSTINC0, A       ; Store to hidden_outX and increment FSR0
    
    decfsz  counter_h, F, A   ; Decrement counter, skip if zero
    bra     Hidden_Bias_Loop  ; Loop for all hidden neurons
    
    ;---------------------------------------------------------------------------
    ; Step 2: Process all inputs for each hidden neuron
    ;---------------------------------------------------------------------------
    
    ; Reset FSR0 to the beginning of hidden outputs
    movlw   LOW(hidden_out0)
    movwf   FSR0L, A
    movlw   HIGH(hidden_out0)
    movwf   FSR0H, A
    
    ; Process each of the 8 hidden neurons
    movlw   8
    movwf   counter_h, A
    
Hidden_Neuron_Loop:
    ; For each hidden neuron, we'll process all 3 inputs
    movlw   LOW(norm_distance) ; Point to our normalized inputs
    movwf   FSR1L, A
    movlw   HIGH(norm_distance)
    movwf   FSR1H, A
    
    ; Calculate weight matrix index for current hidden neuron
    ; For hidden neuron h, we need weights at:
    ; Input 0: fc1_weight + h
    ; Input 1: fc1_weight + 8 + h
    ; Input 2: fc1_weight + 16 + h
    
    ; First, save which hidden neuron we're processing (0-7)
    movlw   8
    subwf   counter_h, W, A   ; W = 8 - counter_h (gives 0-7 index)
    movwf   weight_idx, A     ; Save index
    
    ; Process each of the 3 inputs
    movlw   3
    movwf   counter_i, A
    
    ; Initialize input offset at 0
    movlw   0
    movwf   input_offset, A
    
Input_Loop:
    ; Get weight for this input-hidden connection
    ; Position = fc1_weight + (input_offset * 8) + weight_idx
    
    ; Calculate position in weight matrix
    movlw   LOW(fc1_weight)
    movwf   FSR2L, A
    movlw   HIGH(fc1_weight)
    movwf   FSR2H, A
    
    ; Add input offset (0, 8, or 16)
    movf    input_offset, W, A
    addwf   FSR2L, F, A
    
    ; Add hidden neuron index (0-7)
    movf    weight_idx, W, A
    addwf   FSR2L, F, A
    
    ; Get the weight
    movf    INDF2, W, A       ; Get weight
    movwf   temp_w, A         ; Store for multiplication
    
    ; Get input value
    movf    POSTINC1, W, A    ; Get input and increment FSR1
    
    ; Multiply input by weight
    mulwf   temp_w, A         ; input * weight -> PRODH:PRODL
    
    ; Add product to hidden neuron activation
    movf    PRODL, W, A       ; Get low byte of product
    addwf   INDF0, F, A       ; Add to hidden neuron output
    
    ; Update input offset for next input (add 8 each time)
    movlw   8
    addwf   input_offset, F, A
    
    ; Move to next input
    decfsz  counter_i, F, A   ; Decrement input counter
    bra     Input_Loop        ; Loop for next input
    
    ; Apply ReLU activation: max(0, x)
    btfsc   INDF0, 7, A       ; Check if negative (bit 7 set)
    clrf    INDF0, A          ; If negative, set to 0
    
    ; Move to next hidden neuron
    incf    FSR0L, F, A       ; Increment FSR0 to next hidden neuron
    
    decfsz  counter_h, F, A   ; Decrement hidden neuron counter
    bra     Hidden_Neuron_Loop ; Process next hidden neuron
    
    ;---------------------------------------------------------------------------
    ; Step 3: Load biases into output neurons
    ;---------------------------------------------------------------------------
    
    ; Set up FSR0 to point to the output layer
    movlw   LOW(output_out0)
    movwf   FSR0L, A
    movlw   HIGH(output_out0)
    movwf   FSR0H, A
    
    ; Set up FSR1 to point to the output biases
    movlw   LOW(fc2_bias)
    movwf   FSR1L, A
    movlw   HIGH(fc2_bias)
    movwf   FSR1H, A
    
    ; Initialize counter for output neurons
    movlw   3
    movwf   counter_o, A
    
Output_Bias_Loop:
    ; Load bias into the current output neuron
    movf    POSTINC1, W, A     ; Load bias and increment FSR1
    movwf   POSTINC0, A        ; Store to output_outX and increment FSR0
    
    decfsz  counter_o, F, A    ; Decrement counter, skip if zero
    bra     Output_Bias_Loop   ; Loop for all output neurons
    
    ;---------------------------------------------------------------------------
    ; Step 4: Process all hidden neurons for each output neuron
    ;---------------------------------------------------------------------------
    
    ; Reset FSR0 to the beginning of output neurons
    movlw   LOW(output_out0)
    movwf   FSR0L, A
    movlw   HIGH(output_out0)
    movwf   FSR0H, A
    
    ; Process each of the 3 output neurons
    movlw   3
    movwf   counter_o, A
    
Output_Neuron_Loop:
    ; For each output neuron, process all 8 hidden neurons
    movlw   LOW(hidden_out0)
    movwf   FSR1L, A
    movlw   HIGH(hidden_out0)
    movwf   FSR1H, A
    
    ; Calculate weight matrix index for current output neuron
    ; For output neuron o, we need weights at:
    ; Hidden 0: fc2_weight + (o*8) + 0
    ; Hidden 1: fc2_weight + (o*8) + 1
    ; etc.
    
    ; First, determine output index (0-2)
    movlw   3
    subwf   counter_o, W, A   ; W = 3 - counter_o (gives 0-2 index)
    
    ; Multiply by 8 to get row offset
    movwf   temp_w, A
    bcf     STATUS, 0, A      ; Clear carry
    rlcf    temp_w, F, A      ; Rotate left (x2)
    rlcf    temp_w, F, A      ; Rotate left (x4)
    rlcf    temp_w, F, A      ; Rotate left (x8)
    
    ; Save base offset for this output neuron
    movf    temp_w, W, A
    movwf   input_offset, A   ; Reusing input_offset variable
    
    ; Process each of the 8 hidden neurons
    movlw   8
    movwf   counter_h, A
    
Hidden_To_Output_Loop:
    ; Calculate position in fc2_weight matrix
    movlw   LOW(fc2_weight)
    movwf   FSR2L, A
    movlw   HIGH(fc2_weight)
    movwf   FSR2H, A
    
    ; Add output row offset
    movf    input_offset, W, A
    addwf   FSR2L, F, A
    
    ; Add column offset (which hidden neuron)
    movlw   8
    subwf   counter_h, W, A   ; W = 8 - counter_h (0-7 index)
    addwf   FSR2L, F, A
    
    ; Get the weight
    movf    INDF2, W, A       ; Get weight
    movwf   temp_w, A         ; Store weight
    
    ; Get hidden neuron output
    movf    POSTINC1, W, A    ; Get hidden output and move to next
    
    ; Multiply hidden output by weight
    mulwf   temp_w, A         ; hidden_out * weight -> PRODH:PRODL
    
    ; Add product to output neuron activation
    movf    PRODL, W, A       ; Get low byte of product
    addwf   INDF0, F, A       ; Add to output neuron
    
    decfsz  counter_h, F, A   ; Decrement hidden neuron counter
    bra     Hidden_To_Output_Loop ; Process next hidden neuron
    
    ; Move to next output neuron
    incf    FSR0L, F, A       ; Move to next output neuron
    
    decfsz  counter_o, F, A   ; Decrement output neuron counter
    bra     Output_Neuron_Loop ; Process next output neuron
    
    ;---------------------------------------------------------------------------
    ; Step 5: Find the maximum output (ArgMax) to determine the action
    ;---------------------------------------------------------------------------
    
    ; Load the three output values
    movlw   LOW(output_out0)
    movwf   FSR0L, A
    movlw   HIGH(output_out0)
    movwf   FSR0H, A
    
    ; Compare output_out0 (duck) and output_out1 (idle)
    movf    POSTINC0, W, A     ; Get output_out0, increment to output_out1
    subwf   INDF0, W, A        ; output_out1 - output_out0
    
    ; If output_out1 <= output_out0, check output_out2
    bn      Check_Output2      ; If output_out1 > output_out0 (result negative), branch
    
    ; If here, output_out0 >= output_out1
    movf    POSTINC0, W, A     ; Get output_out1, increment to output_out2
    subwf   INDF0, W, A        ; output_out2 - output_out1
    
    ; If output_out2 <= output_out1, action is output_out0 (duck)
    bn      Return_Duck        ; If output_out2 > output_out1, branch
    
    ; If here, action is output_out2 (jump)
    movlw   1                  ; Action: Jump
    bra     Return_Action
    
Check_Output2:
    ; If here, output_out1 > output_out0
    movf    POSTINC0, W, A     ; Get output_out1, increment to output_out2
    subwf   INDF0, W, A        ; output_out2 - output_out1
    
    ; If output_out2 <= output_out1, action is output_out1 (idle)
    bn      Return_Idle        ; If output_out2 > output_out1, branch
    
    ; If here, action is output_out2 (jump)
    movlw   1                  ; Action: Jump
    bra     Return_Action
    
Return_Duck:
    movlw   3                  ; Action: Duck
    bra     Return_Action
    
Return_Idle:
    movlw   0                  ; Action: Idle
    bra     Return_Action
    
Return_Action:
    ; Return the action in WREG
    return    
    
END                            ; End of module