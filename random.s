#include <xc.inc>

; Export functions for use in other files
global  Initialize_RNG, Next_RNG, Display_RNG
global  Get_Random_Obstacle, Get_Random_Height
global	Draw_Digit

; Import only what we need from GLCD system
extrn   GLCD_Set_Page, GLCD_Set_CS, GLCD_Data
extrn	GLCD_Render_RNG, GLCD_Render_Slash
extrn	used_rng_ob, used_rng_bird

; Variables in access bank
psect   udata_acs
lfsr_low:       ds 1    ; LFSR low byte
lfsr_high:      ds 1    ; LFSR high byte
rng_counter:    ds 1    ; Frame counter for updates
obstacle_type:  ds 1    ; Current obstacle type (0-4)
bird_height:    ds 1    ; Current bird height (1-6)
temp:           ds 1    ; Temporary calculation storage
digit:          ds 1    ; For digit conversion
offset:         ds 1    ; For calculating digit data offset

;RNG_DISPLAY:    ds 1    ; Toggle for RNG display (0=off, 1=on)
;RNG_DISPLAY_PAGE: ds 1  ; Page number for RNG display
;RNG_DISPLAY_Y:  ds 1    ; Y position for RNG display
;last_obstacle_type:    ds 1    ; Store last generated obstacle type
;last_bird_height:      ds 1    ; Store last generated bird height
; Constants
LFSR_TAPS   EQU 0xB4   ; x^16 + x^14 + x^13 + x^11 + 1 (0xB4 = 10110100b)

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
    
psect   rng_code,class=CODE
    
Initialize_RNG:
    ; Seed LFSR with Timer0 value
    movf    TMR0L, W, A
    movwf   lfsr_low, A
    movf    TMR0H, W, A
    movwf   lfsr_high, A
    
    ; Ensure seed is not zero
    movlw   0x01
    iorwf   lfsr_low, F, A
    
    ; Initialize values
    clrf    rng_counter, A
    clrf    obstacle_type, A
    movlw   1
    movwf   bird_height, A

    return

Next_RNG:
    ; Check LSB
    btfss   lfsr_low, 0, A
    bra     Skip_XOR
    
    ; If LSB was 1, apply XOR with taps
    movlw   LFSR_TAPS    ; Tap bits in hex instead of binary
    xorwf   lfsr_high, F, A
    
Skip_XOR:
    ; Shift right the 16-bit value
    bcf     STATUS, 0, A   ; Clear carry
    rrcf    lfsr_high, F, A
    rrcf    lfsr_low, F, A
    
    ; Generate new obstacle type (0-4)
    call    Generate_Obstacle_Type
    
    ; Generate new bird height (1-6)
    call    Generate_Bird_Height
    
    return

Generate_Obstacle_Type:
    ; Use low byte for obstacle type
    movf    lfsr_low, W, A
    andlw   0x07        ; Get lowest 3 bits (0-7)
    movwf   temp, A     ; Save in temp
    
    ; Reduce to 0-4 range using subtraction
    ; 0 = No obstacle
    ; 1 = Single large cactus (CACTUS_DATA)
    ; 2 = Two medium cacti (CACTUS_DATA)
    ; 3 = Three small cacti (CACTUS_DATA)
    ; 4 = Bird at variable height (CACTUS_DATA)
Mod_5_Loop:
    movlw   5
    cpfslt  temp, A     ; Skip if temp < 5
    subwf   temp, F, A  ; temp = temp - 5
    movlw   5
    cpfslt  temp, A     ; Check if we need another subtraction
    bra     Mod_5_Loop
    
    ; Store result
    movf    temp, W, A
    movwf   obstacle_type, A
    return

Generate_Bird_Height:
    ; Bird height is only used when obstacle_type = 4
    ; Heights 1-6 represent different vertical positions
    ; Currently storing height but using page 7 for display
    ; TODO: Implement proper bird height when bird sprites are fixed
    ; Use middle bits from low byte for better randomness
    movf    lfsr_low, W, A
    andlw   0x38        ; Get bits 3-5 (0b00111000)
    rrncf   WREG, W, A  ; Rotate right 3 times to get value 0-7
    rrncf   WREG, W, A
    rrncf   WREG, W, A
    movwf   temp, A
    
    ; Now temp contains 0-7
    ; If it's 6 or 7, subtract 5 to wrap back to 1 or 2
    movlw   6
    cpfslt  temp, A     ; Skip if temp < 6
    subwf   temp, F, A  ; temp = temp - 6 if >= 6
    
    ; Add 1 to get range 1-6
    incf    temp, F, A
    movf    temp, W, A
    movwf   bird_height, A
    return

Get_Random_Obstacle:
    movf    obstacle_type, W, A
    return

Get_Random_Height:
    movf    bird_height, W, A
    return

; Draw a single digit (0-9) at current position
Draw_Digit:
    ; Save digit value
    movwf   digit, A
    
    ; Calculate offset into digit data (digit * 5)
    movwf   offset, A    ; Store digit value
    movf    offset, W, A ; Get original value
    addwf   offset, F, A ; Add once (×2)
    addwf   offset, F, A ; Add again (×3)
    addwf   offset, F, A ; Add again (×4)
    addwf   offset, F, A ; Add final time (×5)
    
    ; Set up table pointer to digit data
    movlw   low highword(Digit_Data)
    movwf   TBLPTRU, A
    movlw   high(Digit_Data)
    movwf   TBLPTRH, A
    movlw   low(Digit_Data)
    addwf   offset, W, A    ; Add offset
    movwf   TBLPTRL, A
    
    ; Draw 5 columns
    movlw   5
    movwf   temp, A
    
Draw_Digit_Loop:
    tblrd*+             ; Read byte from table
    movf    TABLAT, W, A
    call    GLCD_Data   ; Send to display
    decfsz  temp, F, A
    bra     Draw_Digit_Loop
    
    return

Display_RNG:
    call    GLCD_Render_RNG 
    
    ; Display obstacle type (0-4)
    movf    used_rng_ob, W, A
    call    Draw_Digit
    
    ; If obstacle is bird (4), show height
    movlw   4
    cpfseq  used_rng_ob, A
    return
    
    call    GLCD_Render_Slash
    
    ; Display bird height (1-6)
    movf    used_rng_bird, W, A
    call    Draw_Digit
    
    return

end