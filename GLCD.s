#include <xc.inc>
    
global	GLCD_Setup, GLCD_Data, GLCD_Display_On, GLCD_Clear_Screen, GLCD_Render_DINO_RUN1, GLCD_Render_DINO_RUN2, GLCD_Render_Cactus, GLCD_Render_Slogan, GLCD_Render_DINO_JUMP
global	GLCD_Render_DINO_DUCK1, GLCD_Render_DINO_DUCK2, GLCD_Render_Bird1, GLCD_Render_Bird2 , GLCD_Render_DinoGo 
global	GLCD_Render_Cactus_Large, GLCD_Render_Cactus_Medium, GLCD_Render_Cactus_Small
global	GLCD_CMD, GLCD_Set_Page, GLCD_Set_Y, GLCD_Set_CS, GLCD_Clear_DINO_JUMP
global	GLCD_Clear_Cactus_Large, GLCD_Clear_Cactus_Medium, GLCD_Clear_Cactus_Small, GLCD_Clear_Bird1, GLCD_Clear_Bird2
global	GLCD_Render_GameOver, GLCD_Render_RestartMessage
global	GLCD_Read_Screen_UART, GLCD_Render_RNG, GLCD_Render_Slash, GLCD_Render_Speed
extrn	page_coord, y_coord, DINO_page, DINO_y
extrn	UART_Transmit_Byte
extrn	delay_x4us, delay_ms

psect	udata_acs
GLCD_cnt_y:	    ds 1		
GLCD_cnt_pg:	    ds 1
GLCD_tmp:	    ds 1   ; reserve 1 byte for temporary use
GLCD_counter:	    ds 1   ; reserve 1 byte for counting
GLCD_pg:	    ds 1
GLCD_y:		    ds 1
y_add:		    ds 1
y_adjusted:	    ds 1
_sprite_h:	    ds 1
_sprite_l:	    ds 1
_sprite_size:	    ds 1
clear_page:	    ds 1
clear_y:	    ds 1

    
	;Define Register Address
	GLCD_CS1  EQU 0  ; Chip Select 1 (RB0)
	GLCD_CS2  EQU 1  ; Chip Select 2 (RB1)
	GLCD_RS   EQU 2  ; Register Select (RB2)
	GLCD_RW   EQU 3  ; Read/Write (RB3)
	GLCD_E    EQU 4  ; Enable (RB4)
	GLCD_RST  EQU 5  ; Reset (RB5)
 
psect	udata_bank4
dino_run_array:	    ds 0x80 ; reserve 128 bytes for dino_run_data

psect	data
DINO_RUN1_DATA:
    db	0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFE, 0xFF, 0xFF, 0xFF, 0xF7, 0xB7, 0xBF, 0x3F, 0x3F
    db	0x0F, 0x1E, 0x3C, 0x38, 0xFF, 0x7F, 0x3F, 0x7F, 0xFF, 0x1F, 0x0F, 0x02, 0x00, 0x00, 0x00

DINO_RUN2_DATA:
    db  0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFE, 0xFF, 0xFF, 0xFF, 0xF7, 0xB7, 0xBF, 0x3F, 0x3F
    db  0x0F, 0x1E, 0x3C, 0x38, 0x3F, 0x7F, 0xFF, 0xBF, 0x3F, 0x1F, 0x0F, 0x02, 0x00, 0x00, 0x00

DINO_JUMP_DATA:
    db  0x00, 0x00, 0x00, 0x00, 0x00, 0x80, 0xFE, 0xFF, 0xFF, 0xFF, 0xF7, 0xB7, 0xBF, 0x3F, 0x3F
    db  0x0F, 0x1E, 0x3C, 0x38, 0xFF, 0x7F, 0x3F, 0x3F, 0x7F, 0x1F, 0x0F, 0x02, 0x00, 0x00, 0x00


DINO_DUCK1_DATA:
    db	0x0F, 0x0F, 0x1E, 0x3E, 0x3C, 0xFF, 0x7F, 0x3F
    db	0x7F, 0xFF, 0x3F, 0x3F, 0x1E, 0x1E, 0x3E, 0x3F
    db  0x3F, 0x3F, 0x3D, 0x2D, 0x2F, 0x0F, 0x0F

DINO_DUCK2_DATA:
    db  0x0F, 0x0F, 0x1E, 0x3E, 0x3C, 0x3F, 0x7F, 0xFF
    db	0xBF, 0x3F, 0x3F, 0x3F, 0x1E, 0x1E, 0x3E, 0x3F
    db	0x3F, 0x3F, 0x3D, 0x2D, 0x2F, 0x0F, 0x0F

BIRD1_DATA:
    db  0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xE0, 0xC0, 0x80
    db  0xFF, 0xFE, 0xFC, 0xF0, 0xE0, 0xC0, 0x80, 0x00, 0x00, 0x00
    db  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03
    db  0x03, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x05, 0x05, 0x01

BIRD2_DATA:
    db  0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xE0, 0xC0, 0x80
    db  0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00
    db  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x03, 0xFF, 0x7F
    db  0x3F, 0x0F, 0x07, 0x07, 0x07, 0x05, 0x05, 0x01

CACTUS_DATA:
    db  0x00, 0x00, 0xC0, 0x00, 0xFE, 0x30, 0x20, 0xFE, 0x00, 0x00
    db  0x04, 0x7C, 0x41, 0x41, 0xFF, 0x80, 0xC0, 0x7F, 0x02, 0x00

CACTUS_LARGE_DATA:
    db  0x80, 0x00, 0x00, 0xf0, 0xf0, 0xf0, 0xf0, 0x00, 0x00, 0x00
    db  0x0f, 0x1c, 0x18, 0xff, 0xff, 0xff, 0xff, 0x60, 0x60, 0x3c
    db  0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00

