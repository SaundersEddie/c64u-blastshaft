; ============================================================
; BLASTSHAFT
; C64U PROOF OF CONCEPT
;
; Assembler: ACME
; ============================================================

!to "build/blastshaft.prg", cbm


; ============================================================
; BASIC LOADER
;
; Creates:
;
; 10 SYS 2064
;
; Machine code begins at $0810.
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
    ; Disable normal maskable interrupts for this test.
    ;
    ; We are NOT installing our own IRQ yet.
    ;
    ; This prevents the normal KERNAL IRQ from interfering
    ; with the zero-page locations used by our text handler.
    ; --------------------------------------------------------

    sei


    ; --------------------------------------------------------
    ; Set border and background to black.
    ; --------------------------------------------------------

    lda #0
    sta BORDER_COLOR
    sta BACKGROUND_COLOR


    ; --------------------------------------------------------
    ; Clear screen.
    ; --------------------------------------------------------

    jsr Text_ClearScreen


    ; --------------------------------------------------------
    ; Initialize BLASTSHAFT text position.
    ; --------------------------------------------------------

    lda #15
    sta TextColumn

    lda #10
    sta TextRow


    ; --------------------------------------------------------
    ; Initialize movement direction.
    ;
    ; Start moving toward the right.
    ; --------------------------------------------------------

    lda #TEXT_DIR_RIGHT
    sta TextDirection


    ; --------------------------------------------------------
    ; Initialize text color.
    ;
    ; C64 color 1 = white.
    ; --------------------------------------------------------

    lda #1
    sta TextColor


    ; --------------------------------------------------------
    ; Initialize frame counter.
    ; --------------------------------------------------------

    lda #0
    sta FrameCounter


    ; --------------------------------------------------------
    ; Set pointer to the BLASTSHAFT text.
    ; --------------------------------------------------------

    lda #<BlastshaftText
    sta TextPtrLo

    lda #>BlastshaftText
    sta TextPtrHi


    ; --------------------------------------------------------
    ; Draw the initial text.
    ; --------------------------------------------------------

    jsr Text_PrintAt



; ============================================================
; MAIN LOOP
; ============================================================

MainLoop:

    ; --------------------------------------------------------
    ; Wait until the VIC is below the visible game area.
    ; --------------------------------------------------------

    jsr WaitForOffscreenUpdate


    ; --------------------------------------------------------
    ; Count video frames.
    ; --------------------------------------------------------

    inc FrameCounter


    ; --------------------------------------------------------
    ; Only move the text once every six frames.
    ;
    ; We still synchronize every frame, but most frames require
    ; no screen-memory changes.
    ; --------------------------------------------------------

    lda FrameCounter
    cmp #6
    bcc MainLoop


    ; --------------------------------------------------------
    ; Reset movement timer.
    ; --------------------------------------------------------

    lda #0
    sta FrameCounter

; ============================================================
; OFF-SCREEN TEXT UPDATE
;
; The VIC is now below the main visible display.
;
; Select and run the active text movement mode.
; ============================================================

OffscreenTextUpdate:

    jsr UpdateTextMovement

    jmp MainLoop

; ============================================================
; FRAME TIMING
; ============================================================

; ============================================================
; WAIT FOR OFF-SCREEN UPDATE AREA
;
; Wait until the VIC reaches our selected lower-border
; raster line.
;
; Screen changes are performed immediately after this routine
; returns, keeping erase/update/redraw work away from the
; main visible display area.
; ============================================================

WaitForOffscreenUpdate:

WaitForUpdateRaster:

    lda RASTER_LINE
    cmp #RASTER_UPDATE_LINE
    bne WaitForUpdateRaster


    ; --------------------------------------------------------
    ; Wait until the VIC leaves the selected raster line.
    ;
    ; This guarantees one detection per video frame.
    ; --------------------------------------------------------

