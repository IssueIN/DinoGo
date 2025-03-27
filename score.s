#include <xc.inc>

; Export functions and variables for use in other files
global  Update_Score, Display_Score, Display_High_Score, Initialize_Score
global  score_low, score_high    ; Make sure these are exported
global  Check_Update_High_Score  ; Export high score comparison function
global  Render_Digit, Display_Speed            ; Export digit rendering function for RNG display
extrn   GLCD_Data, GLCD_CMD, GLCD_Set_Page, GLCD_Set_Y, GLCD_Set_CS
extrn	Agent_Freq

; Variables for score tracking
psect   udata_acs
score_low:      ds 1    ; Low byte of score (0-255)
score_high:     ds 1    ; High byte of score (0-255)
score_pg:       ds 1    ; Page coordinate for score display
score_y:        ds 1    ; Y coordinate for score display
tmp_digit:      ds 1    ; Temporary storage for digit conversion
tmp_value:      ds 1    ; Temporary value for digit extraction
score_counter:  ds 1    ; Counter for rendering
hundreds:       ds 1    ; Storage for hundreds digit
tens:           ds 1    ; Storage for tens digit
ones:           ds 1    ; Storage for ones digit
combined_score: ds 2    ; Combined score for calculation (low and high bytes)
high_score_low: ds 1    ; Low byte of high score (stored in RAM)
high_score_high: ds 1   ; High byte of high score (stored in RAM)
high_hundreds:  ds 1    ; Storage for high score hundreds digit
high_tens:      ds 1    ; Storage for high score tens digit
high_ones:      ds 1    ; Storage for high score ones digit

; Constants for character dimensions
CHAR_WIDTH      EQU 5   ; Width of each character in pixels
CHAR_HEIGHT     EQU 1   ; Height of each character in pages (8 pixels)
DIGIT_WIDTH     EQU 5   ; Width of each digit in pixels
CHAR_SPACING    EQU 1   ; Space between characters

; High score stored in program memory (initialized to 0)
psect   highscore_data,class=CODE
high_score_data:
    db  0x00, 0x00  ; High score value: 0x0000 = 0 (decimal)
                    ; To set a specific initial high score (e.g., 420 or 0x01A4),
                    ; change this to db 0xA4, 0x01

; Character and digit bitmap data
psect   score_const,class=CODE
; Character bitmap data for "SCORE:" and "HI:" text
CHAR_S_DATA:
    db  0x26, 0x49, 0x49, 0x32, 0x00
CHAR_C_DATA:
    db  0x3E, 0x41, 0x41, 0x22, 0x00
CHAR_O_DATA:
    db  0x3E, 0x41, 0x41, 0x3E, 0x00
CHAR_R_DATA:
    db  0x7F, 0x09, 0x19, 0x66, 0x00
CHAR_E_DATA:
    db  0x7F, 0x49, 0x49, 0x41, 0x00
CHAR_COLON_DATA:
    db  0x00, 0x36, 0x36, 0x00, 0x00
CHAR_H_DATA:
    db  0x7F, 0x08, 0x08, 0x08, 0x7F
CHAR_I_DATA:
    db  0x41, 0x7F, 0x41, 0x00, 0x00

; Digit bitmap data for numbers 0-9
DIGIT_0_DATA:
    db  0x3E, 0x51, 0x49, 0x45, 0x3E
DIGIT_1_DATA:
    db  0x00, 0x42, 0x7F, 0x40, 0x00
DIGIT_2_DATA:
    db  0x42, 0x61, 0x51, 0x49, 0x46
DIGIT_3_DATA:
    db  0x21, 0x41, 0x45, 0x4B, 0x31
DIGIT_4_DATA:
    db  0x18, 0x14, 0x12, 0x7F, 0x10
DIGIT_5_DATA:
    db  0x27, 0x45, 0x45, 0x45, 0x39
DIGIT_6_DATA:
    db  0x3C, 0x4A, 0x49, 0x49, 0x30
DIGIT_7_DATA:
    db  0x01, 0x71, 0x09, 0x05, 0x03
DIGIT_8_DATA:
    db  0x36, 0x49, 0x49, 0x49, 0x36
DIGIT_9_DATA:
    db  0x06, 0x49, 0x49, 0x29, 0x1E

; Main code section
psect   score_code,class=CODE