CACTUS_MEDIUM_DATA:
    db	0x00, 0x00, 0x00, 0xf0, 0xf0, 0xf0, 0x00, 0xc0, 0x00, 0x00, 0x00, 0x00, 0xf0, 0xf0, 0xf0, 0x00 
    db	0xc0, 0xf0, 0x07, 0x04, 0xff, 0xff, 0xff, 0x00, 0xff, 0x00, 0xf0, 0x07, 0x04, 0xff, 0xff, 0xff 
    db	0x00, 0xff, 0x01, 0x01, 0x01, 0xff, 0xff, 0xff, 0x03, 0x01, 0x00, 0x01, 0x01, 0x01, 0xff, 0xff 
    db	0xff, 0x03, 0x01

CACTUS_SMALL_DATA:
    db  0x00, 0xc0, 0xfc, 0x10, 0x10, 0xf8, 0x00, 0x00, 0xc0, 0xfc
    db  0x10, 0x10, 0xf8, 0x00, 0x00, 0xc0, 0xfc, 0x10, 0x10, 0xf8
    db  0x00, 0x3e, 0x20, 0xff, 0xc0, 0x66, 0x3f, 0x01, 0x3e, 0x20
    db  0xff, 0xc0, 0x66, 0x3f, 0x01, 0x3e, 0x20, 0xff, 0xc0, 0x66
    db  0x3f, 0x01


Slogan_DATA:
    db  0x7F, 0x09, 0x09, 0x09, 0x06, 0x00  ; P
    db  0x7F, 0x09, 0x19, 0x29, 0x46, 0x00  ; R
    db  0x7F, 0x49, 0x49, 0x49, 0x41, 0x00  ; E
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x00, 0x00                          ; Space
    db  0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00  ; A
    db  0x7F, 0x04, 0x08, 0x10, 0x7F, 0x00  ; N
    db  0x07, 0x08, 0x70, 0x08, 0x07, 0x00  ; Y
    db  0x00, 0x00                          ; Space
    db  0x08, 0x14, 0x22, 0x41, 0x41, 0x22, 0x14, 0x08 ; button
    db  0x00, 0x00                          ; Space
    db  0x01, 0x01, 0x7F, 0x01, 0x01, 0x00  ; T
    db  0x3E, 0x41, 0x41, 0x41, 0x3E, 0x00  ; O
    db  0x00, 0x00                          ; Space
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x01, 0x01, 0x7F, 0x01, 0x01, 0x00  ; T
    db  0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00  ; A
    db  0x7F, 0x09, 0x19, 0x29, 0x46, 0x00  ; R
    db  0x01, 0x01, 0x7F, 0x01, 0x01, 0x00  ; T
 
DinoGo_DATA:
    db	0xff, 0xff, 0xff, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x0f, 0x0f, 0xfc, 0xfc, 0xf8, 0xf0, 0xe0 
    db	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x70, 0x70, 0xf3, 0xf3, 0xf3, 0xf3, 0x20, 0x00, 0x00 
    db	0x00, 0x00, 0x00, 0x00, 0xe0, 0xf0, 0xf0, 0xf0, 0xf0, 0x70, 0x70, 0x70, 0x70, 0x70, 0x70, 0x70 
    db	0xf0, 0xe0, 0x80, 0x80, 0x00, 0x00, 0x00, 0x80, 0x80, 0xf0, 0xf0, 0x70, 0x70, 0x70, 0x70, 0x70 
    db	0x70, 0x70, 0xf0, 0xf0, 0x80, 0x80, 0x80, 0x00, 0x00, 0xf0, 0xf0, 0xfc, 0xfc, 0x1f, 0x0f, 0x0f 
    db	0x03, 0x03, 0x83, 0x83, 0x83, 0x83, 0x83, 0x83, 0x83, 0x00, 0x00, 0x80, 0x80, 0xe0, 0xf0, 0xf0 
    db	0x70, 0x70, 0x70, 0x70, 0x70, 0x70, 0x70, 0xf0, 0xe0, 0x80, 0x80, 0xff, 0xff, 0xff, 0xff, 0xe0 
    db	0xc0, 0xc0, 0xc0, 0xc0, 0xf8, 0xf8, 0x3f, 0x3f, 0x1f, 0x07, 0x07, 0x00, 0x00, 0x00, 0x00, 0xc0 
    db	0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff, 0xff, 0xff, 0xe0, 0xc0, 0xc0, 0xc0, 0xc0, 0x00, 0x00, 0xff 
    db	0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00 
    db	0x00, 0x00, 0x3f, 0x3f, 0xff, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff, 0x3f 
    db	0x3f, 0x1f, 0x00, 0x00, 0x07, 0x07, 0x3f, 0x3f, 0xf8, 0xf8, 0xf0, 0xc0, 0xc0, 0xc1, 0xc1, 0xff 
    db	0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x3f, 0x3f, 0xff, 0xff, 0xff, 0xc0, 0xc0, 0xc0, 0xc0, 0xc0 
    db	0xc0, 0xe0, 0xff, 0xff, 0x3f, 0x3f
 
