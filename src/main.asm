; BLASTSHAFT
; C64U TEXT HANDLER PROOF OF CONCEPT
;
; Assembler: ACME
; ============================================================

!to "build/blastshaft.prg", cbm

SPRITE_ENABLE       = $D015
SPRITE_X_MSB        = $D010
SPRITE_PRIORITY     = $D01B

SPRITE_0_X          = $D000
SPRITE_0_Y          = $D001

SPRITE_POINTERS     = $07F8

SPRITE_DATA         = $2000
SPRITE_POINTER      = $80


; BASIC LOADER
; 10 SYS 2064
; ============================================================

* = $0801

!byte $0C,$08
!byte $0A,$00
!byte $9E
!text "2064"
!byte $00
!byte $00,$00

; PROGRAM START
; ============================================================

* = $0810
!source "src/textHandler.inc"

Start:
; INITIALIZATION
; ============================================================

Initialization:
    sei

    ; DISABLE CIA INTERRUPTS
    ; --------------------------------------------------------
    lda #$7F
    sta CIA1_IRQ_CONTROL
    sta CIA2_IRQ_CONTROL

    ; Clear pending CIA interrupts
    lda CIA1_IRQ_CONTROL
    lda CIA2_IRQ_CONTROL

    ; SET UP RASTER IRQ
    ; --------------------------------------------------------

    lda #RASTER_UPDATE_LINE
    sta RASTER_LINE

    ; Raster line is below 256
    lda VIC_CONTROL_1
    and #%01111111
    sta VIC_CONTROL_1

    ; Install IRQ vector
    lda #<RasterIRQ
    sta IRQ_VECTOR_LO

    lda #>RasterIRQ
    sta IRQ_VECTOR_HI

    ; Enable VIC raster IRQ
    lda #%00000001
    sta VIC_IRQ_ENABLE

    ; Clear any pending VIC IRQ
    lda #%00000001
    sta VIC_IRQ_STATUS

    ; SCREEN COLORS
    ; --------------------------------------------------------
    lda #0
    sta BORDER_COLOR
    sta BACKGROUND_COLOR

    ; CLEAR SCREEN
    ; --------------------------------------------------------
    jsr Text_ClearScreen

    ; INITIAL TEXT POSITION
    ; --------------------------------------------------------
    lda #15
    sta TextColumn

    lda #10
    sta TextRow

    ; BOUNCE DIRECTIONS
    ; --------------------------------------------------------
    lda #TEXT_DIR_RIGHT
    sta TextDirectionX

    lda #TEXT_DIR_DOWN
    sta TextDirectionY

    ; TEXT COLOR
    ; --------------------------------------------------------
    lda #1
    sta TextColor

    lda #1
    sta ScrollColor

    ; FRAME COUNTER
    ; --------------------------------------------------------

    lda #0
    sta FrameCounter

    ; SCROLLER STATE
    ; --------------------------------------------------------
    lda #0
    sta ScrollTextIndex
    sta ScrollRightTextIndex

    ; SINE STATE
    ; --------------------------------------------------------
    lda #0
    sta SinePhase
    sta SineCharacterIndex

    lda #8
    sta SineBaseRow

    lda #14
    sta SineBaseColumn

    ; STRING POINTER
    ; --------------------------------------------------------
    lda #<BlastshaftText
    sta TextPtrLo

    lda #>BlastshaftText
    sta TextPtrHi

    ; INITIAL DRAW
    ; --------------------------------------------------------
    lda TextMovementMode
    cmp #TEXT_MODE_SINE
    beq InitialDrawSine

    jsr Text_PrintAt
    jmp InitializationDone


InitialDrawSine:
    jsr Text_DrawSine

; STARFIELD
; --------------------------------------------------------
InitializeStarfield:
    jsr Starfield_Init

InitializationDone:
    cli

; MAIN LOOP
; ============================================================
MainLoop:
    jmp MainLoop

; RASTER IRQ
; ============================================================
RasterIRQ:
    lda #%00000001
    sta VIC_IRQ_STATUS

    ; Stars move every frame
    jsr Starfield_Update

    ; Text still uses its slower divider
    inc FrameCounter

    lda FrameCounter
    cmp #TEXT_UPDATE_DELAY
    bcc RasterIRQDone

    lda #0
    sta FrameCounter

    jsr UpdateTextMovement


RasterIRQDone:
    jmp $EA31

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

; HORIZONTAL BOUNCE
; ============================================================
RunTextBounceX:
    jsr Text_EraseAt

    jsr Text_UpdateBounceX
    jsr Text_UpdateColor

    jsr Text_PrintAt

    rts

; VERTICAL BOUNCE
; ============================================================
RunTextBounceY:
    jsr Text_EraseAt

    jsr Text_UpdateBounceY
    jsr Text_UpdateColor

    jsr Text_PrintAt

    rts

; SCROLL LEFT
; ============================================================
RunTextScrollLeft:
    jsr Text_UpdateColor
    jsr Text_UpdateScrollLeft

    rts

; SCROLL RIGHT
; ============================================================
RunTextScrollRight:
    jsr Text_UpdateColor
    jsr Text_UpdateScrollRight

    rts

