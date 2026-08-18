; ============================================================
; BLASTSHAFT
; C64U PROOF OF CONCEPT
;
; Assembler: ACME
; ============================================================

!to "blastshaft.prg", cbm


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
    ; Wait for the next video frame.
    ; --------------------------------------------------------

    jsr WaitForFrame


    ; --------------------------------------------------------
    ; Erase BLASTSHAFT at its CURRENT position.
    ;
    ; This must happen BEFORE changing TextColumn.
    ; --------------------------------------------------------

    jsr Text_EraseAt


    ; --------------------------------------------------------
    ; Update horizontal position.
    ; --------------------------------------------------------

    jsr UpdateTextBounceX


    ; --------------------------------------------------------
    ; Update text color.
    ; --------------------------------------------------------

    jsr UpdateTextColor


    ; --------------------------------------------------------
    ; Draw BLASTSHAFT at its NEW position.
    ; --------------------------------------------------------

    jsr Text_PrintAt


    ; --------------------------------------------------------
    ; Repeat forever.
    ; --------------------------------------------------------

    jmp MainLoop



; ============================================================
; FRAME TIMING
; ============================================================

WaitForFrame:

    ; --------------------------------------------------------
    ; Wait until raster reaches line 250.
    ; --------------------------------------------------------

WaitForRaster250:

    lda RASTER_LINE
    cmp #250
    bne WaitForRaster250


    ; --------------------------------------------------------
    ; Wait until raster leaves line 250.
    ;
    ; Without this second loop, the program could return and
    ; detect line 250 again during the same frame.
    ; --------------------------------------------------------

WaitForRaster250End:

    lda RASTER_LINE
    cmp #250
    beq WaitForRaster250End

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