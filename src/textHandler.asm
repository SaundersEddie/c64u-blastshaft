; ============================================================
; BLASTSHAFT - TEXT HANDLER
; ============================================================


; ============================================================
; CLEAR SCREEN
; ============================================================

Text_ClearScreen:

    lda #$20
    ldx #0

TextClearLoop:

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
; Screen address =
;
; $0400 + (TextRow * 40) + TextColumn
; ============================================================

Text_CalculateScreenPosition:

    lda #<SCREEN_RAM
    sta ScreenPtrLo

    lda #>SCREEN_RAM
    sta ScreenPtrHi

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

    clc

    lda ScreenPtrLo
    adc TextColumn
    sta ScreenPtrLo

    lda ScreenPtrHi
    adc #0
    sta ScreenPtrHi

    rts


; ============================================================
; CONVERT SCREEN POINTER TO COLOR POINTER
; ============================================================

Text_ConvertPointerToColor:

    clc

    lda ScreenPtrHi
    adc #$D4
    sta ScreenPtrHi

    rts


; ============================================================
; PRINT TEXT
;
; TextPtrLo / TextPtrHi = zero terminated screen-code string
; TextColumn             = screen column
; TextRow                = screen row
; TextColor              = color
; ============================================================

Text_PrintAt:

    jsr Text_CalculateScreenPosition

    ldy #0

TextPrintCharacterLoop:

    lda (TextPtrLo),y
    beq TextPrintCharactersDone

    sta (ScreenPtrLo),y

    iny
    bne TextPrintCharacterLoop


TextPrintCharactersDone:

    jsr Text_CalculateScreenPosition
    jsr Text_ConvertPointerToColor

    ldy #0

TextPrintColorLoop:

    lda (TextPtrLo),y
    beq TextPrintDone

    lda TextColor
    sta (ScreenPtrLo),y

    iny
    bne TextPrintColorLoop


TextPrintDone:

    rts


; ============================================================
; ERASE TEXT
; ============================================================

Text_EraseAt:

    jsr Text_CalculateScreenPosition

    ldy #0

TextEraseLoop:

    lda (TextPtrLo),y
    beq TextEraseDone

    lda #$20
    sta (ScreenPtrLo),y

    iny
    bne TextEraseLoop


TextEraseDone:

    rts


; ============================================================
; COLOR UPDATE
; ============================================================

Text_UpdateColor:

    lda TextColorMode

    cmp #TEXT_COLOR_CYCLE
    beq Text_UpdateColorCycle

    rts


Text_UpdateColorCycle:

    inc TextColor

    lda TextColor
    and #$0F
    sta TextColor

    bne TextColorCycleDone

    lda #1
    sta TextColor


TextColorCycleDone:

    rts


; ============================================================
; HORIZONTAL BOUNCE
; ============================================================

Text_UpdateBounceX:

    lda TextDirectionX
    cmp #TEXT_DIR_RIGHT
    beq TextMoveRight


TextMoveLeft:

    lda TextColumn
    cmp #TEXT_MIN_COL
    beq TextChangeDirectionRight

    dec TextColumn
    rts


TextChangeDirectionRight:

    lda #TEXT_DIR_RIGHT
    sta TextDirectionX

    inc TextColumn
    rts


TextMoveRight:

    lda TextColumn
    cmp #TEXT_MAX_COL
    beq TextChangeDirectionLeft

    inc TextColumn
    rts


TextChangeDirectionLeft:

    lda #TEXT_DIR_LEFT
    sta TextDirectionX

    dec TextColumn
    rts


; ============================================================
; VERTICAL BOUNCE
; ============================================================

Text_UpdateBounceY:

    lda TextDirectionY
    cmp #TEXT_DIR_DOWN
    beq TextMoveDown


TextMoveUp:

    lda TextRow
    cmp #TEXT_MIN_ROW
    beq TextChangeDirectionDown

    dec TextRow
    rts