RESTART_SLOGAN_DATA:
    db  0x7F, 0x09, 0x09, 0x09, 0x06, 0x00  ; P
    db  0x7F, 0x09, 0x19, 0x29, 0x46, 0x00  ; R
    db  0x7F, 0x49, 0x49, 0x49, 0x41, 0x00  ; E
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x00, 0x00                          ; Space
    db  0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00  ; A
    db  0x7F, 0x04, 0x08, 0x10, 0x7F, 0x00  ; N
    db  0x07, 0x08, 0x70, 0x08, 0x07, 0x00  ; Y
    db  0x00, 0x00                          ; Space
    db  0x08, 0x14, 0x22, 0x41, 0x41, 0x22, 0x14, 0x08 ; button
    db  0x00, 0x00                          ; Space
    db  0x01, 0x01, 0x7F, 0x01, 0x01, 0x00  ; T
    db  0x3E, 0x41, 0x41, 0x41, 0x3E, 0x00  ; O
    db  0x00, 0x00                          ; Space
    db  0x7F, 0x09, 0x19, 0x29, 0x46, 0x00  ; R
    db  0x7F, 0x49, 0x49, 0x49, 0x41, 0x00  ; E
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x01, 0x01, 0x7F, 0x01, 0x01, 0x00  ; T
    db  0x7E, 0x11, 0x11, 0x11, 0x7E, 0x00  ; A
    db  0x7F, 0x09, 0x19, 0x29, 0x46, 0x00  ; R
    db  0x01, 0x01, 0x7F, 0x01, 0x01, 0x00  ; T

GAME_OVER_DATA:
    db 0xe0, 0xe0, 0xf8, 0xfc, 0x1f, 0x0f, 0x03, 0x03, 0x83, 0x83, 0x83, 0x83, 0x83, 0x02, 0x00, 0x00
    db 0x00, 0x00, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0xe0, 0xe0, 0x80, 0x80, 0x00, 0x00, 0xe0
    db 0xe0, 0x60, 0x60, 0xe0, 0xe0, 0xe0, 0xe0, 0x60, 0x60, 0xe0, 0xe0, 0x80, 0x80, 0x00, 0x00, 0x80
    db 0x80, 0xe0, 0xe0, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0xe0, 0xe0, 0x80, 0x80, 0x00, 0x00, 0xf8
    db 0xf8, 0xff, 0xff, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0xff, 0xff, 0xf8, 0xf8, 0x00, 0x00, 0x00
    db 0x00, 0xe0, 0xe0, 0xe0, 0xe0, 0x00, 0x00, 0x00, 0x00, 0xe0, 0xe0, 0xe0, 0xe0, 0x00, 0x00, 0x80
    db 0x80, 0xe0, 0xe0, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0xe0, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00
    db 0xe0, 0xe0, 0xe0, 0xe0, 0x80, 0x80, 0x60, 0x60, 0x60, 0x60, 0x60, 0x60, 0x0f, 0x0f, 0x3f, 0x3f
    db 0xf0, 0xf0, 0xc0, 0xc0, 0xc1, 0xc3, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x30, 0x38, 0xfe, 0xce
    db 0xce, 0xce, 0xce, 0xce, 0xce, 0xee, 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff
    db 0xff, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x3f, 0x3f, 0xff, 0xff, 0xce
    db 0xce, 0xce, 0xce, 0xce, 0xce, 0xcf, 0xcf, 0x0f, 0x0f, 0x00, 0x00, 0x3f, 0x3f, 0xff, 0xff, 0xc0
    db 0xc0, 0xc0, 0xc0, 0xc0, 0xc0, 0xff, 0xff, 0x3f, 0x3f, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x0f, 0x3f
    db 0x3f, 0xf0, 0xf0, 0xf0, 0xf8, 0x3f, 0x3f, 0x0f, 0x07, 0x00, 0x00, 0x3f, 0x3f, 0xff, 0xee, 0xce
    db 0xce, 0xce, 0xce, 0xce, 0xce, 0xcf, 0x0f, 0x0f, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff
    db 0x03, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
 
RNG_DATA:
    db  0x7F, 0x09, 0x19, 0x29, 0x46 ; R
    db	0x00
    db  0x7F, 0x04, 0x08, 0x10, 0x7F ; N
    db	0x00
    db  0x3E, 0x41, 0x49, 0x49, 0x3A ; G
    db	0x00
    db  0x00, 0x36, 0x36, 0x00, 0x00 ; :
    db	0x00

SLASH_DATA:
    db	0x00, 0x20, 0x10, 0x08, 0x04, 0x02, 0x00 ; /
    
SPEED_DATA:
    db  0x46, 0x49, 0x49, 0x49, 0x31, 0x00  ; S
    db  0x7F, 0x09, 0x09, 0x09, 0x06, 0x00  ; P
    db  0x7F, 0x49, 0x49, 0x49, 0x41, 0x00  ; E
    db  0x7F, 0x49, 0x49, 0x49, 0x41, 0x00  ; E
    db  0x7F, 0x41, 0x41, 0x22, 0x1C, 0x00  ; D
    db  0x00, 0x36, 0x36, 0x00, 0x00 ; :
    
; ; Game Over character data
;CHAR_G_DATA:
;    db  0x3E, 0x41, 0x41, 0x51, 0x32 ; G
;CHAR_A_DATA:
;    db  0x7E, 0x11, 0x11, 0x11, 0x7E ; A
;CHAR_M_DATA:
;    db  0x7F, 0x02, 0x0C, 0x02, 0x7F ; M
;CHAR_E_DATA:
;    db  0x7F, 0x49, 0x49, 0x49, 0x41 ; E
;CHAR_O_DATA:
;    db  0x3E, 0x41, 0x41, 0x41, 0x3E ; O
;CHAR_V_DATA:
;    db  0x03, 0x1C, 0x60, 0x1C, 0x03 ; V
;CHAR_R_DATA:
;    db  0x7F, 0x09, 0x19, 0x29, 0x46 ; R

