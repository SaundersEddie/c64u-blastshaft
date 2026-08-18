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
; $FB-$FE are being used by our text routines.
; ------------------------------------------------------------

TextPtrLo           = $FB
TextPtrHi           = $FC

ScreenPtrLo         = $FD
ScreenPtrHi         = $FE


; ------------------------------------------------------------
; TEXT MOVEMENT CONSTANTS
; ------------------------------------------------------------

TEXT_DIR_RIGHT      = 0
TEXT_DIR_LEFT       = 1

TEXT_MIN_COL        = 2
TEXT_MAX_COL        = 28


; ------------------------------------------------------------
; FRAME TIMING CONSTANTS
; ------------------------------------------------------------

TEXT_UPDATE_DELAY   = 6

; Raster line used for screen updates.
RASTER_UPDATE_LINE  = 250

; ------------------------------------------------------------
; TEXT MOVEMENT MODES
; ------------------------------------------------------------

TEXT_MODE_BOUNCE_X      = 0
TEXT_MODE_SCROLL_LEFT   = 1