TextChangeDirectionDown:

    lda #TEXT_DIR_DOWN
    sta TextDirectionY

    inc TextRow
    rts


TextMoveDown:

    lda TextRow
    cmp #TEXT_MAX_ROW
    beq TextChangeDirectionUp

    inc TextRow
    rts


TextChangeDirectionUp:

    lda #TEXT_DIR_UP
    sta TextDirectionY

    dec TextRow
    rts


; ============================================================
; SCROLL LEFT
;
; Shifts an entire 40-character row one position left.
; New characters enter at column 39.
; ============================================================

Text_UpdateScrollLeft:

    lda TextColumn
    pha

    lda #0
    sta TextColumn

    jsr Text_CalculateScreenPosition


    ; --------------------------------------------------------
    ; SHIFT SCREEN RAM LEFT
    ; --------------------------------------------------------

    ldy #0

TextScrollLeftScreenLoop:

    iny
    lda (ScreenPtrLo),y

    dey
    sta (ScreenPtrLo),y

    iny
    cpy #39
    bne TextScrollLeftScreenLoop


    ; --------------------------------------------------------
    ; FETCH NEXT CHARACTER
    ; --------------------------------------------------------

    ldy ScrollTextIndex

    lda ScrollText,y
    bne TextScrollLeftCharacterReady

    lda #0
    sta ScrollTextIndex

    tay
    lda ScrollText,y


TextScrollLeftCharacterReady:

    ldy #39
    sta (ScreenPtrLo),y


    ; --------------------------------------------------------
    ; COLOR RAM
    ; --------------------------------------------------------

    jsr Text_ConvertPointerToColor

    ldy #0

TextScrollLeftColorLoop:

    iny
    lda (ScreenPtrLo),y

    dey
    sta (ScreenPtrLo),y

    iny
    cpy #39
    bne TextScrollLeftColorLoop


    ; --------------------------------------------------------
    ; NEW CHARACTER COLOR
    ; --------------------------------------------------------

    ldy #39

    lda TextColorMode
    cmp #TEXT_COLOR_RAINBOW
    beq TextScrollLeftRainbow

    lda TextColor
    jmp TextScrollLeftWriteColor


TextScrollLeftRainbow:

    lda ScrollColor


TextScrollLeftWriteColor:

    sta (ScreenPtrLo),y


    ; --------------------------------------------------------
    ; ADVANCE RAINBOW COLOR
    ; --------------------------------------------------------

    lda TextColorMode
    cmp #TEXT_COLOR_RAINBOW
    bne TextScrollLeftColorDone

    jsr Text_AdvanceScrollColor


TextScrollLeftColorDone:

    inc ScrollTextIndex

    pla
    sta TextColumn

    rts


; ============================================================
; SCROLL RIGHT
;
; Shifts an entire row right.
;
; ScrollRightText is stored backwards so that the visible
; message reads correctly while entering from the left.
; ============================================================

Text_UpdateScrollRight:

    lda TextColumn
    pha

    lda #0
    sta TextColumn

    jsr Text_CalculateScreenPosition


    ; --------------------------------------------------------
    ; SHIFT SCREEN RAM RIGHT
    ; --------------------------------------------------------

    ldy #38

TextScrollRightScreenLoop:

    lda (ScreenPtrLo),y

    iny
    sta (ScreenPtrLo),y

    dey
    dey

    bpl TextScrollRightScreenLoop


    ; --------------------------------------------------------
    ; FETCH NEXT CHARACTER
    ; --------------------------------------------------------

    ldy ScrollRightTextIndex

    lda ScrollRightText,y
    bne TextScrollRightCharacterReady

    lda #0
    sta ScrollRightTextIndex

    tay
    lda ScrollRightText,y


TextScrollRightCharacterReady:

    ldy #0
    sta (ScreenPtrLo),y


    ; --------------------------------------------------------
    ; SHIFT COLOR RAM RIGHT
    ; --------------------------------------------------------

    jsr Text_ConvertPointerToColor

    ldy #38

