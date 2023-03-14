stdout equ 01h
System.Write equ 04h

macro when val
{
  cmp byte [edi], `val          ;\
  je . # val                    ; | if ([EDI] == 'val') goto .val
  ;; jmp table
}

macro case val, soubrutine
{
. # val :
  stdcall soubrutine, dword [ebx], esi ; EAX = Function(soubrutine).invoke(Number(EBX), ..buffer)
  jmp .number
}
;;; ================================================================
;;; Print format C-like string like printf() from C
;;; ================================================================
;;; @param [in] format - foramt C-like string
;;; @param [in] ... - stack located values
;;; @return EAX - count of printed chars
;;; ================================================================
;;; Permitted formats: %d %b %o %x %c %s %f
;;; ================================================================
proc _printf c uses eax ebx ecx edx edi esi, format: dword

locals
  buffer db 022h dup(?)
  label ..buffer at 024h
endl
  mov esi, ebp                  ;\
  sub esi, ..buffer             ; | ESI = Pointer<Char>(..buffer)

  mov edi, dword [format]       ; EDI = format
  lea ebx, [ebp + 0Ch]          ; EBX = Pointer<?>(format + 01h)

.head:
  stdcall strchr, edi, '%'      ; EAX = strchr(EDI, '%')

  and eax, eax                  ;\
  jz .tail                      ; | if (!format.next()) goto .tail

  stdcall iterprints, edi, eax  ; print(format.tail())
  inc eax                       ; format.restoreHead()

  mov edi, eax                  ; EDI = format.nextHead()

  when s
  when c
  when b
  when o
  when x
  when d
  when %

  jmp .head
.%:
  stdcall putchar, '%' ; putchar('%')
  inc edi
  jmp .head

.s:
  stdcall prints, dword [ebx]   ; prints(String([EBX]))
  jmp .end

.c:
  stdcall putchar, dword [ebx]  ; putchar(Char([EBX]))
  jmp .end

  case b, binToStr
  case o, octToStr
  case x, hexToStr
  case d, decToStr
  case f, floatToStr

.number:
  stdcall prints, esi           ; prints(..buffer)
  jmp .end

.end:
  add ebx, 04h                    ; EBX.nextArg()
  inc edi                         ; skipChar(EDI)
  jmp .head

.tail:
  stdcall prints, edi           ; print(format.tail())

  ret
endp
;;; ================================================================

;;; ================================================================
;;; Put char into stdout
;;; ================================================================
;;; @param [in] char - char
;;; ================================================================
proc putchar stdcall uses eax ecx edx ebx, char: byte

  lea ecx, dword [char]         ;\
  mov edx, 01h                  ; |
	mov	ebx, stdout               ; |
	mov	eax, System.Write         ; | SetParametersFor(System.Write)

	int 080h                      ; System.Write(stdout, ECX)

  ret
endp
;;; ================================================================

;;; ================================================================
;;; Print C-like string
;;; ================================================================
;;; @param [in] string - C-like string
;;; ================================================================
proc prints stdcall uses eax ecx edx ebx, string: dword

  mov ecx, dword [string]       ; ECX = string

  stdcall strlen, ecx           ;\
  mov edx, eax                  ; | EDX = strlen(ECX)

	mov	ebx, stdout               ;\
	mov	eax, System.Write         ; | SetParametersFor(System.Write)

	int 080h                      ; System.Write(stdout, ECX.substring(0, EDX))

  ret
endp
;;; ================================================================

;;; ================================================================
;;; Print C-like string
;;; ================================================================
;;; @param [in] beginStr - first char of C-like string
;;; @param [in]   endStr - first char after C-like string
;;; ================================================================
proc iterprints stdcall uses eax ecx edx ebx, beginStr: dword, endStr

  mov ecx, dword [beginStr]       ; ECX = beginStr

  mov edx, dword [endStr]       ;\
  sub edx, ecx                  ; | EDX = strlen(ECX)

	mov	ebx, stdout               ;\
	mov	eax, System.Write         ; | SetParametersFor(System.Write)

	int 080h                      ; System.Write(stdout, ECX.substring(0, EDX))

  ret
endp
;;; ================================================================

;;; ================================================================
;;; Count length of C-like string without '\0'
;;; ================================================================
;;; @param [in] string - C-like string
;;; @return EAX - Size of string without '\0'
;;; ================================================================
proc strlen stdcall uses edi, string: dword

  mov edi, dword [string]       ; EDI = string

  xor eax, eax                  ; EAX = 00h

  dec eax                       ; --EAX
@@:
  inc eax                       ; ++EAX

  cmp byte [edi + eax], 00h     ;\
  jne @b                        ; | if ([EDI + EAX]) goto Loop

  ret
endp
;;; ================================================================

;;; ================================================================
;;; Search first char in string
;;; ================================================================
;;; @param [in] string - C-like string
;;; @param [in] char - needed char
;;; @return EAX - address of first founed char or 00h
;;; ================================================================
proc strchr stdcall uses ebx, string: dword, char: byte

  mov eax, dword [string]       ; EAX = string
  mov ebx, dword [char]         ; EBX = char

@@:
  cmp byte [eax], 00h           ;\
  je @f                         ; | if (![EAX]) break

  cmp byte [eax], bl            ;\
  je @f                         ; | if ([EAX] == Bl) break

  inc eax                       ; Loop.updateCounter(EAX)
  jmp @b                        ; Loop.gotoStart()
@@:

  cmp byte [eax], bl            ;\
  je @f                         ; |
  xor eax, eax                  ; | if ([EAX] == BL) EAX = 00h

@@:
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Translate number to hex string
;;; ================================================================
;;; @param [in] number - number for translate to hex string
;;; @param [in/out] buffer - buffer for translated string
;;; ================================================================
proc hexToStr stdcall uses eax ecx edx ebx, number: dword, buffer: dword

  mov eax, dword [number]       ; EAX = number
  mov ebx, dword [buffer]       ; EBX = buffer

  mov ecx, 04h                  ; Loop.initCounter(ECX)
.loop:
  rol eax, 08h                  ; EAX.moveByte(first to last)

  mov dl, 02h                  ; Loop.initCounter(DL)
@@:
  ror al, 04h                   ; AL.swapHalfBytes()

  mov ch, al                    ;\
  and ch, 0Fh                   ; | CH = AL.bits(04h)

  add ch, '0'                   ; CH.transformToChar()

  cmp ch, '9'                   ;\
  jle .writeNum                 ; |
  add ch, 07h                   ; | if (CH.hexNumber()) CH.transformToHexNum()

.writeNum:
  mov byte [ebx], ch            ;\
  inc ebx                       ; | [EBX++] = CH

  xor ch, ch                    ; CH = 00h

  dec dl                        ; Loop.updateCounter(DL)
  jnz @b                        ; Loop.checkCounter(DL)

  loop .loop                    ; Loop.updateAndCheckCounter(ECX)

  mov byte [ebx], 00h           ; EBX.setEndOfString()
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Translate number to bin string
;;; ================================================================
;;; @param [in] number - number for translate to bin string
;;; @param [in/out] buffer - buffer for translated string
;;; ================================================================
proc binToStr stdcall uses eax ecx ebx, number: dword, buffer: dword

  mov eax, dword [number]       ; EAX = number
  mov ebx, dword [buffer]       ; EBX = buffer

  mov ecx, 020h                 ; Loop.initCounter(ECX)
.loop:
  rol eax, 01h                  ; EAX.moveBit(first to last)

  mov ch, al                    ;\
  and ch, 01h                   ; | CH = AL.bit(00h)

  add ch, '0'                   ; CH.transformToChar()

  mov byte [ebx], ch            ;\
  inc ebx                       ; | [EBX++] = CH

  xor ch, ch                    ; CH = 00h

  loop .loop                    ; Loop.updateAndCheckCounter(ECX)

  mov byte [ebx], 00h           ; EBX.setEndOfString()
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Translate number to oct string
;;; ================================================================
;;; @param [in] number - number for translate to oct string
;;; @param [in/out] buffer - buffer for translated string
;;; ================================================================
proc octToStr stdcall uses eax ecx ebx, number: dword, buffer: dword

  mov eax, dword [number]       ; EAX = number
  mov ebx, dword [buffer]       ; EBX = buffer

  rol eax, 02h                  ; EAX.moveSetBit(02h, first to last)

  mov ch, al                    ;\
  and ch, 07h                   ; | CH = AL.bits(03h)

  add ch, '0'                   ; CH.transformToChar()

  mov byte [ebx], ch            ;\
  inc ebx                       ; | [EBX++] = CH

  xor ch, ch                    ; CH = 00h

  mov ecx, 0Ah                  ; Loop.initCounter(ECX)
.loop:
  rol eax, 03h                  ; EAX.moveSetBit(03h, first to last)

  mov ch, al                    ;\
  and ch, 07h                   ; | CH = AL.bits(03h)

  add ch, '0'                   ; CH.transformToChar()

  mov byte [ebx], ch            ;\
  inc ebx                       ; | [EBX++] = CH

  xor ch, ch                    ; CH = 00h

  loop .loop                    ; Loop.updateAndCheckCounter(ECX)

  mov byte [ebx], 00h           ; EBX.setEndOfString()
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Translate number to dec string
;;; ================================================================
;;; @param [in] number - number for translate to dec string
;;; @param [in/out] buffer - buffer for translated string
;;; ================================================================
proc decToStr stdcall uses eax ecx edx ebx edi, number: dword, buffer: dword

  mov eax, dword [number]       ; EAX = number
  mov ebx, dword [buffer]       ; EBX = buffer
  mov edi, 0Ah                  ; EDI = 0Ah

  test eax, eax                 ;\
  jns @f                        ; | if (!Sign(EAX))

  mov byte [ebx], '-'           ; \
  inc ebx                       ;  | [EBX] = '-'

  neg eax                       ; EAX = ~EAX

@@:
  xor ecx, ecx                  ; Loop.initCounter(ECX)
@@:
  xor edx, edx                  ; EDX = 00h
  div edi                       ; EAX = (EDX:EAX) / EDI, EDX = (EDX:EAX) % EDI

  add dl, '0'                   ; EDX.transformToChar()
  push edx                      ; Save(EDX)

  inc ecx                       ; charCounter.update()

  test eax, eax                 ;\
  jnz @b                        ; | Loop.checkCounter(EAX)

@@:
  pop eax                       ;\
  mov byte [ebx], al            ; |
  inc ebx                       ; | [EBX] = Load(EAX)

  loop @b                       ; Loop.updateAndCheckCounter(ECX)


  mov byte [ebx], 00h           ; EBX.setEndOfString()
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Translate number to float string
;;; ================================================================
;;; @param [in] number - number for translate to flaot string
;;; @param [in/out] buffer - buffer for translated string
;;; ================================================================
proc floatToStr stdcall uses eax ecx edx ebx edi, number: dword, buffer: dword

locals
  useExp dw 00h
  m      dw 00h
  m0     dw 00h
  digit  dw 00h
  neg    dw 00h
  weight dw 00h
  temp   dw 00h
endl

  mov eax, dword [number]       ;\
  mov edi, eax                  ; | EDI = EAX = number
  mov ebx, dword [buffer]       ; EBX = buffer

  ;; if (isNaN(EAX))
  ;; if (isInf(EAX))
  ;; if (isZero(EAX))
  ;; AL - useExp, CL - neg, CH - m, AH - m0
  xor ecx, ecx                  ;\
  fld dword [ss:number]         ; | push(EAX)

  ftst                          ;\
  fstsw ax                      ; |
  sahf                          ; | FLAGS = compare(ST(0), .0)

  xor ax, ax                    ; AX = 00h

  cmovb cx, ax                 ; if (ST(0) < .0) CX = 00h
  mov byte [neg], cl            ; neg = CL

  test cl, cl                   ;\
  jz @f                         ; | if (CL) goto @f

  fchs                          ; ST(0) = -ST(0)

  mov byte [es:ebx], '-'        ;\
  inc ebx                       ; | [ES:EBX++] = '-'
@@:
  fldlg2                        ; push(lg(2))
  fld st1                       ; push(ST(1))

  fyl2x                         ; push(lb(pop()) * pop())

  fistp dword [m]               ;\
  mov ch, byte [m]              ; | m = CH = Int(pop())

  cmp ch, 14d                   ;\
  jge .useExp                   ; |

  cmp ch, -9d                   ; |
  jbe .useExp                   ; |

  cmp ch,  9d                   ; |
  jb .skip                      ; |

  test cl, cl                   ; |
  jz .skip                      ; | if (!(m >= 14d || neg && m >= 9d || m <= -9d) goto .skip

.useExp:
  mov al, 01h                   ; AL = 01h

  cmp ch, 00h                   ;\
  jge @f                        ; |
  sub ch, 01h                   ; | if (m < 0) m -= 01h

  mov byte [m0], ch             ; m1 = m

  stdcall power, 0Ah, dword [m] ;\
  mov dword [digit], eax         ; |
  fld dword [digit]              ; | push(power(0Ah, m))

  fdivp                         ; push(1/pop()*pop())

  mov byte [m], 00h             ; m = 00h
@@:

  mov dword [temp], 1e-12      ; temp = 1e-12

  mov cl, byte [m]              ;\
  cmp byte [m], 01h             ; |
  jge .loop                     ; |
  xor cl, cl                    ; | if (m < 01h) m = 00h
.loop:

  cmp cl, 00h                   ;\
  jge @f                        ; |

  fcom dword [temp]             ; |
  fstsw ax                      ; |
  sahf                          ; |
  jg @f                         ; | while (number > 1e-12 || m >= 00h)

  jmp .endLoop
@@:

  stdcall power, 0Ah, dword [m0] ;\
  mov dword [weight], eax        ; |
  fld dword [weight]             ; | weight = power(0Ah, m)

  cmp eax, 00h                  ;\
  jle @f                        ; |

  stdcall isinf, eax            ; |
  test bl, bl                   ; |
  jnz @f                        ; | if (weight > 0 && !isnan(digit))

;;;  ...

  dec cl                        ; --m

@@:

.endLoop:

.skip:
  ;; sign - 31, power - 30-23, mantice - 22-0
  ;; s * (m * 2 ^ -23) * (2 ^(e-127))
  ;; TODO

  mov byte [es:ebx], 00h        ; EBX.setEndOfString()
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Power base into integer index
;;; ================================================================
;;; @param [in] base - base of power
;;; @param [in] index - index of power
;;; @return EAX - power
;;; ================================================================
proc power stdcall uses eax, base: dword, index: byte

  fld dword [base]              ; push(base)
;;; TODO
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Check number for infinit
;;; ================================================================
;;; @param [in] number - number for check
;;; @return BL - bool
;;; ================================================================
proc isinf stdcall uses eax, number: dword

;;; TODO
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Floor number
;;; ================================================================
;;; @param [in] number - number for floor
;;; @return EAX - bool
;;; ================================================================
proc floor stdcall uses eax, number: dword

;;; TODO
  ret
endp
;;; ================================================================
