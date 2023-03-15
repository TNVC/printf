stdout equ 01h
System.Write equ 04h

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

  movzx eax, byte [edi]         ; EAX = [EDI]

  cmp al, '%'                   ;\
  je .%                         ; | if ([EDI] == '%') goto .%

  cmp al, 'b'                   ;\
  jl ._                         ; | if ([EDI] < 'b') goto ._

  cmp al, 'x'                   ;\
  jg ._                         ; | if ([EDI] > 'x') goto ._

  sub eax, 'b'                  ;\
  shl eax, 02h                  ; |
  add eax, .table               ; | EAX = Poiter<Code>([EDI])

  jmp dword [eax]               ; goto Table.get(EAX)

.table:
  dd .b                          ; 62 'b'
  dd .c                          ; 63 'c'
  dd .d                          ; 64 'd'
  dd 01h dup(._)
  dd .f                          ; 66 'f'
  dd 08h dup(._)
  dd .o                          ; 6f 'o'
  dd 03h dup(._)
  dd .s                          ; 73 's'
  dd 04h dup(._)
  dd .x                          ; 78 'x'

._:
  stdcall putchar, '%' ; putchar('%')
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

  neg eax                       ; EAX = -EAX

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
proc floatToStr stdcall uses eax ecx edx ebx edi esi, number: dword, buffer: dword

locals
  digit  dd ?
  m      dd ?
  m1     dd ?
  _neg   dd ?
  useExp dd ?
  weight dd ?
  i      dd ?
  j      dd ?
  const  dd 1e-12
  temp0  dd ?
  temp1  dd ?
  temp2  dd ?
endl

  xor eax, eax                  ; EAX = 00h
  mov ebx, dword [buffer]       ; EBX = buffer

  ;; if (isNaN(EAX))  return 'NaN'
  ;; if (isInf(EAX))  return 'Inf'
  ;; if (isZero(EAX)) return '0'

  fldz                          ; push(0)
  fld dword [number]            ; push(number)

  fcomip st, st1                ;\
  seta al                       ; | AL = (st0 < st1)

  fstp st0                      ; pop()

  mov dword [_neg], eax         ; _neg = EAX

  cmp al, 00h                   ;\
  jne @f                        ; | if (!AL) goto @f

  fld dword [number]            ;\
  fchs                          ; |
  fstp dword [number]           ; | number = -number

  mov byte [ebx], '-'           ;\
  inc ebx                       ; | *(buffer++) = '-'
@@:

  fldlg2                        ;\
  fld dword [number]            ; |
  fyl2x                         ; | push(log2(number) * lg(2))
  fistp dword [m]               ; m = Int(pop())

  mov eax, dword [m]            ; EAX = m

  cmp eax, 0Eh                  ;\
  jge .useExp_true              ; | if (m >= 14d) goto .useExp_true

  cmp eax, -09h                 ;\
  jle .useExp_true              ; | if (m <= -9d) goto .useExp_true

  cmp eax, 09h                  ;\
  jl .useExp_false              ; | if (m < 9d) goto .useExp_false

  mov eax, dword [_neg]         ; EAX = _neg

  test eax, eax                 ;\
  jz .useExp_true               ; | if (!neg) goto .useExp_false

.useExp_true:
  mov dword [useExp], 01h       ; useExp = 01h
  jmp @f
.useExp_false:
  mov dword [useExp], 00h       ; useExp = 00h
@@:

  cmp dword [useExp], 00h       ;\
  je .endIf0                    ; | if (!useExp) goto .endIf0

  cmp dword [m], 00h            ;\
  jge @f                        ; | if (m >= 00h) goto @f

  sub dword [m], 01h            ; m -= 1
@@:

  stdcall power, 10.0, dword [m] ; EAX = power(10.0, m)

  fld dword [number]            ; push(number)
  mov dword [temp0], eax        ;\
  fld dword [temp0]             ; | push(EAX)

  fdivp                         ; push(1/pop()*pop())
  fstp dword [number]           ; number = pop()

  mov eax, dword [m]            ;\
  mov dword [m1], eax           ; | m1= m
  mov dword [m], 00h            ; m = 00h
