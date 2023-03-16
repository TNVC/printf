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
proc floatToStr stdcall uses eax ecx edx ebx, number: dword, buffer: dword

locals
  temp1 dd ?
  temp2 dd ?
  temp3 dd ?
  temp4 dd ?
  temp5 dd ?
  temp6 dd ?
endl

  mov ebx, dword [buffer]       ; EBX = buffer

  stdcall isinf, dword [number] ;\
  test al, al                   ; |
  jz @f                         ; | if (!isinf(number)) goto @f

  mov dword [ebx], 000666E49h   ; buffer = 'Inf\0'
  jmp .endp
@@:

  stdcall isnan, dword [number] ;\
  test al, al                   ; |
  jz @f                         ; | if (!isnan(number)) goto @f

  mov dword [ebx], 0004E614Eh   ; buffer = 'NaN\0'
  jmp .endp
@@:

  fldz                          ;\
  fld dword [number]            ; |
  fcomip st0, st1               ; |
  fstp st0                      ; |
  jnz @f                        ; | if (number) goto @f

  mov dword [ebx], 000000030h   ; buffer = '0\0'
  jmp .endp
@@:

  fnstcw word [temp1]           ;\
  or word [temp1], 0c00h        ; |
  fldcw word [temp1]            ; | FPU.setRounding(FPU.toZero)

  fld dword [number]            ; fpush(number)
  fldz                          ; fpush(0)

  fcomip st0, st1               ;\
  seta al                       ; |
  movzx eax, al                 ; | EAX = (st0 > st1)
  mov dword [temp1], eax        ; temp1 = EAX

  test al, al                   ;\
  jz .positive                  ; | if (!EAX) goto .positive

  mov byte [ebx], '-'           ;\
  inc ebx                       ; | *(buffer++) = '-'

  fchs                          ;\
  fst dword [number]            ; | number = -fpop()
.positive:

  fstp st0                      ; fpop()

  fnstcw word [temp3]           ;\
  mov ax, word [temp3]          ; |
  and ax, 0F3FFh                ; |
  mov word [temp3], ax          ; |
  fldcw word [temp3]            ; | FPU.setRounding(FPU.toNeighbour)

  fldlg2                        ;\
  fld dword [number]            ; |
  fyl2x                         ; |
  fistp dword [temp2]           ; | temp2 = Int(log10(number))
  mov eax, dword [temp2]        ; EAX = temp2

  fnstcw word [temp3]           ;\
  or word [temp3], 0c00h        ; |
  fldcw word [temp3]            ; | FPU.setRounding(FPU.toZero)

  cmp eax, 0Eh                  ;\
  jge .useExp_true              ; | if (EAX >= 14d) goto .useExp_true

  cmp eax, -9d                  ;\
  jle .useExp_true              ; | if (EAX <= -9d) goto .useExp_true

  cmp eax, 09h                  ;\
  jl .useExp_false              ; | if (m < 9d) goto .useExp_false

  mov eax, dword [temp1]        ;\
  test eax, eax                 ; |
  jz .useExp_false              ; | if (temp1) goto .useExp_false
.useExp_true:
  mov ecx, 01h                  ; ECX = 01h

  cmp dword [temp2], 00h        ;\
  jge @f                        ; | if (temp2 >= 00h) goto @f
;;dec dword [temp2]             ; --temp2
@@:
  stdcall pow, 10.0, dword [temp2] ;\
  mov dword [temp3], eax           ; | temp3 = pow(10.0, temp2)

  fld dword [number]            ; fpush(number)
  fld dword [temp3]             ; fpush(temp3)

  fdivp                         ;\
  fstp dword [number]           ; | number = 1/fpop() * fpop()

  mov eax, dword [temp2]        ;\
  mov dword [temp3], eax        ; | temp3 = temp2
  mov dword [temp2], 00h        ; temp2 = 00h

  jmp .useExp_end
.useExp_false:
  mov ecx, 00h                  ; ECX = 00h
.useExp_end:
  mov dword [temp1], ecx        ; temp1 = ECX

  cmp dword [temp2], 01h        ;\
  jge @f                        ; | if (temp2 >= 01h) goto @f
  mov dword [temp2], 00h        ; temp2 = 00h
@@:

  jmp .condLoop0
.startLoop0:
  stdcall pow, 10.0, dword [temp2] ;\
  mov dword [temp5], eax           ; | temp5 = pow(10.0, temp2)

  fldz                          ; fpush(0)
  fld dword [temp5]             ; fpush(temp5)

  fcomip st0, st1               ;\
  fstp st0                      ; |
  jbe @f                        ; | if (temp5 <= 0) goto @f

  stdcall isinf, dword [temp5]  ; EAX = isinf(temp5)

  test al, al                   ;\
  jnz @f                        ; | if (AL) goto @f

  fld dword [number]            ; fpush(number)
  fld dword [temp5]             ; fpush(temp5)

  fdivp                         ;\
  fstp dword [temp6]            ; | temp6 = 1/fpop()*fpop()

  stdcall floor, dword [temp6]  ;\
  mov dword [temp6], eax        ; | temp6 = floor(temp6)

  fld dword [number]            ; fpush(number)

  fild dword [temp6]            ;\
  fmul dword [temp5]            ; | fpush(Float(temp6)*temp5)

  fsubp                         ;\
  fstp dword [number]           ; | number = -fpop() + fpop()

  add al, '0'                   ; AL += '0'
  mov byte [ebx], al            ;\
  inc ebx                       ; | *(buffer++) = AL
  @@:

  cmp dword [temp2], 00h        ;\
  jne @f                        ; | if (temp2) goto @f

  fldz                          ; fpush(0)
  fld dword [number]            ; fpush(number)

  fcomip st0, st1               ;\
  fstp st0                      ; |
  jbe @f                        ; | if (number <= 0) goto @f

  mov byte [ebx], '.'           ;\
  inc ebx                       ; | *(buffer++) = '.'