; SINE
; ============================================================
RunTextSine:
    jsr Text_EraseSine

    jsr Text_UpdateSinePhase
    jsr Text_UpdateColor

    jsr Text_DrawSine

    rts

; STARFIELD INITIALIZATION
; ============================================================
Starfield_Init:
    ; --------------------------------------------------------
    ; COPY STAR GRAPHIC INTO SPRITE MEMORY
    ; --------------------------------------------------------

    ldx #0

Starfield_CopySprite:
    lda StarSpriteData,x
    sta SPRITE_DATA,x

    inx
    cpx #63
    bne Starfield_CopySprite

    ; ALL SPRITES USE SAME STAR GRAPHIC
    ; --------------------------------------------------------
    ldx #0

Starfield_SetPointers:
    lda #SPRITE_POINTER
    sta SPRITE_POINTERS,x

    inx
    cpx #8
    bne Starfield_SetPointers

    ; ENABLE ALL 8 SPRITES
    ; --------------------------------------------------------
    lda #%11111111
    sta SPRITE_ENABLE

    ; SPRITES BEHIND TEXT
    ; --------------------------------------------------------
    lda #%11111111
    sta SPRITE_PRIORITY

    ; INITIAL Y POSITIONS
    ; --------------------------------------------------------
    lda #70
    sta $D001

    lda #105
    sta $D003

    lda #140
    sta $D005

    lda #175
    sta $D007

    lda #85
    sta $D009

    lda #120
    sta $D00B

    lda #155
    sta $D00D

    lda #195
    sta $D00F

    ; INITIAL X MSB
    ; --------------------------------------------------------
    lda #0
    sta SPRITE_X_MSB

    ; INITIAL DRAW
    ; --------------------------------------------------------
    jsr Starfield_WritePositions

    rts

; STARFIELD UPDATE
; ============================================================
Starfield_Update:
    ldx #0


Starfield_UpdateLoop:
    ; Move star left
    sec

    lda StarXLo,x
    sbc StarSpeed,x
    sta StarXLo,x

    lda StarXHi,x
    sbc #0
    sta StarXHi,x

    ; If the 9-bit position underflowed,
    ; StarXHi will now be $FF.
    cmp #$FF
    bne Starfield_NoWrap

    ; Respawn at X = 343 ($0157)
    lda #$57
    sta StarXLo,x

    lda #$01
    sta StarXHi,x

Starfield_NoWrap:

    inx
    cpx #8
    bne Starfield_UpdateLoop

    jsr Starfield_WritePositions

    rts

; WRITE STAR POSITIONS TO VIC
; ============================================================
Starfield_WritePositions:
    lda #0
    sta SPRITE_X_MSB

    ldx #0

Starfield_WriteLoop:
    ldy SpriteXRegister,x

    lda StarXLo,x
    sta SPRITE_0_X,y

    lda StarXHi,x
    beq Starfield_NoMSB

    lda SPRITE_X_MSB
    ora SpriteBitMask,x
    sta SPRITE_X_MSB

Starfield_NoMSB:
    inx
    cpx #8
    bne Starfield_WriteLoop

    rts

; TEXT HANDLER
; ============================================================
!source "src/textHandler.asm"

; PROGRAM DATA
; ============================================================
BlastshaftText:
    !scr "blastshaft"
    !byte 0

; LEFT SCROLLER
; ------------------------------------------------------------
ScrollText:
    !scr "blastshaft   "
    !byte 0

; RIGHT SCROLLER
; Stored backwards because characters enter from the left.
; ------------------------------------------------------------
ScrollRightText:
    !scr "   tfahstsalb"
    !byte 0

; CHUNKY SINE TABLE
; Offsets are added to SineBaseRow.
; ------------------------------------------------------------
SineTable:
    !byte 2,3,4,5
    !byte 4,3,2,1
    !byte 0,1,2,3
    !byte 4,3,2,1

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

; TEXT HANDLER TEST CONFIGURATION
; THIS IS THE SECTION TO CHANGE WHEN TESTING.
; ============================================================
TextMovementMode:
    !byte TEXT_MODE_SINE

TextColorMode:
    !byte TEXT_COLOR_CYCLE

; STARFIELD DATA
; ============================================================

StarXLo:
    !byte 30,80,130,180
    !byte 230,20,100,200

StarXHi:
    !byte 0,0,0,0
    !byte 0,1,1,0

; Three apparent depth layers:
; far = 1
; middle = 2
; near = 3

StarSpeed:
    !byte 1,1,1
    !byte 2,2,2
    !byte 3,3

SpriteXRegister:
    !byte 0,2,4,6,8,10,12,14

SpriteBitMask:
    !byte %00000001
    !byte %00000010
    !byte %00000100
    !byte %00001000
    !byte %00010000
    !byte %00100000
    !byte %01000000
    !byte %10000000

StarSpriteData:
    ; 24 x 21 monochrome sprite
    ; tiny dot near the middle

    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$18,$00
    !byte $00,$18,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    !byte $00,$00,$00
    
