; ------------------------------------------------------------
; Blastshaft - Text Handler
; ------------------------------------------------------------


; ------------------------------------------------------------
; Text_ClearScreen
;
; Clears all 1000 characters of screen RAM.
; Uses screen-code space ($20).
; ------------------------------------------------------------

Text_ClearScreen:

    lda #$20

    ldx #$00

.clearLoop:

    sta SCREEN_RAM,x
    sta SCREEN_RAM+$0100,x
    sta SCREEN_RAM+$0200,x

    ; Last page only needs 232 bytes,
    ; but writing 256 here is harmless for this early test.
    sta SCREEN_RAM+$0300,x

    inx
    bne .clearLoop

    rts


; ------------------------------------------------------------
; Text_SetPosition
;
; Calculates:
;
; SCREEN_RAM + (row * 40) + column
; COLOR_RAM  + (row * 40) + column
;
; Input:
;   TextRow
;   TextCol
;
; Output:
;   ScreenPtrLo/Hi
;   ColorPtrLo/Hi
; ------------------------------------------------------------

Text_SetPosition:

    lda #<SCREEN_RAM
    sta ScreenPtrLo

    lda #>SCREEN_RAM
    sta ScreenPtrHi

    ldx TextRow

.rowLoop:

    cpx #$00
    beq .addColumn

    clc

    lda ScreenPtrLo
    adc #40
    sta ScreenPtrLo

    lda ScreenPtrHi
    adc #0
    sta ScreenPtrHi

    dex
    jmp .rowLoop


.addColumn:

    clc

    lda ScreenPtrLo
    adc TextCol
    sta ScreenPtrLo

    lda ScreenPtrHi
    adc #0
    sta ScreenPtrHi


    ; Color RAM has identical layout.
    lda ScreenPtrLo
    sta ColorPtrLo

    lda ScreenPtrHi
    clc
    adc #$D4
    sta ColorPtrHi

    rts


; ------------------------------------------------------------
; Text_PrintAt
;
; Prints a zero-terminated screen-code string.
;
; Requires:
;   TextPtrLo/Hi = string address
;   TextRow
;   TextCol
;   TextColor
;
; ------------------------------------------------------------

Text_PrintAt:

    jsr Text_SetPosition

    ldy #$00

.printLoop:

    lda (TextPtrLo),y

    beq .done

    sta (ScreenPtrLo),y

    lda TextColor
    sta (ColorPtrLo),y

    iny

    bne .printLoop

.done:

    rts
    