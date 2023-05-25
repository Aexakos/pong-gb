INCLUDE "hardware.inc"

Section "header", ROM0[$100]
	
	jp Begin

	ds $150 - @, 0 ;Make room for header

	Begin:
		call WaitVBlank
		; Turn LCD off
		ld a, 0
		ld [rLCDC], a

		; Copy the menu tile data
		ld de, TilesTitle
		ld hl, $9000
		ld bc, TilesTitleEnd - TilesTitle
		call Memcopy
		
		; Copy the tilemap data
		ld de, TileMapTitle
		ld hl, $9800
		ld bc, TileMapTitleEnd - TileMapTitle
		call Memcopy

		; Turn the LCD on
		ld a, LCDCF_ON | LCDCF_BGON
		ld [rLCDC], a

		; Set background palette
		ld a, %11100100
		ld [rBGP], a

		ld a, 0
		ld [wFrameCounter], a

	TitleLoop:
		call WaitVBlank
		ld a, [wFrameCounter]
		inc a
		ld [wFrameCounter], a
		cp a, 100
		call z, BlinkText
		call GetKeys
		ld a, [wNewKeys]
		AND a, PADF_START
		jp z, TitleLoop
	
	NewGameSetup:
		ld a, 0
		ld [wFrameCounter], a
		ld a, %11100100
		ld [rBGP], a
		
	MainLoop:
		jp MainLoop

	; Wait for VBlank
	WaitVBlank:
		ld a, [rLY]
		cp 144
		jp c, WaitVBlank
		ret
	; Wait for not VBlank
	WaitNoVBlank:
		ld a, [rLY]
		cp 144
		jp nc, WaitNoVBlank
		ret

	; Copy data from one place to another
	; @param de: source
	; @param hl: destination
	; @param bc: byteCount
	Memcopy:
		ld a, [de]
		ld [hli], a
		inc de
		dec bc
		ld a, b
		or a, c
		jp nz, Memcopy
		ret
	
	; Get joypad input
	GetKeys:
		; Poll the action controller
		ld a, P1F_GET_BTN
		call .onenibble
		ld b, a

		; Poll the direction controller
		ld a, P1F_GET_DPAD
		call .onenibble
		swap a
		xor a, b
		ld b, a

		; Release the controller
		ld a, P1F_GET_NONE
		ldh [rP1], a

		; Combine with previous wCurKeys and wNewKeys
		ld a, [wCurKeys]
		xor a, b
		and a, b
		ld [wNewKeys], a
		ld a, b
		ld [wCurKeys], a
		ret

		.onenibble:
			ldh [rP1], a
			call .noop
			ldh a, [rP1]
			ldh a, [rP1]
			ldh a, [rP1]
			or a, $F0
		.noop:
			ret

	; Reset FrameCounter and change BGP 02<->01
	BlinkText:
		ld a, 0
		ld [wFrameCounter], a
		ld a, [rBGP]
		xor a, %00110000
		ld [rBGP], a
		ret

	TilesTitle:
		; Title Tiles
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `33100000
		dw `33100000
		dw `33100000
		dw `33100000
		dw `33100000
		dw `33100000
		dw `33100000
		dw `33100000
		dw `00000133
		dw `00000133
		dw `00000133
		dw `00000133
		dw `00000133
		dw `00000133
		dw `00000133
		dw `00000133
		dw `33333333
		dw `33333333
		dw `11111111
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `11111111
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33111111
		dw `33111110
		dw `33111100
		dw `33111000
		dw `33110000
		dw `33100000
		dw `33333333
		dw `33333333
		dw `11111133
		dw `01111133
		dw `00111133
		dw `00011133
		dw `00001133
		dw `00000133
		dw `33100000
		dw `33110000
		dw `33111000
		dw `33111100
		dw `33111110
		dw `33111111
		dw `33333333
		dw `33333333
		dw `00000133
		dw `00001133
		dw `00011133
		dw `00111133
		dw `01111133
		dw `11111133
		dw `33333333
		dw `33333333

		dw `33333300
		dw `31111130
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `33333310
		dw `31111100
		dw `31000000
		dw `31000000
		dw `31000000
		dw `31000000
		dw `31000000
		dw `10000000
		dw `03333300
		dw `31111130
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `03333311
		dw `00111110
		dw `30000030
		dw `33000031
		dw `31300031
		dw `31310031
		dw `31310031
		dw `31310031
		dw `31030031
		dw `31031031
		dw `31031031
		dw `31003031
		dw `31003131
		dw `31003131
		dw `31003131
		dw `31000331
		dw `31000031
		dw `10000010
		dw `03333330
		dw `31111100
		dw `31000000
		dw `31000000
		dw `31000000
		dw `31000000
		dw `31033300
		dw `31000030
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `31000031
		dw `13333310
		dw `01111100

		dw `02222000
		dw `02000200
		dw `02000200
		dw `02000200
		dw `02222000
		dw `02000000
		dw `02000000
		dw `02000000
		dw `00000000
		dw `00000000
		dw `02022000
		dw `02200200
		dw `02000000
		dw `02000000
		dw `02000000
		dw `02000000
		dw `00000000
		dw `00000000
		dw `02222200
		dw `02000200
		dw `02000200
		dw `02222200
		dw `02000000
		dw `02222200
		dw `00000000
		dw `00000000
		dw `00222200
		dw `02000000
		dw `02000000
		dw `02222200
		dw `00000200
		dw `02222200
		dw `00000000
		dw `00000000
		dw `00020000
		dw `02222200
		dw `00020000
		dw `00020000
		dw `00020200
		dw `00022200
		dw `00000000
		dw `00000000
		dw `00222000
		dw `02002000
		dw `02002000
		dw `02002000
		dw `02002000
		dw `00222200

	TilesTitleEnd:
	
	TilesMain:
		

	TilesMainEnd:

	TileMapTitle:
		db $05, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $06, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $09, $00, $0B, $00, $0D, $00, $0F, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $0A, $00, $0C, $00, $0E, $00, $10, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $11, $12, $13, $14, $14, $00, $00, $14, $15, $16, $12, $15, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $07, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $08, 0,0,0,0,0,0,0,0,0,0,0,0
	TileMapTitleEnd:

SECTION "Counter", WRAM0
wFrameCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db