; ============================================================
; BLASTSHAFT - TEXT HANDLER DEFINITIONS
; ============================================================


; ------------------------------------------------------------
; C64 MEMORY LOCATIONS
; ------------------------------------------------------------

SCREEN_RAM      = $0400
COLOR_RAM       = $D800

BORDER_COLOR    = $D020
BACKGROUND_COLOR = $D021

RASTER_LINE     = $D012


; ------------------------------------------------------------
; ZERO PAGE POINTERS
;
; $FB-$FE are being used by our text routines.
; ------------------------------------------------------------

TextPtrLo       = $FB
TextPtrHi       = $FC

ScreenPtrLo     = $FD
ScreenPtrHi     = $FE


; ------------------------------------------------------------
; TEXT MOVEMENT CONSTANTS
; ------------------------------------------------------------

TEXT_DIR_RIGHT  = 0
TEXT_DIR_LEFT   = 1

TEXT_MIN_COL    = 2
TEXT_MAX_COL    = 28

; ============================================================
; FRAME TIMING CONSTANTS
; ============================================================

RASTER_LINE         = $D012
RASTER_IRQ_ENABLE   = $D01A
RASTER_IRQ_STATUS   = $D019
VIC_CONTROL_1       = $D011

IRQ_VECTOR_LO       = $0314
IRQ_VECTOR_HI       = $0315

CIA1_IRQ_CONTROL    = $DC0D

TEXT_UPDATE_DELAY   = 6

; Raster line used for screen updates.
; Keep screen-memory changes down in the lower border rather
; than modifying visible text while the VIC is displaying it.

RASTER_UPDATE_LINE  = 250