; ------------------------------------------------------------
; Blastshaft - Text Handler definitions
; ------------------------------------------------------------

SCREEN_RAM = $0400
COLOR_RAM  = $D800

; Zero-page workspace
TextPtrLo  = $02
TextPtrHi  = $03

TextCol    = $04
TextRow    = $05
TextColor  = $06

ScreenPtrLo = $07
ScreenPtrHi = $08

ColorPtrLo = $09
ColorPtrHi = $0A