WaitForUpdateRasterEnd:

    lda RASTER_LINE
    cmp #RASTER_UPDATE_LINE
    beq WaitForUpdateRasterEnd

    rts

; ============================================================
; TEXT MOVEMENT DISPATCHER
;
; Reads TextMovementMode and calls the matching movement
; routine.
;
; Current modes:
;
;   TEXT_MODE_BOUNCE_X
;   TEXT_MODE_SCROLL_LEFT
; ============================================================

UpdateTextMovement:

    lda TextMovementMode

    cmp #TEXT_MODE_BOUNCE_X
    beq RunTextBounceX

    cmp #TEXT_MODE_SCROLL_LEFT
    beq RunTextScrollLeft

    ; Unknown mode - do nothing.

    rts


RunTextBounceX:

    ; --------------------------------------------------------
    ; Bounce mode works by erasing the old string,
    ; changing its position and color, then redrawing it.
    ; --------------------------------------------------------

    jsr Text_EraseAt
    jsr UpdateTextBounceX
    jsr UpdateTextColor
    jsr Text_PrintAt

    rts


RunTextScrollLeft:

    ; --------------------------------------------------------
    ; Scroll mode shifts an entire character row and its
    ; matching Color RAM one position left.
    ; --------------------------------------------------------

    jsr UpdateTextScrollLeft

    rts


; ============================================================
; TEXT SCROLL LEFT
;
; Shifts one complete 40-character screen row left by one
; character position.
;
; Screen RAM and Color RAM are shifted together.
;
; A new character from ScrollText is inserted at column 39.
; The new character uses TextColor.
;
; ScrollText is zero terminated. When the terminator is
; reached, ScrollTextIndex returns to zero and the message
; begins again.
; ============================================================

UpdateTextScrollLeft:

    ; --------------------------------------------------------
    ; Calculate address of column 0 on the scrolling row.
    ;
    ; Text_CalculateScreenPosition uses TextColumn, so save
    ; the current value before temporarily setting it to zero.
    ; --------------------------------------------------------

    lda TextColumn
    pha

    lda #0
    sta TextColumn

    jsr Text_CalculateScreenPosition


    ; --------------------------------------------------------
    ; SHIFT SCREEN RAM LEFT
    ;
    ; column 1  -> column 0
    ; column 2  -> column 1
    ; ...
    ; column 39 -> column 38
    ; --------------------------------------------------------

    ldy #0


ScrollLeftCharacterLoop:

    iny
    lda (ScreenPtrLo),y

    dey
    sta (ScreenPtrLo),y

    iny
    cpy #39
    bne ScrollLeftCharacterLoop


    ; --------------------------------------------------------
    ; Get next character from scrolling text.
    ; --------------------------------------------------------

    ldy ScrollTextIndex

    lda ScrollText,y

    ; Zero means end of message.

    bne ScrollLeftCharacterReady


    ; --------------------------------------------------------
    ; Restart message from beginning.
    ; --------------------------------------------------------

    lda #0
    sta ScrollTextIndex

    tay

    lda ScrollText,y

ScrollLeftCharacterReady:

    ; --------------------------------------------------------
    ; Put new character into column 39 of SCREEN RAM.
    ;
    ; A currently contains the character from ScrollText.
    ; --------------------------------------------------------

    ldy #39
    sta (ScreenPtrLo),y


    ; --------------------------------------------------------
    ; Convert screen pointer into matching COLOR RAM pointer.
    ;
    ; $D800 - $0400 = $D400
    ; --------------------------------------------------------

    clc

    lda ScreenPtrHi
    adc #$D4
    sta ScreenPtrHi


    ; --------------------------------------------------------
    ; SHIFT COLOR RAM LEFT
    ;
    ; column 1  -> column 0
    ; column 2  -> column 1
    ; ...
    ; column 39 -> column 38
    ; --------------------------------------------------------

    ldy #0

