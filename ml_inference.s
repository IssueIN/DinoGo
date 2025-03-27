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
extrn  fc1_weight
extrn  fc1_bias
extrn  fc2_weight
extrn  fc2_bias
extrn  scales
extrn  obstacle_distance, obstacle_height, game_speed

; Global declaration for the inference function
GLOBAL  ML_Inference, Normalize_Game_State

; Memory allocation in Access RAM for state vector and intermediate results
psect   udata_acs_ovr
; Input state vector (normalized)
norm_distance:    ds 1    ; normalized obstacle distance
norm_height:      ds 1    ; normalized obstacle height
norm_speed:       ds 1    ; normalized game speed

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

psect   ml_code,class=CODE

;-------------------------------------------------------------------------------
; Normalize_Game_State - Convert raw game state to normalized inputs
;-------------------------------------------------------------------------------
Normalize_Game_State:
    ; In this simple implementation, we'll do a basic linear scaling
    ; from raw values to normalized values (-1 to 1 range, represented as signed 8-bit)
    
    ; Normalize obstacle distance (0-255 ? -128 to 127)
    ; For simplicity, we'll just use the raw value shifted
    movf    obstacle_distance, W, A
    movwf   norm_distance, A
    
    ; Normalize obstacle height (0-7 ? -128 to 127)
    ; Scale by multiplying by ~25
    movf    obstacle_height, W, A
    mullw   25
    movf    PRODL, W, A
    movwf   norm_height, A
    
    ; Normalize game speed (0-255 ? -128 to 127)
    ; For simplicity, we'll just use the raw value shifted
    movf    game_speed, W, A
    movwf   norm_speed, A
    
    return
    
;-------------------------------------------------------------------------------
; ML_Inference - Main entry point for ML inference
;-------------------------------------------------------------------------------
ML_Inference:
    ; Save working registers that we'll use
    movwf   temp_w, A          ; Save any incoming value in WREG
    
    ; Step 0: Normalize the input state
    call    Normalize_Game_State
    
    ;---------------------------------------------------------------------------
    ; Step 1: Compute hidden layer outputs (8 neurons)
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
    movlw   8           ; 8 hidden neurons in new model
    movwf   counter_h, A
    
Hidden_Loop:
    ; Load bias into the current hidden neuron output
    movf    POSTINC1, W, A     ; Load bias and increment FSR1
    movwf   POSTINC0, A        ; Store to hidden_outX and increment FSR0
    
    decfsz  counter_h, F, A    ; Decrement counter, skip if zero
    bra     Hidden_Loop        ; Loop for all hidden neurons
    
    ; Reset FSR0 to the beginning of hidden outputs
    movlw   LOW(hidden_out0)
    movwf   FSR0L, A
    movlw   HIGH(hidden_out0)
    movwf   FSR0H, A
    
    ; Set up a loop to process all 8 hidden neurons
    movlw   8
    movwf   counter_h, A
    
    ; Set up FSR1 to point to the weights for input?hidden
    movlw   LOW(fc1_weight)
    movwf   FSR1L, A
    movlw   HIGH(fc1_weight)
    movwf   FSR1H, A
    
Process_Hidden:
    ; Save the current hidden neuron pointer
    movf    FSR0L, W, A
    movwf   addr_ptr, A
    movf    FSR0H, W, A
    movwf   addr_ptr+1, A
    
    ; Process each input for this hidden neuron
    movlw   3                  ; 3 inputs in new model
    movwf   counter_i, A
    
    ; Set up pointer to the normalized inputs
    movlw   LOW(norm_distance)
    movwf   FSR2L, A
    movlw   HIGH(norm_distance)
    movwf   FSR2H, A
    
