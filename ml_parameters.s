;===============================================================================
; ML Parameters for Dino Runner Game - Quantized Model
;===============================================================================
; This file contains the quantized weights and biases for the ML model.
; Generated: 20250326-152927
;
; Architectural Overview:
; - 3 inputs: normalized distance, normalized height, normalized speed
; - 8 hidden neurons with ReLU activation
; - 3 outputs: 0=duck, 1=idle, 2=jump
;
; Parameter Counts:
; - Input?Hidden Weights: 3×8 = 24 parameters
; - Hidden Biases: 8 parameters
; - Hidden?Output Weights: 8×3 = 24 parameters
; - Output Biases: 3 parameters
; - Total: 59 parameters
;
; Fixed-Point Format:
; - Q8.8 format (8 bits integer, 8 bits fractional)
; - Range: -128.0 to 127.99609375
; - Resolution: 1/256 ? 0.00390625
;===============================================================================
#include <xc.inc>
; Global declarations to make these parameters accessible from ml_inference.s
GLOBAL  fc1_weight
GLOBAL  fc1_bias
GLOBAL  fc2_weight
GLOBAL  fc2_bias
GLOBAL  scales

; Reserve space in program memory for parameters
psect   ml_params,class=CODE

;-------------------------------------------------------------------------------
; fc1_weight - Input ? Hidden Layer Weights (3×8 matrix = 24 values)
; Each value is in Q8.8 fixed-point format
;-------------------------------------------------------------------------------
fc1_weight:
    DB 0xfd, 0x12, 0x40, 0xfc, 0x09, 0x0f, 0xff, 0x03
    DB 0xee, 0x0f, 0x08, 0x1b, 0x07, 0xf7, 0x0f, 0x0c
    DB 0x2e, 0x7f, 0xd6, 0x0a, 0x16, 0x18, 0x0f, 0x11

;-------------------------------------------------------------------------------
; fc1_bias - Hidden Layer Biases (8 values)
; Each value is in Q8.8 fixed-point format
;-------------------------------------------------------------------------------
fc1_bias:
    DB 0x71, 0x66, 0xfc, 0x6e, 0x6d, 0xcb, 0x6a, 0x7f

;-------------------------------------------------------------------------------
; fc2_weight - Hidden ? Output Layer Weights (8×3 matrix = 24 values)
; Each value is in Q8.8 fixed-point format
;-------------------------------------------------------------------------------
fc2_weight:
    DB 0xbd, 0xd7, 0x01, 0xd8, 0xe1, 0x7a, 0xb1, 0xda
    DB 0xdb, 0xd4, 0x02, 0xd5, 0xcc, 0x75, 0xb0, 0xd6
    DB 0xce, 0xc9, 0x05, 0xdf, 0xce, 0x7f, 0xb8, 0xdb

;-------------------------------------------------------------------------------
; fc2_bias - Output Layer Biases (3 values)
; Each value is in Q8.8 fixed-point format
;-------------------------------------------------------------------------------
fc2_bias:
    DB 0xa6, 0x81, 0x91

;-------------------------------------------------------------------------------
; scales - Scaling factors for weights and biases (Q8.8 fixed point)
;-------------------------------------------------------------------------------
scales:
    DW 13  ; fc1_weight
    DW 11  ; fc1_bias
    DW 15  ; fc2_weight
    DW 7   ; fc2_bias

END                        ; End of module