ScrollLeftColorLoop:

    iny
    lda (ScreenPtrLo),y

    dey
    sta (ScreenPtrLo),y

    iny
    cpy #39
    bne ScrollLeftColorLoop


    ; --------------------------------------------------------
    ; Set color for newly inserted character.
    ; --------------------------------------------------------

    ldy #39

    lda ScrollColor
    sta (ScreenPtrLo),y


    ; --------------------------------------------------------
    ; Advance scroll color.
    ;
    ; Keep color in range 1-15.
    ; Zero/black is skipped because background is black.
    ; --------------------------------------------------------

    inc ScrollColor

    lda ScrollColor
    and #$0F
    sta ScrollColor

    bne ScrollColorDone

    lda #1
    sta ScrollColor


ScrollColorDone:

    ; --------------------------------------------------------
    ; Advance scrolling message position.
    ; --------------------------------------------------------

    inc ScrollTextIndex


    ; --------------------------------------------------------
    ; Restore original TextColumn value.
    ; --------------------------------------------------------

    pla
    sta TextColumn

    rts

; ============================================================
; TEXT MOVEMENT UPDATE
; ============================================================

UpdateTextBounceX:

    ; --------------------------------------------------------
    ; Check current direction.
    ; --------------------------------------------------------

    lda TextDirection
    cmp #TEXT_DIR_RIGHT
    beq MoveTextRight



; ------------------------------------------------------------
; MOVE TEXT LEFT
; ------------------------------------------------------------

MoveTextLeft:

    ; Have we reached the left boundary?

    lda TextColumn
    cmp #TEXT_MIN_COL
    beq ChangeDirectionRight


    ; No.
    ; Move one character column left.

    dec TextColumn
    rts



; ------------------------------------------------------------
; CHANGE DIRECTION TO RIGHT
; ------------------------------------------------------------

ChangeDirectionRight:

    lda #TEXT_DIR_RIGHT
    sta TextDirection

    inc TextColumn

    rts



; ------------------------------------------------------------
; MOVE TEXT RIGHT
; ------------------------------------------------------------

MoveTextRight:

    ; Have we reached the right boundary?

    lda TextColumn
    cmp #TEXT_MAX_COL
    beq ChangeDirectionLeft


    ; No.
    ; Move one character column right.

    inc TextColumn
    rts



; ------------------------------------------------------------
; CHANGE DIRECTION TO LEFT
; ------------------------------------------------------------

ChangeDirectionLeft:

    lda #TEXT_DIR_LEFT
    sta TextDirection

    dec TextColumn

    rts



; ============================================================
; TEXT COLOR UPDATE
; ============================================================

UpdateTextColor:

    ; --------------------------------------------------------
    ; Advance to the next C64 color.
    ; --------------------------------------------------------

    inc TextColor


    ; --------------------------------------------------------
    ; C64 colors are 0-15.
    ;
    ; Mask off everything above the lower four bits.
    ; --------------------------------------------------------

    lda TextColor
    and #$0F
    sta TextColor


    ; --------------------------------------------------------
    ; Avoid black because our background is black.
    ; --------------------------------------------------------

    bne TextColorDone

    lda #1
    sta TextColor


TextColorDone:

    rts



; ============================================================
; TEXT HANDLER ROUTINES
; ============================================================

!source "src/textHandler.asm"



; ============================================================
; PROGRAM DATA
; ============================================================

BlastshaftText:

    !scr "blastshaft"
    !byte 0


ScrollText:

    !scr "blastshaft   "
    !byte 0


; ============================================================
; PROGRAM VARIABLES
; ============================================================

TextColumn:
    !byte 15

TextRow:
    !byte 10

TextDirection:
    !byte TEXT_DIR_RIGHT

TextColor:
    !byte 1

FrameCounter:
    !byte 0

ScrollTextIndex:
    !byte 0

ScrollColor:
    !byte 1

TextMovementMode:
    // !byte TEXT_MODE_SCROLL_LEFT?
    !byte TEXT_MODE_BOUNCE_X