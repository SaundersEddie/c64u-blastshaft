; ============================================================
; BLASTSHAFT - TEXT HANDLER DEFINITIONS
; ============================================================

; ------------------------------------------------------------
; C64 MEMORY LOCATIONS
; ------------------------------------------------------------

SCREEN_RAM          = $0400
COLOR_RAM           = $D800
BORDER_COLOR        = $D020
BACKGROUND_COLOR    = $D021
RASTER_LINE         = $D012

; ------------------------------------------------------------
; ZERO PAGE POINTERS
;
; $FB-$FE are reserved for TextHandler.
; ------------------------------------------------------------

TextPtrLo           = $FB
TextPtrHi           = $FC

ScreenPtrLo         = $FD
ScreenPtrHi         = $FE

; ------------------------------------------------------------
; DIRECTION CONSTANTS
; ------------------------------------------------------------

TEXT_DIR_RIGHT      = 0
TEXT_DIR_LEFT       = 1

TEXT_DIR_DOWN       = 0
TEXT_DIR_UP         = 1

; ------------------------------------------------------------
; MOVEMENT MODES
; ------------------------------------------------------------

TEXT_MODE_STATIC        = 0
TEXT_MODE_BOUNCE_X      = 1
TEXT_MODE_BOUNCE_Y      = 2
TEXT_MODE_SCROLL_LEFT   = 3
TEXT_MODE_SCROLL_RIGHT  = 4
TEXT_MODE_SINE          = 5

; ------------------------------------------------------------
; COLOR MODES
; ------------------------------------------------------------

TEXT_COLOR_STATIC       = 0
TEXT_COLOR_CYCLE        = 1
TEXT_COLOR_RAINBOW      = 2

; ------------------------------------------------------------
; MOVEMENT LIMITS
; ------------------------------------------------------------

TEXT_MIN_COL        = 2
TEXT_MAX_COL        = 28

TEXT_MIN_ROW        = 3
TEXT_MAX_ROW        = 20

; ------------------------------------------------------------
; FRAME TIMING
; ------------------------------------------------------------

TEXT_UPDATE_DELAY   = 6
RASTER_UPDATE_LINE  = 250

VIC_CONTROL_1       = $D011
VIC_IRQ_STATUS      = $D019
VIC_IRQ_ENABLE      = $D01A

CIA1_IRQ_CONTROL    = $DC0D
CIA2_IRQ_CONTROL    = $DD0D

IRQ_VECTOR_LO       = $0314
IRQ_VECTOR_HI       = $0315