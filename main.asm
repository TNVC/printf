format ELF
public main
public _printf

include 'proc32.inc'
include 'printf.asm'

extrn printf
extrn exit
extrn c_main

section '.text' executable align 16

NaN equ 07FFFFFFFh
Inf equ 07F800000h

main:
  ccall _printf, floatMessage, 0, NaN, Inf, 3.14, 12345e+20, 12345e-20, -54321e20, -54321e-20, 1e38, 1e-44
  ccall _printf, floatMessage, 1.0, 11.0, 111.0, 1111.0, 11111.0, 111111.0, 1111111.0, 11111111.0, 111111111.0, 1111111111.0
  ccall _printf, floatMessage, 0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001, 0.00000001, 0.000000001, 0.0000000001
 	ccall exit, 00h

  ccall _printf, message, love, 3802d, 100d, 33d, 127d
  ccall  printf, message, love, 3802d, 100d, 33d, 127d
  ccall c_main
 	ccall exit, 00h

section '.data' align 4

  floatMessage db '(%f) (%f) (%f) (%f) (%f) (%f) (%f) (%f) (%f) (%f)', 0Ah, 00h

  message db 'I %s %x %d%%%c%b%r from ASM', 0Ah, 00h
  love db 'love', 00h