.endIf0:

  cmp dword [m], 01h            ;\
  jge @f                        ; |
  mov dword [m], 00h            ; | if (m < 01h) m = 00h
@@:

  jmp .condLoop0
.startLoop0:

  stdcall power, 10.0, dword [m] ;\
  mov dword [weight], eax        ; | weight = power(10.0, m)

  fldz                          ; push(0)
  fld dword [weight]            ; push(weight)
  fcomip st, st1                          ;\
  fstp st0                      ; pop()   ; |
  jbe @f                                  ; | if (pop() <= pop()) goto @f

  stdcall isinf, dword [weight] ; EAX = isinf(weight)
  cmp eax, 01h                  ;\
  je @f                         ; | if (EAX) goto @f

  fld dword [number]            ; push(number)
  fld dword [weight]            ; push(weight)
  fdivp                         ; push(1/pop()*pop())

  fst dword [temp0]             ;\
  stdcall floor, dword [temp0]  ; |
  mov dword [digit], eax        ; | digit = floor(top())

  fld dword [weight]            ; push(weight)
  fmulp                         ; push(pop()*pop())
  fsub dword [number]           ; ST(0) -= number
  fchs                          ; ST(0) = -ST(0)
  fstp dword [number]           ; number = pop()

  mov eax, dword [digit]        ;\
  add eax, '0'                  ; | EAX = digit + '0'

  mov byte [ebx], al            ;\
  inc ebx                       ; | *(buffer++) = AL
@@:

  cmp dword [m], 00h            ;\
  jne @f                        ; | if (m != 00h) goto @f

  cmp dword [number], 00h       ;\
  jle @f                        ; | if (number <= 00h) goto @f

  mov byte [ebx], '.'           ;\
  inc ebx                       ; | *(buffer++) = '.'
@@:

  sub dword [m], 01h            ; --m

.condLoop0:
  cmp dword [m], 00h            ;\
  jge .startLoop0               ; | if (m >= 00h) goto .startLoop0

  fld dword [const]             ; push(1e-12)
  fld dword [number]            ; push(number)
  fcomip st, st1                        ;\
  fstp st0                      ; pop() ; |
  jg .startLoop0                        ; | if (number > 1e-12) goto .startLoop0

  cmp dword [useExp], 00h       ;\
  je @f                         ; | if (!useExp) goto @f

  mov byte [ebx], 'e'           ;\
  inc ebx                       ; | *(buffer++) = 'e'

  cmp dword [m1], 00h           ;\
  jle .else                     ; | if (m1 <= 00h) goto .else

  mov byte [ebx], '+'           ;\
  inc ebx                       ; | *(buffer++) = '+'

  jmp .endIf
.else:
  mov byte [ebx], '-'           ;\
  inc ebx                       ; | *(buffer++) = '-'
  neg dword [m1]                ; m1 = -m1

.endIf:
  mov dword [m], 00h            ; m = 00h

  jmp .condLoop1
.startLoop1:

  xor edx, edx                  ; EDX = 00h
  mov eax, dword [m1]           ; EAX = m1

  mov esi, 0Ah                  ;\
  idiv esi                      ; | EDX = EAX % 0Ah, EAX = EAX / 0AH

  mov dword [m1], eax           ; m1 /= 0Ah

  mov al, '0'                   ;\
  add al, dl                    ; | AL = '0' + Dl

  mov byte [ebx], al            ;\
  inc ebx                       ; | *(buffer++) = AL

  inc dword [m]                 ; ++m

.condLoop1:
  cmp dword [m1], 00h           ;\
  jg .startLoop1                ; | if (m1 > 00h) goto .startLoop1

  sub ebx, dword [m]            ; buffer -= m

  mov edi, 00h                  ; i = 00h
  mov esi, dword [m]            ;\
  dec esi                       ; | j = m - 01h

  jmp .condLoop2
