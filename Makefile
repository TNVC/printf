all:
	@fasm main.asm amain.o
	@gcc -m32 -c main.c -o cmain.o
	@gcc -m32 amain.o cmain.o -o a.out
	@rm -rf amain.o cmain.o
clear:
	@rm -rf amain.o cmain.o a.out
run: all
	@./a.out