DINO_RUN1_L	EQU 15
DINO_RUN1_H	EQU 2
DINO_RUN1_SIZE	EQU 30
DINO_RUN2_L	EQU 15
DINO_RUN2_H	EQU 2
DINO_RUN2_SIZE	EQU 30
DINO_JUMP_L	EQU 15
DINO_JUMP_H	EQU 2
DINO_JUMP_SIZE	EQU 30
DINO_DUCK1_L	EQU 23
DINO_DUCK1_H	EQU 1
DINO_DUCK1_SIZE	EQU 23
DINO_DUCK2_L	EQU 23
DINO_DUCK2_H	EQU 1
DINO_DUCK2_SIZE	EQU 23
BIRD1_L		EQU 18
BIRD1_H		EQU 2
BIRD1_SIZE	EQU 36
BIRD2_L		EQU 18
BIRD2_H		EQU 2
BIRD2_SIZE	EQU 36
CACTUS_L	EQU 10
CACTUS_H	EQU 2
CACTUS_SIZE	EQU 20
CACTUS_LARGE_L	EQU 10
CACTUS_LARGE_H	EQU 3
CACTUS_LARGE_SIZE	EQU 30
CACTUS_MEDIUM_L	EQU 17
CACTUS_MEDIUM_H	EQU 3
CACTUS_MEDIUM_SIZE	EQU 51
CACTUS_SMALL_L	EQU 21
CACTUS_SMALL_H	EQU 2
CACTUS_SMALL_SIZE	EQU 42
Slogan_L	EQU 106
Slogan_H	EQU 1
Slogan_SIZE	EQU 106
DinoGo_L	EQU 107
DinoGo_H	EQU 2
DinoGo_SIZE	EQU 214
RESTART_SLOGAN_L	EQU 118    
RESTART_SLOGAN_H	EQU 1      ; Height in pages (1 page = 8 pixels)
RESTART_SLOGAN_SIZE	EQU 118    ; Total size in bytes
;GAMEOVER_CHAR_WIDTH	EQU 5   ; Width of each character in pixels
;GAMEOVER_CHAR_HEIGHT	EQU 1   ; Height of each character in pages (8 pixels)
;GAMEOVER_CHAR_SPACING	EQU 1  ; Space between characters
GAME_OVER_L	EQU 124
GAME_OVER_H	EQU 2
GAME_OVER_SIZE	EQU 248
RNG_L		EQU 24
RNG_H		EQU 1
RNG_SIZE	EQU 24
SLASH_L		EQU 7
SLASH_H		EQU 1
SLASH_SIZE	EQU 7
SPEED_L		EQU 35
SPEED_H		EQU 1
SPEED_SIZE	EQU 35
;align 12

psect	glcd_code,class=CODE



GLCD_Setup:
    ; Reset
    clrf    LATB, A
    clrf    LATD, A
    movlw   0x00	; Set all pins output
    movwf   TRISB, A
    movwf   TRISD, A
    
    bsf	    LATB, GLCD_RST, A   ; Set Reset High
    call    Delay
    bcf	    LATB, GLCD_RST, A   ; Set Reset Low
    call    Delay
    bsf	    LATB, GLCD_RST, A	; Set Reset High
    call    Delay
;
    bcf     LATB, GLCD_CS1, A
    bcf     LATB, GLCD_CS2, A
    call    GLCD_Display_On
;    call    Delay
    call    GLCD_Clear_Screen
    return

; Set GLCD side (left or right)
;GLCD_Set_Side:
;    movwf   WREG, A
;    sublw   64
;    bnc     Set_Right
;
;    ; Select Left Side
;    bsf     LATB, GLCD_CS1, A
;    bcf     LATB, GLCD_CS2, A
;    return
;    
;Set_Right:
;    ; Select Right Side
;    bsf     LATB, GLCD_CS2, A
;    bcf     LATB, GLCD_CS1, A
;    return

; Set Y position
GLCD_Set_Y:
    andlw   0x3F       ; Ensure only the lower 6 bits are used (Y0-Y5)
    iorlw   0x40       ; Add Y position command base (01000000)
    ;addlw   0x40       ; Add Y position cmd base
    call    GLCD_CMD
    return

; Set Page
GLCD_Set_Page:
    addlw   0xB8       ; Page command base address
    call    GLCD_CMD
    return

    
;
;GLCD_MOVE_CACTUS_:
;    movlw   138
;    movwf   y_add, A
;Cactus_Movement_Loop_:
;    call    GLCD_Clear_Screen  
;    call    GLCD_CACTUS
;    
;    movlw   100                 ; Set delay to 20ms per step
;    call    GLCD_delay_ms       ; Wait 20ms before moving
;    
;    decf    y_add, f, A 
;    
;    movlw   0
;    cpfseq  y_add, A
;    bra     Cactus_Movement_Loop_  ; Continue moving until y_add reaches 0
;    return
;
;GLCD_CACTUS:
;    movlw   5
;    movwf   GLCD_pg, A
;    movlw   CACTUS_L
;    movwf   GLCD_cnt_y, A
;
;GLCD_Load_Cactus:
;    movlw   low	highword(CACTUS_DATA)    ; address of data in PM
;    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
;    movlw   high(CACTUS_DATA) ; address of data in PM
;    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
;    movlw   low(CACTUS_DATA)  ; address of data in PM
;    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
;    movlw   CACTUS_SIZE
;    movwf   GLCD_counter, A
;
;GLCD_Cactus_loop:
;    movf    GLCD_cnt_y, W, A   ; Load GLCD_cnt_y into W
;    subwf   y_add, W, A        ; Compute W = y_add - GLCD_cnt_y
;    call    GLCD_Set_CS
;
;    movf    GLCD_pg, W, A
;    call    GLCD_Set_Page
;    tblrd*+
;    movf    TABLAT, W, A
;    call    GLCD_Data
;    decfsz  GLCD_counter, A
;    bra	    cactus_loop2
;    return
    
