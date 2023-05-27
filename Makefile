ASSEMBLER := rgbasm
LINKER := rgblink
FIX := rgbfix

pong.gb: main.asm
	$(ASSEMBLER) -L -o main.o main.asm

pong.gb: main.o
	$(LINKER)  -o pong.gb main.o

fix:
	$(FIX) -v -f 0xFF pong.gb