Process_Input:
    ; Multiply input by weight and add to hidden neuron output
    ; hidden_outi += state_vecj * weight_ij
    movf    POSTINC1, W, A     ; Get weight from fc1_weight and increment
    movwf   temp_w, A          ; Save weight
    
    mulwf   POSTINC2, A        ; Multiply by input and increment FSR2
    
    ; Add the product to the hidden neuron output
    movf    PRODL, W, A        ; Get low byte of product
    addwf   INDF0, F, A        ; Add to hidden neuron output
    
    decfsz  counter_i, F, A    ; Decrement input counter, skip if zero
    bra     Process_Input      ; Process next input
    
    ; Apply ReLU activation function: max(0, x)
    btfsc   INDF0, 7, A        ; Check if negative (bit 7 set)
    clrf    INDF0, A           ; If negative, set to 0
    
    ; Move to next hidden neuron
    incf    FSR0L, F, A        ; Increment FSR0 to next hidden neuron
    
    decfsz  counter_h, F, A    ; Decrement hidden neuron counter, skip if zero
    bra     Process_Hidden     ; Process next hidden neuron
    
    ;---------------------------------------------------------------------------
    ; Step 2: Compute output layer
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
    
    ; Reset FSR0 to the beginning of output neurons
    movlw   LOW(output_out0)
    movwf   FSR0L, A
    movlw   HIGH(output_out0)
    movwf   FSR0H, A
    
    ; Process all hidden neurons for each output neuron
    ; For each output neuron k:
    ;   For each hidden neuron i:
    ;     output_outk += hidden_outi * weight_ki
    
    ; Set up a loop to process all 3 output neurons
    movlw   3
    movwf   counter_o, A
    
Process_Output:
    ; Save the current output neuron pointer
    movf    FSR0L, W, A
    movwf   addr_ptr, A
    movf    FSR0H, W, A
    movwf   addr_ptr+1, A
    
    ; Process each hidden neuron for this output neuron
    movlw   8                  ; 8 hidden neurons in new model
    movwf   counter_h, A
    
    ; Set up FSR2 to point to the hidden layer outputs
    movlw   LOW(hidden_out0)
    movwf   FSR2L, A
    movlw   HIGH(hidden_out0)
    movwf   FSR2H, A
    
    ; Calculate the offset in the weights array based on current output neuron
    ; Offset = output_index (0-2)
    movf    counter_o, W, A    ; Get remaining outputs
    sublw   3                  ; 3 - counter_o
    decf    WREG, W, A         ; (3 - counter_o) - 1 to get output index
    
    ; Set up FSR1 to point to the weights for hidden?output
    ; We need to access the weights in a column-wise manner
    movlw   LOW(fc2_weight)
    movwf   FSR1L, A
    movlw   HIGH(fc2_weight)
    movwf   FSR1H, A
    
    ; Adjust FSR1 based on output index
    addwf   FSR1L, F, A        ; Add offset to FSR1L
    
Process_Hidden_For_Output:
    ; Multiply hidden output by weight and add to output neuron
    ; output_outk += hidden_outi * weight_ki
    movf    INDF1, W, A        ; Get weight
    movwf   temp_w, A          ; Save weight
    
    mulwf   POSTINC2, A        ; Multiply by hidden neuron output and increment FSR2
    
    ; Add the product to the output neuron
    movf    PRODL, W, A        ; Get low byte of product
    addwf   INDF0, F, A        ; Add to output neuron
    
    ; Move to the next weight for this output neuron (skip to next column)
    movlw   3                  ; Each row has 3 weights
    addwf   FSR1L, F, A        ; Jump to next row, same column
    
    decfsz  counter_h, F, A    ; Decrement hidden neuron counter, skip if zero
    bra     Process_Hidden_For_Output    ; Process next hidden neuron
    
    ; No ReLU for output layer (we want to keep negative values for comparison)
    
    ; Move to next output neuron
    incf    FSR0L, F, A        ; Increment FSR0 to next output neuron
    
    decfsz  counter_o, F, A    ; Decrement output neuron counter, skip if zero
    bra     Process_Output     ; Process next output neuron
    
    ;---------------------------------------------------------------------------
    ; Step 3: Find the maximum output (ArgMax) to determine the action
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