;cactus_loop2:
;    decfsz  GLCD_cnt_y, A
;    bra	    GLCD_Cactus_loop
;    
;    incf    GLCD_pg, f, A
;    movf    y_add, W, A
;    call    GLCD_Set_Y
;    movlw   CACTUS_L
;;    movlw   10
;    movwf   GLCD_cnt_y, A
;    movlw   8
;    cpfseq  GLCD_pg, A
;    bra	    GLCD_Cactus_loop
;    return

GLCD_MOVE_Vertical:
    movlw   6
    movwf   GLCD_pg, A
    
_Movement_Loop_V:
    call    GLCD_Clear_Screen  
    
    movf    GLCD_tmp, W, A
    call    GLCD_Render_Cactus	; change to correct render function
    
    movlw   250                 ; Set delay to 250ms per step
    call    delay_ms       ; Wait 20ms before moving
    
    decf    GLCD_pg, f, A 

    movlw   0
    cpfseq  GLCD_pg, A
    bra     _Movement_Loop_V  ; Continue moving until y_add reaches 0
    return
 
GLCD_MOVE_Horizontal:
    movlw   138
    movwf   y_add, A
_Movement_Loop_H:
    call    GLCD_Clear_Screen  
    call    GLCD_Render_Cactus		; change to correct render function
    
    movlw   100                 ; Set delay to 20ms per step
    call    delay_ms       ; Wait 20ms before moving
    
    decf    y_add, f, A 
    
    movlw   0
    cpfseq  y_add, A
    bra     _Movement_Loop_H  ; Continue moving until y_add reaches 0
    return

