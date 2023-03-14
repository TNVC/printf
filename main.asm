format ELF
public main
public _printf

include 'proc32.inc'
include 'printf.asm'

extrn printf
extrn exit
extrn c_main

section '.text' executable align 16

main:
  ccall _printf, message, love, 3802d, 100d, 33d, 127d
  ccall  printf, message, love, 3802d, 100d, 33d, 127d
  ccall c_main
 	ccall exit

section '.data' align 4

  message db 'I %s %x %d%%%c%b from ASM', 0Ah, 00h
  love db 'love', 00h
