; ------------------------------------------------------------
; Blastshaft
; C64U proof-of-concept
; ------------------------------------------------------------

!to "blastshaft.prg", cbm


; ------------------------------------------------------------
; BASIC loader
;
; 10 SYS 2064
; ------------------------------------------------------------

* = $0801

!byte $0c,$08
!byte $0a,$00
!byte $9e
!text "2064"
!byte $00
!byte $00,$00


; ------------------------------------------------------------
; Machine code begins at $0810 / 2064
; ------------------------------------------------------------

* = $0810

!source "src/textHandler.inc"


Start:

    ; Border/background black

    lda #$00
    sta $D020
    sta $D021


    ; Clear screen ourselves

    jsr Text_ClearScreen


    ; --------------------------------------------------------
    ; BLASTSHAFT
    ; --------------------------------------------------------

    lda #15
    sta TextCol

    lda #8
    sta TextRow

    lda #1
    sta TextColor

    lda #<TitleText
    sta TextPtrLo

    lda #>TitleText
    sta TextPtrHi

    jsr Text_PrintAt


    ; --------------------------------------------------------
    ; Proof-of-concept line
    ; --------------------------------------------------------

    lda #8
    sta TextCol

    lda #12
    sta TextRow

    lda #7
    sta TextColor

    lda #<TestText
    sta TextPtrLo

    lda #>TestText
    sta TextPtrHi

    jsr Text_PrintAt


    ; --------------------------------------------------------
    ; Sit here forever.
    ;
    ; KERNAL is still mapped right now.
    ; We're just deliberately not using it for text.
    ; --------------------------------------------------------

.mainLoop:

    jmp .mainLoop


; ------------------------------------------------------------
; Strings
;
; !scr converts ASCII source text into C64 screen codes.
; ------------------------------------------------------------

TitleText:

    !scr "blastshaft"
    !byte 0


TestText:

    !scr "c64u text handler online"
    !byte 0


; ------------------------------------------------------------
; Handler implementation
; ------------------------------------------------------------

!source "src/textHandler.asm"
