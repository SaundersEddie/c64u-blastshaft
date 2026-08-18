; ============================================================
; BLASTSHAFT
; C64U TEXT HANDLER PROOF OF CONCEPT
;
; Assembler: ACME
; ============================================================

!to "build/blastshaft.prg", cbm


; ============================================================
; BASIC LOADER
;
; 10 SYS 2064
; ============================================================

* = $0801

!byte $0C,$08
!byte $0A,$00
!byte $9E
!text "2064"
!byte $00
!byte $00,$00


; ============================================================
; PROGRAM START
; ============================================================

* = $0810

!source "src/textHandler.inc"


Start:


; ============================================================
; INITIALIZATION
; ============================================================

Initialization:

    ; --------------------------------------------------------
    ; No custom IRQ yet.
    ; Raster polling is used for this proof of concept.
    ; --------------------------------------------------------

    sei


    ; --------------------------------------------------------
    ; SCREEN COLORS
    ; --------------------------------------------------------

    lda #0
    sta BORDER_COLOR
    sta BACKGROUND_COLOR


    ; --------------------------------------------------------
    ; CLEAR SCREEN
    ; --------------------------------------------------------

    jsr Text_ClearScreen


    ; --------------------------------------------------------
    ; INITIAL TEXT POSITION
    ; --------------------------------------------------------

    lda #15
    sta TextColumn

    lda #10
    sta TextRow


    ; --------------------------------------------------------
    ; BOUNCE DIRECTIONS
    ; --------------------------------------------------------

    lda #TEXT_DIR_RIGHT
    sta TextDirectionX

    lda #TEXT_DIR_DOWN
    sta TextDirectionY


    ; --------------------------------------------------------
    ; TEXT COLOR
    ; --------------------------------------------------------

    lda #1
    sta TextColor

    lda #1
    sta ScrollColor


    ; --------------------------------------------------------
    ; FRAME COUNTER
    ; --------------------------------------------------------

    lda #0
    sta FrameCounter


    ; --------------------------------------------------------
    ; SCROLLER STATE
    ; --------------------------------------------------------

    lda #0
    sta ScrollTextIndex
    sta ScrollRightTextIndex


    ; --------------------------------------------------------
    ; SINE STATE
    ; --------------------------------------------------------

    lda #0
    sta SinePhase
    sta SineCharacterIndex

    lda #8
    sta SineBaseRow

    lda #14
    sta SineBaseColumn


    ; --------------------------------------------------------
    ; STRING POINTER
    ; --------------------------------------------------------

    lda #<BlastshaftText
    sta TextPtrLo

    lda #>BlastshaftText
    sta TextPtrHi


    ; --------------------------------------------------------
    ; INITIAL DRAW
    ;
    ; Sine draws itself differently, so don't use PrintAt
    ; for sine mode.
    ; --------------------------------------------------------

    lda TextMovementMode
    cmp #TEXT_MODE_SINE
    beq InitialDrawSine

    jsr Text_PrintAt
    jmp MainLoop


InitialDrawSine:

    jsr Text_DrawSine


; ============================================================
; MAIN LOOP
; ============================================================

MainLoop:

    jsr WaitForOffscreenUpdate

    inc FrameCounter

    lda FrameCounter
    cmp #TEXT_UPDATE_DELAY
    bcc MainLoop

    lda #0
    sta FrameCounter


; ============================================================
; OFF-SCREEN UPDATE
; ============================================================

OffscreenTextUpdate:

    jsr UpdateTextMovement

    jmp MainLoop


; ============================================================
; FRAME TIMING
; ============================================================

WaitForOffscreenUpdate:


WaitForUpdateRaster:

    lda RASTER_LINE
    cmp #RASTER_UPDATE_LINE
    bne WaitForUpdateRaster


WaitForUpdateRasterEnd:

    lda RASTER_LINE
    cmp #RASTER_UPDATE_LINE
    beq WaitForUpdateRasterEnd

    rts


