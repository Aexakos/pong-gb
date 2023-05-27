INCLUDE "hardware.inc"

Section "header", ROM0[$100]
	
	jp Begin

	ds $150 - @, 0 ;Make room for header

	Begin:
		call WaitVBlank
		; Turn LCD off
		ld a, 0
		ld [rLCDC], a

		; Copy the title tile data
		ld de, TilesTitle
		ld hl, $9000
		ld bc, TilesTitleEnd - TilesTitle
		call Memcopy
		
		; Copy the title tilemap data
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
	
	ModeSelectSetup:
		call WaitVBlank

		ld a, 0
		ld [rLCDC], a

		ld de, TileMapModeSelect
		ld hl, $9800
		ld bc, TileMapModeSelectEnd - TileMapModeSelect
		call Memcopy

		ld de, TilesModeObject
		ld hl, $8000
		ld bc, TilesModeObjectEnd - TilesModeObject
		call Memcopy

		ld a, 0
		ld b, 160
		ld hl, _OAMRAM
		ClearOAM:
			ld [hli], a
			dec b
			jp nz, ClearOAM

		ld hl, _OAMRAM
		ld a, 56 + 16
		ld [hli], a
		ld a, 24 + 8
		ld [hli], a
		ld a, 0
		ld [hli], a
		ld [hl], a

		ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON
		ld [rLCDC], a

		ld a, %11110100
		ld [rBGP], a
		ld a, %11100100
		ld [rOBP0], a

		ld a, 0
		ld [wGameMode], a

	ModeSelectLoop:
		call WaitVBlank

		call GetKeys
		ld a, [wNewKeys]
		and a, PADF_UP
		jp z, CheckMultiSelect
		ld a, 56 + 16
		ld [_OAMRAM], a
		ld a, 0
		ld [wGameMode], a
		jp CheckNewGameStart

		CheckMultiSelect:
			ld a, [wNewKeys]
			and a, PADF_DOWN
			jp z, CheckNewGameStart
			ld a, 80 + 16
			ld [_OAMRAM], a
			ld a, 1
			ld [wGameMode], a

		CheckNewGameStart:
			ld a, [wNewKeys]
			and a, PADF_A
		jp z, ModeSelectLoop
	NewGameSetup:
		call WaitVBlank

		; Turn the LCD off
		ld a, 0
		ld [rLCDC], a

		; Copy the main game tile data
		ld de, TilesMain
		ld hl, $9000
		ld bc, TilesMainEnd - TilesMain
		call Memcopy
		
		; Copy the main game tilemap data
		ld de, TileMapMain
		ld hl, $9800
		ld bc, TileMapMainEnd - TileMapMain
		call Memcopy

		; Copy the object tile data
		ld de, TilesObject
		ld hl, $8000
		ld bc, TilesObjectEnd - TilesObject
		call Memcopy

		ld a, $E
		ld [$9848], a
		ld [$984B], a

		; Clear OAM
		ld a, 0
		ld b, 160
		ld hl, _OAMRAM
		ClearOAM1:
			ld [hli], a
			dec b
			jp nz, ClearOAM1

		;Initiate left paddle in OAM
		ld hl, _OAMRAM
		ld a, 64 + 16
		ld [hli], a
		ld a, 8
		ld [hli], a
		ld a, 0
		ld [hli], a
		ld [hli], a

		; Initiate right paddle in OAM
		ld a, 64 + 16
		ld [hli], a
		ld a, 152 + 8
		ld [hli], a
		ld a, 2
		ld [hli], a
		ld a, 0
		ld [hli], a
		
		; Initiate ball in OAM
		ld a, 68 + 16
		ld [hli], a
		ld a, 76 + 8
		ld [hli], a
		ld a, 4
		ld [hli], a
		ld a, 0
		ld [hli], a

		; Initiate ball speed
		ld a, -1
		ld [wBallVelocityX], a
		ld a, [wFrameCounter]   ; if(wFramCounter % 2 = 0)
		ld b, a					; {
		ld a, 1					;	BallVelocityY = -1;
		and a, b				; }
		jp z, Even				; else
		ld [wBallVelocityY], a  ; {
		jp Odd					;	BallVelocityY = 1;
		Even:					; }
			ld a, -1
			ld [wBallVelocityY], a
		Odd:

		; Turn the LCD on
		ld a, LCDCF_ON | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ16
		ld [rLCDC], a

		ld a, 0
		ld [wFrameCounter], a
		ld [wScoreCounter], a
		ld a, %11100100
		ld [rBGP], a
		ld a, %00100111
		ld [rOBP0], a		
	MainLoop:
		call WaitNoVBlank
		call WaitVBlank

		ld a, [wFrameCounter]
		inc a
		ld [wFrameCounter], a

		; Add ball velocity to its position
		ld a, [wBallVelocityX]
		ld b, a
		ld a, [_OAMRAM + 9]
		add a, b
		ld [_OAMRAM + 9], a

		ld a, [wBallVelocityY]
		ld b, a
		ld a, [_OAMRAM + 8]
		add a, b
		ld [_OAMRAM + 8], a


	    ; Checks ball collision and change velocityY 
		BounceTop:
			ld a, [_OAMRAM + 8]
			sub a, 16 - 3
			ld c, a
			ld a, [_OAMRAM + 9]
			sub a, 8
			ld b, a
			call GetTileByPixel
			ld a, [hl]
			call CheckTileCollision
			jp nz, BounceDown
			ld a, 1
			ld [wBallVelocityY], a	
		BounceDown:
			ld a, [_OAMRAM + 8]
			sub a, 16 - 4
			ld c, a
			ld a, [_OAMRAM + 9]
			sub a, 8
			ld b, a
			call GetTileByPixel
			ld a, [hl]
			call CheckTileCollision
			jp nz, BounceDone
			ld a, -1
			ld [wBallVelocityY], a	
		BounceDone:

		; Checks ball collision(w/paddle) and change velocity
		PaddleBounce:
			ld a, [_OAMRAM + 1]
			add a, 6
			ld b, a
			ld a, [_OAMRAM + 9]

			cp a, b
			jp nz, PaddleBounceR;if(paddleX + 6 = ballX)
			ld a, [_OAMRAM + 8]		;{
			ld b, a					;	//Compare Y
			ld a, [_OAMRAM]			;}

			add a, 14
			cp a, b
			jp c, PaddleBounceR  ;if(paddleY + 14 > ballY > paddleY -8)
			sub a, 22				;{
			cp a, b					;	PaddleBounceMid();
			jp nc, PaddleBounceR ;}

			add a, 8
			cp a, b
			jp nc, PaddleBounceBot	;if(paddleY + 6 > ballY > paddleY)
			add a, 6				;{
			cp a, b					;	ballVelocityX = 1;
			jp c, PaddleBounceBot	;	ballVelocityY = 0
			ld a, 1					;}
			ld [wBallVelocityX], a	;else
			ld a, 0					;{
			ld [wBallVelocityY], a	;	PaddleBounceBot();
			jp PaddleBounceR		;}

		PaddleBounceBot:
			cp a, b
			jp nc, PaddleBounceTop	;if(paddleY + 6 < ballY)
			ld a, 1					;{
			ld [wBallVelocityX], a	;	ballVelocityX = 1;
			ld [wBallVelocityY], a	;	ballVelocityY = -1;
									;}
			jp PaddleBounceR	;else
									;{
		PaddleBounceTop:			;	ballVelocityX = 1;
			ld a, 1					;	ballVelocityY = 1;
			ld [wBallVelocityX], a	;}	
			ld a, -1	
			ld [wBallVelocityY], a


		PaddleBounceR:
			ld a, [_OAMRAM + 5]
			sub a, 6
			ld b, a
			ld a, [_OAMRAM + 9]

			cp a, b
			jp nz, PaddleBounceDone
			ld a, [_OAMRAM + 8]
			ld b, a	
			ld a, [_OAMRAM + 4]			

			add a, 14
			cp a, b
			jp c, PaddleBounceDone
			sub a, 22
			cp a, b	
			jp nc, PaddleBounceDone

			add a, 8
			cp a, b
			jp nc, PaddleBounceBotR
			add a, 6
			cp a, b
			jp c, PaddleBounceBotR
			ld a, -1
			ld [wBallVelocityX], a
			ld a, 0
			ld [wBallVelocityY], a
			jp PaddleBounceDone

		PaddleBounceBotR:
			cp a, b
			jp nc, PaddleBounceTopR
			ld a, -1
			ld [wBallVelocityX], a
			ld a, 1
			ld [wBallVelocityY], a

			jp PaddleBounceDone

		PaddleBounceTopR:
			ld a, -1
			ld [wBallVelocityX], a
			ld a, -1	
			ld [wBallVelocityY], a			

		PaddleBounceDone:

		CheckScore:
			ld a, [_OAMRAM + 9]
			ld b, a
			ld a, -8 + 16
			cp a, b
			jp nz, CheckScoreR
			ld a, [wScoreCounter]
			add a, $1
			ld [wScoreCounter], a

			call WaitVBlank
			ld a, [wScoreCounter]
			and a, %1111
			add a, $4
			ld [$984B], a

			ld a, 68 + 16
			ld [_OAMRAM + 8], a
			ld a, 76 + 8
			ld [_OAMRAM + 9], a
			ld a, -1
			ld [wBallVelocityX], a
			ld a, 0
			ld [wBallVelocityY], a

			ld a, [wScoreCounter]
			and a, $A
			cp a, $A

			jp nz, CheckScoreEnd
			; Right paddle wins!
			ld a, 0
			ld [_OAMRAM], a
			ld [_OAMRAM + 8], a
			ld [wBallVelocityX], a
			ld [wBallVelocityY], a
			ld [wFrameCounter], a
			ld [wScoreCounter], a
			jp GameOverLoop

		CheckScoreR:
			ld a, 160 + 16
			cp a, b
			jp nz, CheckScoreEnd
			ld a, [wScoreCounter]
			add a, $10
			ld [wScoreCounter], a

			call WaitVBlank
			ld a, [wScoreCounter]
			swap a
			and a, %1111
			add a, $4
			ld [$9848], a

			ld a, 68 +16
			ld [_OAMRAM + 8], a
			ld a, 76 + 8
			ld [_OAMRAM + 9], a
			ld a, 1
			ld [wBallVelocityX], a
			ld a, 0
			ld [wBallVelocityY], a

			ld a, [wScoreCounter]
			and a, $A0
			cp a, $A0

			jp nz, CheckScoreEnd
			; Left paddle wins!
			ld a, 0
			ld [_OAMRAM+ 4], a
			ld [_OAMRAM + 8], a
			ld [wBallVelocityX], a
			ld [wBallVelocityY], a
			ld [wFrameCounter], a
			ld [wScoreCounter], a
			jp GameOverLoop

		CheckScoreEnd:

		ld a, [wFrameCounter]
		inc a
		ld [wFrameCounter], a

		; Check the keys every frame and move
		call GetKeys
		CheckUp:
			ld a, [wCurKeys]
			and a, PADF_UP
			jp z, CheckDown
		Up:
			ld a, [_OAMRAM]
			dec a
			dec a
			; If at edge of playfield, don't move
			cp a, 21
			jp c, CheckKeysR
			ld [_OAMRAM], a
		CheckDown:
			ld a, [wCurKeys]
			and a, PADF_DOWN
			jp z, CheckKeysR
		Down:
			ld a, [_OAMRAM]
			inc a
			inc a
			; If at edge of playfield, don't move
			cp a, 139
			jp nc, CheckKeysR
			ld [_OAMRAM], a

		CheckKeysR:
			ld a, [wGameMode]
			cp a, 0
			jp z, Controller
			call GetKeys
			CheckUpR:
				ld a, [wCurKeys]
				and a, PADF_A
				jp z, CheckDownR
			UpR:
				ld a, [_OAMRAM + 4]
				dec a
				dec a
				cp a, 21
				jp c, MainLoop
				ld [_OAMRAM + 4], a
			CheckDownR:
				ld a, [wCurKeys]
				and a, PADF_B
				jp z, MainLoop
			DownR:
				ld a, [_OAMRAM + 4]
				inc a
				inc a
				cp a, 139
				jp nc, MainLoop
				ld [_OAMRAM + 4], a
		
		; When single player mode is selected, controls right paddle
		Controller:
			ld a, [wBallVelocityX]
			cp a, -1
			jp z, MainLoop

			ld a, [wFrameCounter]
			and a, %10
			jp nz, MainLoop

			ld a, [wBallVelocityY]
			cp a, -1

			ld a, [_OAMRAM + 8]
			ld b, a
			ld a, [_OAMRAM + 4]

			jp z, ControllerUp
			jp c, ControllerStill

			cp a, b
			jp nc, MainLoop
			inc a
			cp a, 139
			jp nc, MainLoop
			ld [_OAMRAM + 4], a
			jp MainLoop

		ControllerUp:
			cp a, b
			jp c, MainLoop
			dec a
			cp a, 21
			jp c, MainLoop
			ld [_OAMRAM + 4], a
			jp MainLoop

		ControllerStill:
			cp a, b
			jp nc, ControllerStillUp
			jp z, MainLoop
			
			inc a
			cp a, 139
			jp nc, MainLoop
			ld [_OAMRAM + 4], a
			jp MainLoop

		ControllerStillUp:
			dec a
			cp a, 21
			jp c, MainLoop
			ld [_OAMRAM + 4], a
		jp MainLoop

	GameOverLoop:
		call WaitVBlank
		call WaitNoVBlank
		ld a, [wFrameCounter]
		inc a
		ld [wFrameCounter], a
		cp a, 120
		jp nz, GameOverLoop
		jp Begin

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

	; Converts pixel to tilemap address
	; hl = $9800 + X + Y * 32
	; @param b: X
	; @parab c: Y
	; @return hl: tile address
	GetTileByPixel:
		; Mask Y so it's divisible by 
		ld a, c
		and a, %11111000
		ld l, a
		ld h, 0
		add hl, hl
		add hl, hl
		ld a, b
		srl a
		srl a
		srl a
		add a, l
		ld l, a
		adc a, h
		sub a, l
		ld h, a
		ld bc, $9800
		add hl, bc
		ret

	; Checks if tile has collision
	; @param a: tile ID
	; @return z: set if till has collision
	CheckTileCollision:
		cp a, $03
		ret z
		cp a, $04
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

		dw `00333300
		dw `03000000
		dw `03000000
		dw `03000000
		dw `00333300
		dw `00000300
		dw `00000300
		dw `03333000
		dw `00000000
		dw `00000000
		dw `00030000
		dw `00000000
		dw `00030000
		dw `00030000
		dw `00030000
		dw `00030000
		dw `00000000
		dw `00000000
		dw `03033000
		dw `03300300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `00000000
		dw `00000000
		dw `00333300
		dw `03000300
		dw `03000300
		dw `00333300
		dw `00000300
		dw `03333000
		dw `00000000
		dw `00000000
		dw `00030000
		dw `00030000
		dw `00030000
		dw `00030000
		dw `00030000
		dw `00030000
		dw `00000000
		dw `00000000
		dw `03033000
		dw `03300300
		dw `03000300
		dw `03333000
		dw `03000000
		dw `03000000
		dw `00000000
		dw `00000000
		dw `03003000
		dw `03003000
		dw `00333000
		dw `00003000
		dw `03003000
		dw `00333000
		dw `03000300
		dw `03303300
		dw `03030300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `00000000
		dw `00000000
		dw `03000300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `03000300
		dw `00333000
	TilesTitleEnd:
	
	TilesMain:
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333330
		dw `33333330
		dw `33333330
		dw `33333330
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `03333333
		dw `03333333
		dw `03333333
		dw `03333333
		dw `33333333
		dw `33333333
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `33333333
		dw `33333333
		dw `33333333
		dw `33333333
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		dw `00000000
		
		dw `33003333
		dw `33303333
		dw `33303333
		dw `33303333
		dw `33303333
		dw `33303333
		dw `33303333
		dw `33000333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33033333
		dw `33033333
		dw `33033333
		dw `33000333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33033333
		dw `33033333
		dw `33030333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33033333
		dw `33033333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33000333
		dw `33033333
		dw `33033333
		dw `33033333
		dw `33000333
		dw `33030333
		dw `33030333
		dw `33000333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33030333
		dw `33030333
		dw `33000333
		dw `33000333
		dw `33030333
		dw `33030333
		dw `33000333
		dw `33000333
		dw `33030333
		dw `33030333
		dw `33000333
		dw `33330333
		dw `33330333
		dw `33330333
		dw `33000333
		dw `33000333
		dw `33000333
		dw `33030333
		dw `33030333
		dw `33030333
		dw `33030333
		dw `33000333
		dw `33000333

	TilesMainEnd:

	TilesModeObject:
		dw `33000000
		dw `33300000
		dw `31330000
		dw `31133000
		dw `31133000
		dw `31330000
		dw `33300000
		dw `33000000

	TilesModeObjectEnd:

	TilesObject:
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `00000033
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `33000000
		dw `00000000
		dw `00000000
		dw `00333300
		dw `00333300
		dw `00333300
		dw `00333300
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
	TilesObjectEnd:

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

	TileMapModeSelect:
		db $05, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $06, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $17, $18, $19, $1A, $1B, $13, $1C, $1B, $16, $1D, $13, $12, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $1E, $1F, $1B, $15, $18, $1C, $1B, $16, $1D, $13, $12, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $02, 0,0,0,0,0,0,0,0,0,0,0,0
		db $07, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $08, 0,0,0,0,0,0,0,0,0,0,0,0
	TileMapModeSelectEnd:

	TileMapMain:
		db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, 0,0,0,0,0,0,0,0,0,0,0,0
		db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, 0,0,0,0,0,0,0,0,0,0,0,0
	TileMapMainEnd:

SECTION "Counters", WRAM0
wFrameCounter: db
wScoreCounter: db

SECTION "Input Variables", WRAM0
wCurKeys: db
wNewKeys: db

SECTION "Ball Data", WRAM0
wBallVelocityX: db
wBallVelocityY: db

Section "Game Data", WRAM0
wGameMode: db