; Initialize the score system
Initialize_Score:
    ; Reset score to zero
    clrf    score_low, A
    clrf    score_high, A
    
    ; Initialize high score to zero
    ; Comment out the next two lines and uncomment the following lines
    ; if you want to start with a specific high score (e.g., 420)
    clrf    high_score_low, A
    clrf    high_score_high, A
    
    ; To set initial high score to 420 (0x01A4), uncomment these lines:
    ; movlw   0xA4
    ; movwf   high_score_low, A
    ; movlw   0x01
    ; movwf   high_score_high, A
    
    return

; Update the score (increment by 1)
Update_Score:
    ; Save STATUS register because we need to check Z flag
    movf    STATUS, W, A
    movwf   tmp_value, A
    
    ; Increment low byte
    incf    score_low, F, A
    
    ; Check if score_low became zero (overflow from 0xFF to 0x00)
    movf    score_low, W, A
    bnz     Update_Score_Done    ; If score_low is not zero, no overflow occurred
    
    ; If we reach here, score_low overflowed (0xFF -> 0x00)
    incf    score_high, F, A     ; Increment high byte
    
Update_Score_Done:
    return

; Renders a single character at current position
; Input: W contains the character code (ASCII)
; Uses score_pg and score_y as position
Render_Char:
    ; Save the character code
    movwf   tmp_digit, A
    
    ; Check for each supported character
    movlw   'S'
    cpfseq  tmp_digit, A
    goto    Check_C
    ; It's character S
    movlw   low highword(CHAR_S_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_S_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_S_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_C:
    movlw   'C'
    cpfseq  tmp_digit, A
    goto    Check_O
    ; It's character C
    movlw   low highword(CHAR_C_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_C_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_C_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_O:
    movlw   'O'
    cpfseq  tmp_digit, A
    goto    Check_R
    ; It's character O
    movlw   low highword(CHAR_O_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_O_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_O_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_R:
    movlw   'R'
    cpfseq  tmp_digit, A
    goto    Check_E
    ; It's character R
    movlw   low highword(CHAR_R_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_R_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_R_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_E:
    movlw   'E'
    cpfseq  tmp_digit, A
    goto    Check_H
    ; It's character E
    movlw   low highword(CHAR_E_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_E_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_E_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common

Check_H:
    movlw   'H'
    cpfseq  tmp_digit, A
    goto    Check_I
    ; It's character H
    movlw   low highword(CHAR_H_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_H_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_H_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_I:
    movlw   'I'
    cpfseq  tmp_digit, A
    goto    Check_Colon
    ; It's character I
    movlw   low highword(CHAR_I_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_I_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_I_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common

Check_Colon:
    movlw   ':'
    cpfseq  tmp_digit, A
    goto    Check_Digit_0
    ; It's a colon
    movlw   low highword(CHAR_COLON_DATA)
    movwf   TBLPTRU, A
    movlw   high(CHAR_COLON_DATA)
    movwf   TBLPTRH, A
    movlw   low(CHAR_COLON_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_0:
    movlw   '0'
    cpfseq  tmp_digit, A
    goto    Check_Digit_1
    ; It's digit 0
    movlw   low highword(DIGIT_0_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_0_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_0_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_1:
    movlw   '1'
    cpfseq  tmp_digit, A
    goto    Check_Digit_2
    ; It's digit 1
    movlw   low highword(DIGIT_1_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_1_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_1_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common

Check_Digit_2:
    movlw   '2'
    cpfseq  tmp_digit, A
    goto    Check_Digit_3
    ; It's digit 2
    movlw   low highword(DIGIT_2_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_2_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_2_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_3:
    movlw   '3'
    cpfseq  tmp_digit, A
    goto    Check_Digit_4
    ; It's digit 3
    movlw   low highword(DIGIT_3_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_3_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_3_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_4:
    movlw   '4'
    cpfseq  tmp_digit, A
    goto    Check_Digit_5
    ; It's digit 4
    movlw   low highword(DIGIT_4_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_4_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_4_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_5:
    movlw   '5'
    cpfseq  tmp_digit, A
    goto    Check_Digit_6
    ; It's digit 5
    movlw   low highword(DIGIT_5_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_5_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_5_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_6:
    movlw   '6'
    cpfseq  tmp_digit, A
    goto    Check_Digit_7
    ; It's digit 6
    movlw   low highword(DIGIT_6_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_6_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_6_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_7:
    movlw   '7'
    cpfseq  tmp_digit, A
    goto    Check_Digit_8
    ; It's digit 7
    movlw   low highword(DIGIT_7_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_7_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_7_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_8:
    movlw   '8'
    cpfseq  tmp_digit, A
    goto    Check_Digit_9
    ; It's digit 8
    movlw   low highword(DIGIT_8_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_8_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_8_DATA)
    movwf   TBLPTRL, A
    goto    Render_Char_Common
    
Check_Digit_9:
    movlw   '9'
    cpfseq  tmp_digit, A
    goto    Render_Char_End  ; Not a recognized character, exit
    ; It's digit 9
    movlw   low highword(DIGIT_9_DATA)
    movwf   TBLPTRU, A
    movlw   high(DIGIT_9_DATA)
    movwf   TBLPTRH, A
    movlw   low(DIGIT_9_DATA)
    movwf   TBLPTRL, A
    
Render_Char_Common:
    ; Setup for 5 pixels wide characters/digits
    movlw   CHAR_WIDTH
    movwf   score_counter, A
    
    ; Set position
    movf    score_y, W, A
    call    GLCD_Set_CS
    
    movf    score_pg, W, A
    call    GLCD_Set_Page

Render_Char_Loop:
    tblrd*+                  ; Read byte from table and increment pointer
    movf    TABLAT, W, A     ; Get byte into W
    call    GLCD_Data        ; Send to display
    
    decfsz  score_counter, F, A   ; Decrement counter, skip if zero
    goto    Render_Char_Loop      ; Not zero, loop again
    
    ; After rendering, add space for next character
    movlw   CHAR_WIDTH + CHAR_SPACING  ; Character width + spacing
    addwf   score_y, F, A    ; Update Y coordinate for next character
    
Render_Char_End:
    return

; Render a digit (0-9) at the current position
; Input: W contains numeric value (0-9)
Render_Digit:
    ; Convert numeric value to ASCII ('0'-'9')
    addlw   '0'          ; Add ASCII value of '0' to convert to character
    call    Render_Char  ; Use existing character rendering
    return

; Renders the current score value (converts binary score to digits)
; Displays score as 3 digits (000-999)
Render_Score_Value:
    ; Convert the score to decimal digits
    call    Convert_Score_To_Digits
    
    ; Display the hundreds digit
    movf    hundreds, W, A
    call    Render_Digit
    
    ; Display the tens digit
    movf    tens, W, A
    call    Render_Digit
    
    ; Display the ones digit
    movf    ones, W, A
    call    Render_Digit
    
    return

; Convert the score (score_low and score_high) to decimal digits
; Output: hundreds, tens, and ones variables
Convert_Score_To_Digits:
    ; Clear the digit variables
    clrf    hundreds, A
    clrf    tens, A
    clrf    ones, A
    
    ; Create a combined score from both bytes
    ; First, copy score_low to combined_score low byte
    movf    score_low, W, A
    movwf   combined_score, A
    
    ; Copy score_high to combined_score high byte
    movf    score_high, W, A
    movwf   combined_score+1, A
    
    ; Now determine if the combined score > 999 (0x03E7)
    ; Check high byte
    movlw   0x03
    cpfslt  combined_score+1, A      ; Skip if combined_score+1 < 0x03
    goto    Check_If_At_Limit
    cpfsgt  combined_score+1, A      ; Skip if combined_score+1 > 0x03
    goto    Process_Combined_Score   ; If less than 0x03, process normally
    goto    Set_To_Max               ; If greater than 0x03, set to max 999
    
Check_If_At_Limit:
    ; High byte is exactly 0x03, check low byte
    movlw   0xE7
    cpfsgt  combined_score, A        ; Skip if combined_score > 0xE7 
    goto    Process_Combined_Score   ; If <= 0xE7, process normally
    
Set_To_Max:
    ; Score is > 999, cap at 999
    movlw   9
    movwf   hundreds, A
    movlw   9
    movwf   tens, A
    movlw   9
    movwf   ones, A
    return
    
Process_Combined_Score:
    ; Process the hundreds place
    clrf    hundreds, A              ; Clear hundreds digit
    
Hundreds_Loop:
    movlw   0x01                     ; High byte = 0x01 means 256
    cpfslt  combined_score+1, A      ; Skip if combined_score+1 < 0x01 
    goto    Subtract_256
    
    ; Process remaining value < 256
    movf    combined_score, W, A
    movwf   tmp_value, A
    
    ; Extract hundreds from remainder
Extract_Hundreds:
    movlw   100
    cpfslt  tmp_value, A             ; Skip if tmp_value < 100
    goto    Subtract_100
    goto    Extract_Tens             ; Move to tens if < 100
    
Subtract_256:
    ; Subtract 256 from combined_score and add 2 to hundreds
    movlw   0x01
    subwf   combined_score+1, F, A
    movlw   2
    addwf   hundreds, F, A
    goto    Hundreds_Loop
    
Subtract_100:
    ; Subtract 100 from tmp_value and add 1 to hundreds
    movlw   100
    subwf   tmp_value, F, A
    incf    hundreds, F, A
    goto    Extract_Hundreds
    
    ; Extract tens
Extract_Tens:
    clrf    tens, A                  ; Clear tens digit
    
Tens_Loop:
    movlw   10
    cpfslt  tmp_value, A             ; Skip if tmp_value < 10
    goto    Subtract_10
    goto    Extract_Ones             ; Move to ones if < 10
    
Subtract_10:
    ; Subtract 10 from tmp_value and add 1 to tens
    movlw   10
    subwf   tmp_value, F, A
    incf    tens, F, A
    goto    Tens_Loop
    
    ; What's left is ones
Extract_Ones:
    movf    tmp_value, W, A
    movwf   ones, A
    
    return

; Display the score on screen
; Function will render "SCORE:" followed by numeric score
Display_Score:
    ; Set position for score display (top-left corner for better visibility)
    movlw   0               ; Top row (page 0)
    movwf   score_pg, A
    movlw   5               ; Y-position in pixels (left side instead of 90)
    movwf   score_y, A
    
    ; Render "SCORE:" label
    movlw   'S'
    call    Render_Char
    movlw   'C'
    call    Render_Char
    movlw   'O'
    call    Render_Char
    movlw   'R'
    call    Render_Char
    movlw   'E'
    call    Render_Char
    movlw   ':'
    call    Render_Char
    
    ; Add a space after "SCORE:"
    movlw   2
    addwf   score_y, F, A
    
    ; Render the score value (now supports 000-999)
    call    Render_Score_Value
    
    return

; Compare current score with high score and update if needed
; This function is called when game over is triggered
Check_Update_High_Score:
    ; First, compare score_high with high_score_high
    movf    high_score_high, W, A
    cpfsgt  score_high, A        ; Skip if score_high > high_score_high
    goto    Check_Equal_High     ; If score_high <= high_score_high, check if equal
    goto    Update_High_Score    ; If score_high > high_score_high, update

Check_Equal_High:
    ; If high bytes are equal, compare low bytes
    cpfseq  score_high, A        ; Skip if score_high == high_score_high
    goto    No_Update            ; If score_high < high_score_high, no update
    
    ; High bytes are equal, check low bytes
    movf    high_score_low, W, A
    cpfsgt  score_low, A         ; Skip if score_low > high_score_low
    goto    No_Update            ; If score_low <= high_score_low, no update

Update_High_Score:
    ; Update high score with current score
    movf    score_low, W, A
    movwf   high_score_low, A
    movf    score_high, W, A
    movwf   high_score_high, A

No_Update:
    return

; Convert the high score value to digits (similar to Convert_Score_To_Digits)
Convert_High_Score_To_Digits:
    ; Clear the digit variables
    clrf    high_hundreds, A
    clrf    high_tens, A
    clrf    high_ones, A
    
    ; Create a combined score from both bytes of high score
    ; First, copy high_score_low to combined_score low byte
    movf    high_score_low, W, A
    movwf   combined_score, A
    
    ; Copy high_score_high to combined_score high byte
    movf    high_score_high, W, A
    movwf   combined_score+1, A
    
    ; Now determine if the combined score > 999 (0x03E7)
    ; Check high byte
    movlw   0x03
    cpfslt  combined_score+1, A      ; Skip if combined_score+1 < 0x03
    goto    HS_Check_If_At_Limit
    cpfsgt  combined_score+1, A      ; Skip if combined_score+1 > 0x03
    goto    HS_Process_Combined_Score   ; If less than 0x03, process normally
    goto    HS_Set_To_Max               ; If greater than 0x03, set to max 999
    
HS_Check_If_At_Limit:
    ; High byte is exactly 0x03, check low byte
    movlw   0xE7
    cpfsgt  combined_score, A        ; Skip if combined_score > 0xE7 
    goto    HS_Process_Combined_Score   ; If <= 0xE7, process normally
    
HS_Set_To_Max:
    ; Score is > 999, cap at 999
    movlw   9
    movwf   high_hundreds, A
    movlw   9
    movwf   high_tens, A
    movlw   9
    movwf   high_ones, A
    return
    
HS_Process_Combined_Score:
    ; Process the hundreds place
    clrf    high_hundreds, A         ; Clear hundreds digit
    
HS_Hundreds_Loop:
    movlw   0x01                     ; High byte = 0x01 means 256
    cpfslt  combined_score+1, A      ; Skip if combined_score+1 < 0x01 
    goto    HS_Subtract_256
    
    ; Process remaining value < 256
    movf    combined_score, W, A
    movwf   tmp_value, A
    
    ; Extract hundreds from remainder
HS_Extract_Hundreds:
    movlw   100
    cpfslt  tmp_value, A             ; Skip if tmp_value < 100
    goto    HS_Subtract_100
    goto    HS_Extract_Tens          ; Move to tens if < 100
    
HS_Subtract_256:
    ; Subtract 256 from combined_score and add 2 to hundreds
    movlw   0x01
    subwf   combined_score+1, F, A
    movlw   2
    addwf   high_hundreds, F, A
    goto    HS_Hundreds_Loop
    
HS_Subtract_100:
    ; Subtract 100 from tmp_value and add 1 to hundreds
    movlw   100
    subwf   tmp_value, F, A
    incf    high_hundreds, F, A
    goto    HS_Extract_Hundreds
    
    ; Extract tens
HS_Extract_Tens:
    clrf    high_tens, A             ; Clear tens digit
    
HS_Tens_Loop:
    movlw   10
    cpfslt  tmp_value, A             ; Skip if tmp_value < 10
    goto    HS_Subtract_10
    goto    HS_Extract_Ones          ; Move to ones if < 10
    
HS_Subtract_10:
    ; Subtract 10 from tmp_value and add 1 to tens
    movlw   10
    subwf   tmp_value, F, A
    incf    high_tens, F, A
    goto    HS_Tens_Loop
    
    ; What's left is ones
HS_Extract_Ones:
    movf    tmp_value, W, A
    movwf   high_ones, A
    
    return

; Renders the high score value
; Uses separate high score digit variables to avoid conflicts with current score
Render_High_Score_Value:
    ; Convert high score to digits first
    call    Convert_High_Score_To_Digits
    
    ; Display the hundreds digit
    movf    high_hundreds, W, A
    call    Render_Digit
    
    ; Display the tens digit
    movf    high_tens, W, A
    call    Render_Digit
    
    ; Display the ones digit
    movf    high_ones, W, A
    call    Render_Digit
    
    return

; Display high score on screen
; Function will render "HI:" followed by high score value
Display_High_Score:
    ; Set position for high score display (top-right corner)
    movlw   0               ; Top row (page 0)
    movwf   score_pg, A
    movlw   80              ; Y-position in pixels (right side)
    movwf   score_y, A
    
    ; Render "HI:" label
    movlw   'H'
    call    Render_Char
    movlw   'I'
    call    Render_Char
    movlw   ':'
    call    Render_Char
    
    ; Add a space after "HI:"
    movlw   2
    addwf   score_y, F, A
    
    ; Render the high score value
    call    Render_High_Score_Value
    
    return
    
  
Display_Speed:
    ; Set position for score display (top-left corner for better visibility)
    movlw   1               ; Top row (page 0)
    movwf   score_pg, A
    movlw   43               ; Y-position in pixels (left side instead of 90)
    movwf   score_y, A
    
    movf    Agent_Freq, W, A
    sublw   21
;    movlw   43
    call    Display_Two_Digits
;    movlw   5
;    call    Render_Digit
    
    return
    
Display_Two_Digits:
    movwf   tmp_value, A
    clrf    tens, A

Digit_Divide_Loop:
    movlw   10
    cpfslt  tmp_value, A
    bra	    Update_tens
    bra	    Update_ones
Update_tens:
    subwf   tmp_value, A
    incf    tens, F, A
    bra	    Digit_Divide_Loop
Update_ones:
    movf    tmp_value, W, A
    movwf   ones, A

    ; Render tens (blank if zero)
    movf    tens, W, A
    call    Render_Digit
 
    
    movlw   1               ; Top row (page 0)
    movwf   score_pg, A
    movlw   49               ; Y-position in pixels (left side instead of 90)
    movwf   score_y, A

    ; Render ones
    movf    ones, W, A
    call    Render_Digit
    return

end