.startLoop2:

  mov eax, ebx                  ;\
  add eax, edi                  ; | EAX = buffer + i

  mov edx, ebx                  ;\
  add edx, esi                  ; | EDX = buffer + j

  mov cl, byte [eax]            ; CL = [EAX]
  mov ch, byte [edx]            ; CH = [EAX]

  xchg cl, ch                   ; Swap(CL, CH)

  mov byte [eax], cl            ; [EAX] = CL
  mov byte [edx], ch            ; [EAX] = CH

  inc edi                       ; ++i
  dec esi                       ; --j

.condLoop2:
  cmp edi, esi                  ;\
  jl .startLoop2                ; | if (i < j) goto .startLoop2

  add ebx, dword [m]            ; buffer += m
@@:

  mov byte [es:ebx], 00h        ; *buffer = 00h
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
proc power stdcall uses ecx, base: dword, index: byte

  fld dword [base]              ; push(base)

  mov ecx, dword [index]        ; Loop.initCounter(ECX)
@@:
  fmul dword [base]             ; push(pop()*base)
  loop @b                       ; Loop.updateAndCheckCounter(ECX)

  fstp dword [base]             ;\
  mov eax, dword [base]         ; | EAX = pop()

  ret
endp
;;; ================================================================

;;; ================================================================
;;; Check number for infinit
;;; ================================================================
;;; @param [in] number - number for check
;;; @return EAX - bool
;;; ================================================================
proc isinf stdcall uses ebx, number: dword

  mov eax, dword [number]       ; EAX = number

  mov ebx, eax                  ;\
  and ebx, 07FFFFFh             ; | EBX = base(EAX)

  test ebx, ebx                 ;\
  jne @f                        ; | if (!EBX) goto @f

  mov ebx, eax                  ;\
  and ebx, 07F800000h           ; |
  shr ebx, 017h                 ; | EBX = exp(EAX)

  cmp ebx, 0FFh                 ;\
  jne @f                        ; | if (EBX != 0FFh) goto @f

  mov eax, 01h                  ; EAX = 01h
  jmp .endp
@@:
  xor eax, eax                  ; EAX = 00h
.endp:
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Check number for NaN
;;; ================================================================
;;; @param [in] number - number for check
;;; @return EAX - bool
;;; ================================================================
proc isnan stdcall uses ebx, number: dword

  mov eax, dword [number]       ; EAX = number

  mov ebx, eax                  ;\
  and ebx, 07FFFFFh             ; | EBX = base(EAX)

  test ebx, ebx                 ;\
  je @f                         ; | if (EBX) goto @f

  mov ebx, eax                  ;\
  and ebx, 07F800000h           ; |
  shr ebx, 017h                 ; | EBX = exp(EAX)

  cmp ebx, 0FFh                 ;\
  jne                           ; | if (EBX != 0FFh) goto @f

  mov eax, 01h                  ; EAX = 01h
  jmp .endp
@@:
  xor eax, eax                  ; EAX = 00h
.endp:
  ret
endp
;;; ================================================================

;;; ================================================================
;;; Floor number
;;; ================================================================
;;; @param [in] number - number for floor
;;; @return EAX - bool
;;; ================================================================
proc floor stdcall number: dword

locals
  originalBuffer dw ?
  buffer         dw ?
endl

  fnstcw word [originalBuffer]  ; originalBuffer = CR

  mov ax, word [originalBuffer] ;\
  and ax, 0F3FFh                ; |
  or  ax, 00400h                ; |
  mov word [buffer], ax         ; | buffer = CR & 0F3FFh | 00400h

  fldcw word [buffer]           ; CR = buffer

  fld dword [number]            ;\
  frndint                       ; | push(Int(number))

  fistp dword [number]          ;\
  mov eax, dword [number]       ; | EAX = pop()

  fldcw word [originalBuffer]   ; CR = originalBuffer

  ret
endp
;;; ================================================================