@@:

  dec dword [temp2]             ; --temp2

.condLoop0:
  cmp dword [temp2], 00h        ;\
  jge .startLoop0               ; | if (temp2 >= 00h) goto .startLoop0

  mov dword [temp4], 1e-9       ;\
  fld dword [temp4]             ; | fpush(1e-9)
  fld dword [number]            ; fpush(number)

  fcomip st0, st1               ;\
  fstp st0                      ; |
  ja .startLoop0                ; | if (number > 1e-14) goto .startLoop0

  cmp dword [temp1], 00h        ;\
  je .withoutExp                ; | if (!temp1) goto @f

  mov byte [ebx], 'e'           ;\
  inc ebx                       ; | *(buffer++) = 'e'

  cmp dword [temp3], 00h        ;\
  setle al                      ; |
  shl al, 01h                   ; |
  add al, '+'                   ; | AL = (temp3 > 00h) ? '+' : '-'

  mov byte [ebx], al            ;\
  inc ebx                       ; | *(buffer++) = AL

  cmp al, '-'                   ;\
  jne @f                        ; | if (AL != '-') goto @f

  neg dword [temp3]             ; temp3 = -temp3
@@:
  mov dword [temp2], 00h        ; temp2 = 00h

  jmp .condLoop1
.startLoop1:

  mov ecx, dword [temp3]        ; ECX = temp3

  mov eax, ecx                  ;\
  mov edx, 033333334h           ; |
  imul edx                      ; |
  shr edx, 01h                  ; | EDX = ECX * Number.approximate(1/10)

  mov dword [temp3], edx        ; temp3 /= 0Ah

  mov eax, edx                  ;\
  shl edx, 02h                  ; |
  add edx, eax                  ; |
  shl edx, 01h                  ; | EDX *= 10

  sub ecx, edx                  ; ECX -= EDX

  add cl, '0'                   ; CL += '0'

  mov byte [ebx], cl            ;\
  inc ebx                       ; | *(buffer++) = CL

  inc dword [temp2]             ; ++temp2

.condLoop1:
  cmp dword [temp3], 00h        ;\
  jg .startLoop1                ; | if (temp3 > 00h) goto .startLoop1

  sub ebx, dword [temp2]        ; buffer -= temp2

  mov eax, ebx                  ; EAX = buffer
  mov ecx, ebx                  ;\
  add ecx, dword [temp2]        ; |
  dec ecx                       ; | ECX = buffer + temp2 - 01h

  jmp .condLoop2
.startLoop2:
  mov dl, byte [eax]            ;\
  mov dh, byte [ecx]            ; |
  xchg dl, dh                   ; |
  mov byte [eax], dl            ; |
  mov byte [ecx], dh            ; | *EAX, *ECX = *ECX, *EAX

  inc eax                       ; ++EAX
  dec ecx                       ; --ECX

.condLoop2:
  cmp eax, ecx                  ;\
  jl .startLoop2                ; | if (EAX < ECX) goto .startLoop2

  add ebx, dword [temp2]        ; buffer += temp2

.withoutExp:
  mov byte [ebx], 00h        ; *buffer = 00h
.endp:
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
proc pow stdcall uses ecx, base: dword, power: dword

  mov ecx, dword [power]        ; ECX = power

  cmp ecx, 01h                  ;\
  je .one                       ; | if (ECX == 01h) goto .one

  test ecx, ecx                 ;\
  jz .zero                      ; | if (!ECX) goto .zero
  jns .positive                 ; if (!Sign(EAX)) goto .positive

  neg ecx                       ; ECX = -ECX
  jmp .negative

.positive:
  dec ecx                       ; --ECX

  fld dword [base]              ; push(base)
@@:
  fmul dword [base]             ; push(pop()*base)
  loop @b                       ; Loop.updateAndCheckCounter(ECX)

  fstp dword [base]             ;\
  mov eax, dword [base]         ; | EAX = pop()

  jmp .endp
.negative:
  fld1                          ; push(1)
@@:
  fdiv dword [base]             ; push(pop()/base)
  loop @b                       ; Loop.updateAndCheckCounter(ECX)

  fstp dword [base]             ;\
  mov eax, dword [base]         ; | EAX = pop()
  jmp .endp

.zero:
  mov eax, 1.0                  ; EAX = 1.0
  jmp .endp
.one:
  mov eax, dword [base]         ; EAX = base
.endp:
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
;;; Floor number
;;; ================================================================
;;; @param [in] number - number for floor
;;; @return EAX - bool
;;; ================================================================
proc floor stdcall number: dword

locals
  buffer dw ?
endl

  fnstcw word [buffer]          ;\
  mov ax, word [buffer]         ; |
  and ax, 0F3FFh                ; |
  or  ax, 00400h                ; |
  mov word [buffer], ax         ; |
  fldcw word [buffer]           ; | FPU.setRounding(FPU.toNegInf)

  fld dword [number]            ;\
  frndint                       ; | push(Int(number))

  fistp dword [number]          ;\
  mov eax, dword [number]       ; | EAX = pop()

  fnstcw word [buffer]          ;\
  or word [buffer], 0c00h       ; |
  fldcw word [buffer]           ; | FPU.setRounding(FPU.toZero)

  ret
endp
;;; ================================================================