TextScrollRightColorLoop:

    lda (ScreenPtrLo),y

    iny
    sta (ScreenPtrLo),y

    dey
    dey

    bpl TextScrollRightColorLoop


    ; --------------------------------------------------------
    ; NEW CHARACTER COLOR
    ; --------------------------------------------------------

    ldy #0

    lda TextColorMode
    cmp #TEXT_COLOR_RAINBOW
    beq TextScrollRightRainbow

    lda TextColor
    jmp TextScrollRightWriteColor


TextScrollRightRainbow:

    lda ScrollColor


TextScrollRightWriteColor:

    sta (ScreenPtrLo),y


    lda TextColorMode
    cmp #TEXT_COLOR_RAINBOW
    bne TextScrollRightColorDone

    jsr Text_AdvanceScrollColor


TextScrollRightColorDone:

    inc ScrollRightTextIndex

    pla
    sta TextColumn

    rts


; ============================================================
; ADVANCE SCROLLER COLOR
; ============================================================

Text_AdvanceScrollColor:

    inc ScrollColor

    lda ScrollColor
    and #$0F
    sta ScrollColor

    bne TextAdvanceScrollColorDone

    lda #1
    sta ScrollColor


TextAdvanceScrollColorDone:

    rts


; ============================================================
; CHUNKY SINE
;
; Each character is placed on its own screen row according
; to SineTable.
;
; This is intentionally CHARACTER CELL movement.
;
; Smooth pixel sine comes later.
; ============================================================

Text_EraseSine:

    lda #0
    sta SineCharacterIndex


TextEraseSineLoop:

    ldy SineCharacterIndex

    lda (TextPtrLo),y
    beq TextEraseSineDone

    jsr Text_SetSineCharacterPosition

    jsr Text_CalculateScreenPosition

    ldy #0

    lda #$20
    sta (ScreenPtrLo),y

    inc SineCharacterIndex
    jmp TextEraseSineLoop


TextEraseSineDone:

    rts

; ============================================================
; DRAW CHUNKY SINE
; ============================================================

Text_DrawSine:

    lda #0
    sta SineCharacterIndex

TextDrawSineLoop:

    ldy SineCharacterIndex

    lda (TextPtrLo),y
    beq TextDrawSineDone

    sta SineCharacterValue

    jsr Text_SetSineCharacterPosition
    jsr Text_CalculateScreenPosition

    ldy #0

    lda SineCharacterValue
    sta (ScreenPtrLo),y

    ; --------------------------------------------------------
    ; DRAW CHARACTER COLOR
    ; --------------------------------------------------------

    jsr Text_CalculateScreenPosition
    jsr Text_ConvertPointerToColor

    ldy #0

    lda TextColorMode
    cmp #TEXT_COLOR_RAINBOW
    beq TextDrawSineRainbow

    lda TextColor
    jmp TextDrawSineWriteColor

TextDrawSineRainbow:

    lda SineCharacterIndex
    clc
    adc ScrollColor
    and #$0F

    bne TextDrawSineWriteColor

    lda #1

TextDrawSineWriteColor:

    sta (ScreenPtrLo),y

    inc SineCharacterIndex
    jmp TextDrawSineLoop

TextDrawSineDone:

    rts

; ============================================================
; CALCULATE POSITION OF CURRENT SINE CHARACTER
;
; TextColumn = SineBaseColumn + character index
; TextRow    = SineBaseRow + table offset
; ============================================================

Text_SetSineCharacterPosition:

    lda SineBaseColumn
    clc
    adc SineCharacterIndex
    sta TextColumn


    lda SinePhase
    clc
    adc SineCharacterIndex
    and #$0F

    tay

    lda SineTable,y
    clc
    adc SineBaseRow
    sta TextRow

    rts

; ============================================================
; ADVANCE SINE PHASE
; ============================================================

Text_UpdateSinePhase:

    inc SinePhase

    lda SinePhase
    and #$0F
    sta SinePhase

    rts