GLCD_Render_DINO_JUMP:
    movlw   DINO_JUMP_H
    movwf   _sprite_h, A
    movlw   DINO_JUMP_L
    movwf   _sprite_l, A
    movlw   DINO_JUMP_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(DINO_JUMP_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(DINO_JUMP_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(DINO_JUMP_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return  
    
GLCD_Render_DINO_RUN1:
    movlw   DINO_RUN1_H
    movwf   _sprite_h, A
    movlw   DINO_RUN1_L
    movwf   _sprite_l, A
    movlw   DINO_RUN1_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(DINO_RUN1_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(DINO_RUN1_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(DINO_RUN1_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return

GLCD_Render_DINO_RUN2:
    movlw   DINO_RUN2_H
    movwf   _sprite_h, A
    movlw   DINO_RUN2_L
    movwf   _sprite_l, A
    movlw   DINO_RUN2_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(DINO_RUN2_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(DINO_RUN2_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(DINO_RUN2_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
  
GLCD_Render_DINO_DUCK2:
    movlw   DINO_DUCK2_H
    movwf   _sprite_h, A
    movlw   DINO_DUCK2_L
    movwf   _sprite_l, A
    movlw   DINO_DUCK2_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(DINO_DUCK2_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(DINO_DUCK2_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(DINO_DUCK2_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_DINO_DUCK1:
    movlw   DINO_DUCK1_H
    movwf   _sprite_h, A
    movlw   DINO_DUCK1_L
    movwf   _sprite_l, A
    movlw   DINO_DUCK1_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(DINO_DUCK1_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(DINO_DUCK1_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(DINO_DUCK1_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
    
 
GLCD_Render_Cactus:
    movlw   CACTUS_H
    movwf   _sprite_h, A
    movlw   CACTUS_L
    movwf   _sprite_l, A
    movlw   CACTUS_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(CACTUS_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(CACTUS_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(CACTUS_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A   
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_Cactus_Large:
    movlw   CACTUS_LARGE_H
    movwf   _sprite_h, A
    movlw   CACTUS_LARGE_L
    movwf   _sprite_l, A
    movlw   CACTUS_LARGE_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(CACTUS_LARGE_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(CACTUS_LARGE_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(CACTUS_LARGE_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A   
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_Cactus_Medium:
    movlw   CACTUS_MEDIUM_H
    movwf   _sprite_h, A
    movlw   CACTUS_MEDIUM_L
    movwf   _sprite_l, A
    movlw   CACTUS_MEDIUM_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(CACTUS_MEDIUM_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(CACTUS_MEDIUM_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(CACTUS_MEDIUM_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A   
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return

GLCD_Render_Cactus_Small:
    movlw   CACTUS_SMALL_H
    movwf   _sprite_h, A
    movlw   CACTUS_SMALL_L
    movwf   _sprite_l, A
    movlw   CACTUS_SMALL_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(CACTUS_SMALL_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(CACTUS_SMALL_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(CACTUS_SMALL_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A   
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return

GLCD_Render_Bird1:
    movlw   BIRD1_H
    movwf   _sprite_h, A
    movlw   BIRD1_L
    movwf   _sprite_l, A
    movlw   BIRD1_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(BIRD1_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(BIRD1_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(BIRD1_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A   
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
    
GLCD_Render_Bird2:
    movlw   BIRD2_H
    movwf   _sprite_h, A
    movlw   BIRD2_L
    movwf   _sprite_l, A
    movlw   BIRD2_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(BIRD2_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(BIRD2_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(BIRD2_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movf    page_coord, W, A
    movwf   GLCD_pg, A
    movf    y_coord, W, A   
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_Slogan:
    movlw   Slogan_H
    movwf   _sprite_h, A
    movlw   Slogan_L
    movwf   _sprite_l, A
    movlw   Slogan_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(Slogan_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(Slogan_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(Slogan_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movlw   6
    movwf   GLCD_pg, A
    movlw   117
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_DinoGo:
    movlw   DinoGo_H
    movwf   _sprite_h, A
    movlw   DinoGo_L
    movwf   _sprite_l, A
    movlw   DinoGo_SIZE
    movwf   GLCD_counter, A
    movlw   low	highword(DinoGo_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(DinoGo_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(DinoGo_DATA)  ; address of data in PM
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL
    movlw   2
    movwf   GLCD_pg, A
    movlw   117
    movwf   y_add, A
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_GameOver:
    movlw   GAME_OVER_H
    movwf   _sprite_h, A
    movlw   GAME_OVER_L
    movwf   _sprite_l, A
    movlw   GAME_OVER_SIZE
    movwf   GLCD_counter, A
    
    movlw   low	highword(GAME_OVER_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(GAME_OVER_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(GAME_OVER_DATA)  ; Fix: Use RESTART_SLOGAN_DATA instead of Slogan_DATA
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL

    ; Set position for restart message (bottom of screen)
    movlw   2               ; Page 6 (bottom of screen)
    movwf   GLCD_pg, A
    movlw   126              ; Y-position (slightly indented from left)
    movwf   y_add, A
    
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_RNG:
    movlw   RNG_H
    movwf   _sprite_h, A
    movlw   RNG_L
    movwf   _sprite_l, A
    movlw   RNG_SIZE
    movwf   GLCD_counter, A
    
    movlw   low	highword(RNG_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(RNG_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(RNG_DATA)  ; Fix: Use RESTART_SLOGAN_DATA instead of Slogan_DATA
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL

    ; Set position for restart message (bottom of screen)
    movlw   1               ; Page 6 (bottom of screen)
    movwf   GLCD_pg, A
    movlw   104              ; Y-position (slightly indented from left)
    movwf   y_add, A
    
    call    GLCD_Render_Sprite
    return

GLCD_Render_Slash:
    movlw   SLASH_H
    movwf   _sprite_h, A
    movlw   SLASH_L
    movwf   _sprite_l, A
    movlw   SLASH_SIZE
    movwf   GLCD_counter, A
    
    movlw   low	highword(SLASH_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(SLASH_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(SLASH_DATA)  ; Fix: Use RESTART_SLOGAN_DATA instead of Slogan_DATA
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL

    ; Set position for restart message (bottom of screen)
    movlw   1              ; Page 6 (bottom of screen)
    movwf   GLCD_pg, A
    movlw   116              ; Y-position (slightly indented from left)
    movwf   y_add, A
    
    call    GLCD_Render_Sprite
    return
 
GLCD_Render_Speed:
    movlw   SPEED_H
    movwf   _sprite_h, A
    movlw   SPEED_L
    movwf   _sprite_l, A
    movlw   SPEED_SIZE
    movwf   GLCD_counter, A
    
    movlw   low	highword(SPEED_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(SPEED_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(SPEED_DATA)  ; Fix: Use RESTART_SLOGAN_DATA instead of Slogan_DATA
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL

    ; Set position for restart message (bottom of screen)
    movlw   1              ; Page 6 (bottom of screen)
    movwf   GLCD_pg, A
    movlw   40              ; Y-position (slightly indented from left)
    movwf   y_add, A
    
    call    GLCD_Render_Sprite
    return
;    ; Set position for Game Over text (centered on screen)
;    movlw   2               ; Page 2 (middle of screen)
;    movwf   page_coord, A
;    movlw   41              ; Y-position (centered horizontally)
;    movwf   y_coord, A
;    
;    ; Render "G"
;    movlw   GAMEOVER_CHAR_WIDTH
;    movwf   _sprite_l, A
;    movlw   GAMEOVER_CHAR_HEIGHT
;    movwf   _sprite_h, A
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_G_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_G_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_G_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character
;    movlw   6               ; Character width + spacing
;    addwf   y_coord, F, A
;    
;    ; Render "A"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_A_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_A_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_A_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character
;    movlw   6               ; Character width + spacing
;    addwf   y_coord, F, A
;    
;    ; Render "M"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_M_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_M_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_M_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character
;    movlw   6               ; Character width + spacing
;    addwf   y_coord, F, A
;    
;    ; Render "E"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_E_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_E_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_E_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character and add extra space between words
;    movlw   8               ; Character width + extra spacing
;    addwf   y_coord, F, A
;    
;    ; Render "O"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_O_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_O_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_O_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character
;    movlw   6               ; Character width + spacing
;    addwf   y_coord, F, A
;    
;    ; Render "V"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_V_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_V_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_V_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character
;    movlw   6               ; Character width + spacing
;    addwf   y_coord, F, A
;    
;    ; Render "E"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_E_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_E_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_E_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    ; Advance Y position for next character
;    movlw   6               ; Character width + spacing
;    addwf   y_coord, F, A
;    
;    ; Render "R"
;    movlw   5               ; Character width
;    movwf   GLCD_counter, A
;    
;    movlw   low highword(CHAR_R_DATA)
;    movwf   TBLPTRU, A
;    movlw   high(CHAR_R_DATA)
;    movwf   TBLPTRH, A
;    movlw   low(CHAR_R_DATA)
;    movwf   TBLPTRL, A
;    
;    movf    page_coord, W, A
;    movwf   GLCD_pg, A
;    movf    y_coord, W, A
;    movwf   y_add, A
;    call    GLCD_Render_Sprite
;    
;    return

GLCD_Render_RestartMessage:
    ; Setup sprite parameters
    movlw   RESTART_SLOGAN_H
    movwf   _sprite_h, A
    movlw   RESTART_SLOGAN_L
    movwf   _sprite_l, A
    movlw   RESTART_SLOGAN_SIZE
    movwf   GLCD_counter, A
    
    movlw   low	highword(RESTART_SLOGAN_DATA)    ; address of data in PM
    movwf   TBLPTRU, A	; Load upper bits to TBLPTRU
    movlw   high(RESTART_SLOGAN_DATA) ; address of data in PM
    movwf   TBLPTRH, A    ; load high byte to TBLPTRH
    movlw   low(RESTART_SLOGAN_DATA)  ; Fix: Use RESTART_SLOGAN_DATA instead of Slogan_DATA
    movwf   TBLPTRL, A    ; load low byte to TBLPTRL

    ; Set position for restart message (bottom of screen)
    movlw   6               ; Page 6 (bottom of screen)
    movwf   GLCD_pg, A
    movlw   123              ; Y-position (slightly indented from left)
    movwf   y_add, A
    
    call    GLCD_Render_Sprite
    return
    
GLCD_Render_Sprite:
    ; Parameters:
    ; - WREG (H): Height in pages
    ; - PRODL (L): Width in pixels
    ; - PRODH (size): Total size in bytes
    ; - TBLPTR (data): Pointer to sprite data
    ; - GLCD_pg: Starting page
    ; - y_add: Y position
    
    movf   _sprite_l, W, A
    movwf   GLCD_cnt_y, A
    movf    GLCD_pg, W, A
    movwf   GLCD_cnt_pg, A
    
GLCD_Sprite_Loop:
    movf    GLCD_cnt_y, W, A   ; Load GLCD_cnt_y into W
    subwf   y_add, W, A        ; Compute W = y_add - GLCD_cnt_y
    call    GLCD_Set_CS

    movf    GLCD_cnt_pg, W, A
    call    GLCD_Set_Page
    tblrd*+
    movf    TABLAT, W, A
    call    GLCD_Data
    
    decfsz  GLCD_counter, A
    bra	    _sprite_loop2
    return
    
_sprite_loop2:
    decfsz  GLCD_cnt_y, A
    bra	    GLCD_Sprite_Loop
    
    incf    GLCD_cnt_pg, f, A
    
    movf    y_add, W, A
    call    GLCD_Set_CS
    
    movf   _sprite_l, W, A
    movwf   GLCD_cnt_y, A
    
    movf    GLCD_pg, W, A   
    addwf   _sprite_h, W, A
    ;decf    WREG, W, A
    cpfseq  GLCD_cnt_pg, A
    bra	    GLCD_Sprite_Loop
    return
    
GLCD_Write_Message:	    ; Message stored at FSR2, length stored in W
    movwf   GLCD_counter, A
GLCD_Loop_message:
    movf    POSTINC2, W, A   ; Read from RAM
    call    GLCD_Data
    decfsz  GLCD_counter, A
    bra	    GLCD_Loop_message
    return

GLCD_Display_On:
    movlw   0x3F     ; Display ON Command 
    call    GLCD_CMD
    return

GLCD_Display_Off:
    movlw   0x3E     ; **Display OFF Command
    call    GLCD_CMD
    return

; Send Command to GLCD
GLCD_CMD:
    bcf	    LATB, GLCD_E, A	; Set Enable pin Low
    bcf	    LATB, GLCD_RS, A    ; Select Control Lines; Command Mode
    bcf	    LATB, GLCD_RW, A    ; Write Mode
    movwf   LATD, A	   ; Load Command
    call    Enable_Pulse
    return

; Send Data to GLCD
GLCD_Data:
    bcf	    LATB, GLCD_E, A	; Set Enable pin Low
    bsf	    LATB, GLCD_RS, A    ; Data Mode
    bcf	    LATB, GLCD_RW, A    ; Write Mode
    movwf   LATD, A	   ; Load Data
    call    Enable_Pulse
    return

Enable_Pulse:
    bsf	    LATB, GLCD_E, A
    movlw   1
    call    delay_x4us
    bcf	    LATB, GLCD_E, A
    movlw   1
    call    delay_x4us
    return

GLCD_Clear_DINO_JUMP:
    movlw   DINO_JUMP_H
    movwf   _sprite_h, A
    movlw   DINO_JUMP_L
    movwf   _sprite_l, A
    movlw   DINO_JUMP_SIZE
    movwf   GLCD_counter, A
    movf    DINO_page, W, A
    movwf   clear_page, A
    movf    DINO_y, W, A
    movwf   clear_y, A
    call    GLCD_Clear_Area
    return  
 
GLCD_Clear_Cactus_Large:
    movlw   CACTUS_LARGE_H
    movwf   _sprite_h, A
    movlw   CACTUS_LARGE_L
    movwf   _sprite_l, A
    movlw   CACTUS_LARGE_SIZE
    movwf   GLCD_counter, A
    movf    page_coord, W, A
    movwf   clear_page, A
    movf    y_coord, W, A
    movwf   clear_y, A
    call    GLCD_Clear_Area
    return  
    
GLCD_Clear_Cactus_Medium:
    movlw   CACTUS_MEDIUM_H
    movwf   _sprite_h, A
    movlw   CACTUS_MEDIUM_L
    movwf   _sprite_l, A
    movlw   CACTUS_MEDIUM_SIZE
    movwf   GLCD_counter, A
    movf    page_coord, W, A
    movwf   clear_page, A
    movf    y_coord, W, A
    movwf   clear_y, A
    call    GLCD_Clear_Area
    return  
 
GLCD_Clear_Cactus_Small:
    movlw   CACTUS_SMALL_H
    movwf   _sprite_h, A
    movlw   CACTUS_SMALL_L
    movwf   _sprite_l, A
    movlw   CACTUS_SMALL_SIZE
    movwf   GLCD_counter, A
    movf    page_coord, W, A
    movwf   clear_page, A
    movf    y_coord, W, A
    movwf   clear_y, A
    call    GLCD_Clear_Area
    return 

GLCD_Clear_Bird1:
    movlw   BIRD1_H
    movwf   _sprite_h, A
    movlw   BIRD1_L
    movwf   _sprite_l, A
    movlw   BIRD1_SIZE
    movwf   GLCD_counter, A
    movf    page_coord, W, A
    movwf   clear_page, A
    movf    y_coord, W, A
    movwf   clear_y, A
    call    GLCD_Clear_Area
    return 
    
GLCD_Clear_Bird2:
    movlw   BIRD2_H
    movwf   _sprite_h, A
    movlw   BIRD2_L
    movwf   _sprite_l, A
    movlw   BIRD2_SIZE
    movwf   GLCD_counter, A
    movf    page_coord, W, A
    movwf   clear_page, A
    movf    y_coord, W, A
    movwf   clear_y, A
    call    GLCD_Clear_Area
    return 
    
 GLCD_Clear_Area:
    ; Parameters:
    ; - WREG (H): Height in pages
    ; - PRODL (L): Width in pixels
    ; - PRODH (size): Total size in bytes
    ; - TBLPTR (data): Pointer to sprite data
    ; - GLCD_pg: Starting page
    ; - y_add: Y position
    
    movf   _sprite_l, W, A
    movwf   GLCD_cnt_y, A
    movf    clear_page, W, A
    movwf   GLCD_cnt_pg, A
    
GLCD_Clear_Loop:
    movf    GLCD_cnt_y, W, A   ; Load GLCD_cnt_y into W
    subwf   clear_y, W, A        ; Compute W = y_add - GLCD_cnt_y
    call    GLCD_Set_CS

    movf    GLCD_cnt_pg, W, A
    call    GLCD_Set_Page
    movlw   0x00
    call    GLCD_Data
    
    decfsz  GLCD_counter, A
    bra	    _clear_loop2
    return
    
_clear_loop2:
    decfsz  GLCD_cnt_y, A
    bra	    GLCD_Clear_Loop
    
    incf    GLCD_cnt_pg, f, A
    
    movf    clear_y, W, A
    call    GLCD_Set_CS
    
    movf   _sprite_l, W, A
    movwf   GLCD_cnt_y, A
    
    movf    clear_page, W, A   
    addwf   _sprite_h, W, A
    ;decf    WREG, W, A
    cpfseq  GLCD_cnt_pg, A
    bra	    GLCD_Clear_Loop
    return
    
GLCD_Clear_Screen: 
    ; Enable CS1 and CS2 (Both Sides)
    bcf     LATB, GLCD_CS1, A  
    bcf     LATB, GLCD_CS2, A
    
    movlw   7
    movwf   GLCD_cnt_pg, A
_clr:
    movf    GLCD_cnt_pg, W, A
    call    GLCD_Clear_Page
    
    decfsz  GLCD_cnt_pg, A
    bra	    _clr
    
    movlw   0
    call    GLCD_Clear_Page
    return
    
GLCD_Clear_Page:
    call   GLCD_Set_Page

    movlw   0          ; Start from Column 0 (X=0)
    call    GLCD_Set_Y

    movlw   64         ; Fill all 64 Columns
    movwf   GLCD_cnt_y, A	    ; Y address counter

Column_Loop:
    movlw   0x00       ; All pixels OFF (Clear)
    call    GLCD_Data

    decfsz  GLCD_cnt_y, F, A
    bra     Column_Loop

    return

GLCD_Set_CS:    
    clrf    y_adjusted, A
    movwf   y_adjusted, A
    
    movlw   128
    cpfslt  y_adjusted, A        ; Skip next if y_adjusted < 128
    bra     GLCD_Disable_CS      ; If y_adjusted >= 128, turn off both CS1 and CS2
    
    movlw   64
    cpfslt  y_adjusted, A        ; Skip next if WREG < 64
    bra     GLCD_Use_CS2      ; If WREG >= 64, go to CS2

GLCD_Use_CS1:
    bcf     LATB, GLCD_CS1, A
    bsf     LATB, GLCD_CS2, A
    movf    y_adjusted, W, A
    call    GLCD_Set_Y        ; Directly set Y position
    return

GLCD_Use_CS2:
    bsf     LATB, GLCD_CS1, A
    bcf     LATB, GLCD_CS2, A
    movlw   64
    subwf   y_adjusted, W, A        ; Adjust WREG (W = W - 64) before calling GLCD_Set_Y
    call    GLCD_Set_Y
    return

GLCD_Disable_CS:
    bsf     LATB, GLCD_CS1, A
    bsf     LATB, GLCD_CS2, A   
    movf    y_adjusted, W, A
    call    GLCD_Set_Y        ; Directly set Y position
    return

GLCD_Read_Screen_UART:
    clrf    GLCD_cnt_pg, A
    ;clrf    LATD, A
    
Page_Loop_read:
    movf    GLCD_cnt_pg, W, A
    call    GLCD_Set_Page

    movlw   128
    movwf   GLCD_cnt_y, A
 
Column_Loop_read:
    movf    WREG, W, A
    call    GLCD_Set_CS
    call    GLCD_Read_Data
    movf    GLCD_tmp, W, A
    addlw   '0'
    call    UART_Transmit_Byte
    
    decfsz  GLCD_cnt_y, A
    bra	    Column_Loop_read
    
    incf    GLCD_cnt_pg, F, A
    movlw   8
    cpfslt  GLCD_cnt_pg, A
    bra	    Page_Loop_read
    
End_Read:
    ;clrf    LATD, A
    return

GLCD_Read_Data: 
    movlw   0xFF
    movwf   TRISD, A
    
    bsf	    LATB, GLCD_RS, A
    bsf	    LATB, GLCD_RW, A
    call    Enable_Pulse
    bsf	    LATB, GLCD_E, A
    movlw   1
    call    delay_x4us
    movf    PORTD, W, A
    movwf   GLCD_tmp, A
    bcf	    LATB, GLCD_E, A
    
    movlw   0x00
    movwf   TRISD, A
    return

 
Delay:
    movlw   0xFF
    movwf   0x20, A
D_Loop:
    decfsz  0X20, F, A
    goto    D_Loop
    return