; ============================================================
; MOVEMENT DISPATCHER
; ============================================================

UpdateTextMovement:

    lda TextMovementMode

    cmp #TEXT_MODE_STATIC
    beq RunTextStatic

    cmp #TEXT_MODE_BOUNCE_X
    beq RunTextBounceX

    cmp #TEXT_MODE_BOUNCE_Y
    beq RunTextBounceY

    cmp #TEXT_MODE_SCROLL_LEFT
    beq RunTextScrollLeft

    cmp #TEXT_MODE_SCROLL_RIGHT
    beq RunTextScrollRight

    cmp #TEXT_MODE_SINE
    beq RunTextSine

    rts


; ============================================================
; STATIC TEXT
; ============================================================

RunTextStatic:

    lda TextColorMode
    cmp #TEXT_COLOR_CYCLE
    bne RunTextStaticDone

    jsr Text_EraseAt
    jsr Text_UpdateColor
    jsr Text_PrintAt


RunTextStaticDone:

    rts


; ============================================================
; HORIZONTAL BOUNCE
; ============================================================

RunTextBounceX:

    jsr Text_EraseAt

    jsr Text_UpdateBounceX
    jsr Text_UpdateColor

    jsr Text_PrintAt

    rts


; ============================================================
; VERTICAL BOUNCE
; ============================================================

RunTextBounceY:

    jsr Text_EraseAt

    jsr Text_UpdateBounceY
    jsr Text_UpdateColor

    jsr Text_PrintAt

    rts


; ============================================================
; SCROLL LEFT
; ============================================================

RunTextScrollLeft:

    jsr Text_UpdateColor
    jsr Text_UpdateScrollLeft

    rts


; ============================================================
; SCROLL RIGHT
; ============================================================

RunTextScrollRight:

    jsr Text_UpdateColor
    jsr Text_UpdateScrollRight

    rts


; ============================================================
; SINE
; ============================================================

RunTextSine:

    jsr Text_EraseSine

    jsr Text_UpdateSinePhase
    jsr Text_UpdateColor

    jsr Text_DrawSine

    rts


; ============================================================
; TEXT HANDLER
; ============================================================

!source "src/textHandler.asm"


; ============================================================
; PROGRAM DATA
; ============================================================

BlastshaftText:

    !scr "blastshaft"
    !byte 0


; ------------------------------------------------------------
; LEFT SCROLLER
; ------------------------------------------------------------

ScrollText:

    !scr "blastshaft   "
    !byte 0


; ------------------------------------------------------------
; RIGHT SCROLLER
;
; Stored backwards because characters enter from the left.
; ------------------------------------------------------------

ScrollRightText:

    !scr "   tfahstsalb"
    !byte 0


; ------------------------------------------------------------
; CHUNKY SINE TABLE
;
; Offsets are added to SineBaseRow.
; ------------------------------------------------------------

SineTable:

    !byte 2,3,4,5
    !byte 4,3,2,1
    !byte 0,1,2,3
    !byte 4,3,2,1


; ============================================================
; PROGRAM VARIABLES
; ============================================================

TextColumn:
    !byte 15

TextRow:
    !byte 10


TextDirectionX:
    !byte TEXT_DIR_RIGHT

TextDirectionY:
    !byte TEXT_DIR_DOWN


TextColor:
    !byte 1

ScrollColor:
    !byte 1


FrameCounter:
    !byte 0


ScrollTextIndex:
    !byte 0

ScrollRightTextIndex:
    !byte 0


SinePhase:
    !byte 0

SineCharacterIndex:
    !byte 0

SineCharacterValue:
    !byte 0

SineBaseRow:
    !byte 8

SineBaseColumn:
    !byte 14

; ============================================================
; TEXT HANDLER TEST CONFIGURATION
;
; THIS IS THE SECTION TO CHANGE WHEN TESTING.
; ============================================================

TextMovementMode:
    !byte TEXT_MODE_SINE

TextColorMode:
    !byte TEXT_COLOR_CYCLE
