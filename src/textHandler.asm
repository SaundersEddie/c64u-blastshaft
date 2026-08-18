; ============================================================
; BLASTSHAFT - TEXT HANDLER
; ============================================================



; ============================================================
; CLEAR SCREEN
; ============================================================

Text_ClearScreen:

    ; --------------------------------------------------------
    ; Screen-code $20 is a space.
    ; --------------------------------------------------------

    lda #$20
    ldx #0


TextClearLoop:

    ; --------------------------------------------------------
    ; Clear all four 256-byte pages of screen RAM.
    ;
    ; Screen RAM occupies $0400-$07FF.
    ; --------------------------------------------------------

    sta SCREEN_RAM+$000,x
    sta SCREEN_RAM+$100,x
    sta SCREEN_RAM+$200,x
    sta SCREEN_RAM+$300,x

    inx
    bne TextClearLoop

    rts



; ============================================================
; CALCULATE SCREEN POSITION
;
; Converts:
;
;     TextRow
;     TextColumn
;
; into:
;
;     ScreenPtrLo
;     ScreenPtrHi
;
; Screen address =
;
;     $0400 + (row * 40) + column
; ============================================================

Text_CalculateScreenPosition:

    ; --------------------------------------------------------
    ; Start pointer at beginning of screen RAM.
    ; --------------------------------------------------------

    lda #<SCREEN_RAM
    sta ScreenPtrLo

    lda #>SCREEN_RAM
    sta ScreenPtrHi


    ; --------------------------------------------------------
    ; Add 40 bytes once for every row.
    ; --------------------------------------------------------

    ldx TextRow


TextCalculateRowLoop:

    cpx #0
    beq TextCalculateColumn

    clc

    lda ScreenPtrLo
    adc #40
    sta ScreenPtrLo

    lda ScreenPtrHi
    adc #0
    sta ScreenPtrHi

    dex

    jmp TextCalculateRowLoop



TextCalculateColumn:

    ; --------------------------------------------------------
    ; Add column number to calculated row address.
    ; --------------------------------------------------------

    clc

    lda ScreenPtrLo
    adc TextColumn
    sta ScreenPtrLo

    lda ScreenPtrHi
    adc #0
    sta ScreenPtrHi

    rts



; ============================================================
; ERASE TEXT AT CURRENT POSITION
;
; Uses the current string length to replace each character
; with a space.
; ============================================================

Text_EraseAt:

    jsr Text_CalculateScreenPosition

    ldy #0


TextEraseLoop:

    ; --------------------------------------------------------
    ; Read character from source string.
    ; --------------------------------------------------------

    lda (TextPtrLo),y


    ; --------------------------------------------------------
    ; Zero marks end of string.
    ; --------------------------------------------------------

    beq TextEraseDone


    ; --------------------------------------------------------
    ; Replace corresponding screen character with a space.
    ; --------------------------------------------------------

    lda #$20
    sta (ScreenPtrLo),y

    iny

    jmp TextEraseLoop


TextEraseDone:

    rts



; ============================================================
; PRINT TEXT AT CURRENT POSITION
;
; First pass:
;     Write characters to screen RAM.
;
; Second pass:
;     Write matching colors to color RAM.
; ============================================================

Text_PrintAt:

    ; --------------------------------------------------------
    ; Calculate screen position.
    ; --------------------------------------------------------

    jsr Text_CalculateScreenPosition


    ; --------------------------------------------------------
    ; CHARACTER PASS
    ; --------------------------------------------------------

    ldy #0


TextPrintCharacterLoop:

    lda (TextPtrLo),y
    beq TextPrintCharactersDone

    sta (ScreenPtrLo),y

    iny

    jmp TextPrintCharacterLoop



TextPrintCharactersDone:

    ; --------------------------------------------------------
    ; Calculate the screen address again.
    ;
    ; We will convert this pointer into its corresponding
    ; color RAM address.
    ; --------------------------------------------------------

    jsr Text_CalculateScreenPosition


    ; --------------------------------------------------------
    ; Screen RAM begins at $0400.
    ; Color RAM begins at $D800.
    ;
    ; Difference:
    ;
    ;     $D800 - $0400 = $D400
    ;
    ; The low byte therefore remains unchanged.
    ; Add $D4 to the high byte.
    ; --------------------------------------------------------

    clc

    lda ScreenPtrHi
    adc #$D4
    sta ScreenPtrHi


    ; --------------------------------------------------------
    ; COLOR PASS
    ; --------------------------------------------------------

    ldy #0


TextPrintColorLoop:

    ; Read source string only so we know when to stop.

    lda (TextPtrLo),y
    beq TextPrintDone


    ; Write current color.

    lda TextColor
    sta (ScreenPtrLo),y

    iny

    jmp TextPrintColorLoop



TextPrintDone:

    rts
    