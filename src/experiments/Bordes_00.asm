global Bordes00_asm

section .data:
section .rodata:
    align 16
    maskWhite: times 16 db 0xFF
    
section .text:
%define matrixDst rbx
%define rowSize r12
%define actualDst r13
Bordes00_asm:
    ; rdi = src 
    ; rsi = dst 
    ; edx = cols
    ; ecx = filas
    ; r8d = src_row_size
    ; r9d = dst_row_size
    push rbp
    mov rbp, rsp
    push matrixDst
    push rowSize
    push actualDst
    ; limpiamos los tamaños
    mov ecx, ecx                            ; rcx = filas
    mov edx, edx                            ; rdx = cols
    
    mov rowSize, rdx
    mov matrixDst, rsi
    movdqu xmm11, [maskWhite]                  ;xmm11 =;|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|
                         
    ;nos paramos en la primera posicion
    lea rdi, [rdi + 1]                ; rdi = src[0,1]
    lea rsi, [rsi + 1]                ; rsi = dst[0,1]
    mov actualDst, rsi                      ;actualDst = dst
    mov rax, rdi                            ;rax = src
    
    ;para no procesar los pixeles laterales
    sub rdx,2

    ; xmm0 se va a usar para desempaquetar
    pxor xmm0, xmm0
.cols:
    ;escribimos al principio de la fila el el byte en blanco
    movdqu [actualDst],xmm11
    mov rsi, actualDst
    mov rdi, rax    
    add rsi, rowSize
    add rdi, rowSize
    
    ;volvemos a comenzar en la siguiente columna
    add actualDst, 16
    add rax, 16
    ;actualizamos los punteros para volver a procesar
    mov r10, rdi
    sub r10, rowSize                         
    mov r11, rdi                            
    add r11, rowSize                           
    mov r9, rcx
    ;para no procesar los bordes superior e inferior
    sub r9, 2
    
    .rows:

    ;   ↖ ↑ ↗  =  xmm1 xmm2 xmm3
    ;   ← ⋅ →  =  xmm4 ---- xmm5
    ;   ↙ ↓ ↘  =  xmm6 xmm7 xmm8
    ;
    ;  Gx = [ -1   0  +1 
    ;         -2   0  +2
    ;  	      -1   0  +1 ] ∗ A 
    ;
    ;  Gy = [ -1  -2  -1
    ;  	       0   0   0
    ;         +1  +2  +1 ] ∗ A
    ;
    ;  G = sqrt( Gx^2 + Gy^2)
    ;  xmm12 = GxL
    ;  xmm13 = GxH
    ;  xmm14 = GyL
    ;  xmm15 = GyH
    ;
    ;  xmm9, xmm10 y xmm11 libres
    
    ; Levantamos los datos
    movdqu xmm1, [r10 - 1]                  ; ↖
    movdqu xmm2, [r10]                      ; ↑
    movdqu xmm3, [r10 + 1]                  ; ↗
    movdqu xmm4, [rdi - 1]                  ; ←
    movdqu xmm5, [rdi + 1]                  ; →
    movdqu xmm6, [r11 - 1]                  ; ↙
    movdqu xmm7, [r11]                      ; ↓
    movdqu xmm8, [r11 + 1]                  ; ↘
    
    ;expandimos para mayor presicion
    ;Gx
    ;+1
    movdqu xmm12, xmm3
    movdqu xmm13, xmm3
    punpcklbw xmm12, xmm0                   ;xmm12 = ↗L
    punpckhbw xmm13, xmm0                   ;xmm13 = ↗H
    
    movdqu xmm9, xmm8
    movdqu xmm10, xmm8
    punpcklbw xmm9, xmm0                    
    punpckhbw xmm10, xmm0                   
    paddsw xmm12, xmm9                       ;xmm12 = ↗L + ↘L
    paddsw xmm13, xmm10                       ;xmm13 = ↗H + ↘H
    ;+2
    movdqu xmm9, xmm5
    movdqu xmm10, xmm5
    punpcklbw xmm9, xmm0                    
    punpckhbw xmm10, xmm0                    
    psllw xmm9, 1
    psllw xmm10,1
    paddsw xmm12, xmm9                      ;xmm12 = ↗L + ↘L + 2→L
    paddsw xmm13, xmm10                     ;xmm13 = ↗H + ↘H + 2→H
    ;-1
    movdqu xmm9, xmm1
    movdqu xmm10, xmm1
    punpcklbw xmm9, xmm0                   
    punpckhbw xmm10, xmm0 
    psubsw xmm12, xmm9                      ;xmm12 = ↗L + ↘L + 2→L - ↖L
    psubsw xmm13, xmm10                     ;xmm13 = ↗H + ↘H + 2→H - ↖H
    
    movdqu xmm9, xmm6
    movdqu xmm10, xmm6
    punpcklbw xmm9, xmm0                    
    punpckhbw xmm10, xmm0                    
    psubsw xmm12, xmm9                       ;xmm12 = ↗L + ↘L + 2→L - ↖L - ↙L
    psubsw xmm13, xmm10                       ;xmm13 = ↗H + ↘H + 2→H - ↖H - ↙H

    ;-2
    movdqu xmm9, xmm4
    movdqu xmm10, xmm4
    punpcklbw xmm9, xmm0                    
    punpckhbw xmm10, xmm0                    
    psllw xmm9, 1
    psllw xmm10,1
    psubsw xmm12, xmm9                      ; xmm12 = ↗L + ↘L + 2→L - ↖L - ↙L -2←L
    psubsw xmm13, xmm10                     ; xmm13 = ↗H + ↘H + 2→H - ↖H - ↙H -2←H

    pabsw xmm12, xmm12                      ; xmm12 = abs(GxL)
    pabsw xmm13, xmm13                      ; xmm13 = abs(GxH)

    ; Gy
    movdqu xmm14, xmm6
    movdqu xmm15, xmm6
    punpcklbw xmm14, xmm0                   ; xmm14 = ↙L
    punpckhbw xmm15, xmm0                   ; xmm15 = ↙H

    movdqu xmm9, xmm8
    movdqu xmm10, xmm8
    punpcklbw xmm9, xmm0
    punpckhbw xmm10, xmm0
    paddsw xmm14, xmm9                       ; xmm14 = ↙L + ↘L
    paddsw xmm15, xmm10                      ; xmm15 = ↙H + ↙H

    movdqu xmm9, xmm7
    movdqu xmm10, xmm7
    punpcklbw xmm9, xmm0
    punpckhbw xmm10, xmm0
    psllw xmm9, 1
    psllw xmm10, 1 
    paddsw xmm14, xmm9                       ; xmm14 = ↙L + ↘L + 2↓L
    paddsw xmm15, xmm10                      ; xmm15 = ↙H + ↙H + 2↓H

    movdqu xmm9, xmm1
    movdqu xmm10, xmm1
    punpcklbw xmm9, xmm0
    punpckhbw xmm10, xmm0
    psubsw xmm14, xmm9                       ; xmm14 = ↙L + ↘L + 2↓L - ↖L
    psubsw xmm15, xmm10                      ; xmm15 = ↙H + ↙H + 2↓H - ↖H

    movdqu xmm9, xmm3
    movdqu xmm10, xmm3
    punpcklbw xmm9, xmm0
    punpckhbw xmm10, xmm0
    psubsw xmm14, xmm9                       ; xmm14 = ↙L + ↘L + 2↓L - ↖L - ↗L
    psubsw xmm15, xmm10                      ; xmm15 = ↙H + ↙H + 2↓H - ↖H - ↗H

    movdqu xmm9, xmm2
    movdqu xmm10, xmm2
    punpcklbw xmm9, xmm0
    punpckhbw xmm10, xmm0
    psllw xmm9, 1
    psllw xmm10, 1 
    ;los componentes no podrian ser negativos porque saturamos
    psubsw xmm14, xmm9                       ; xmm14 = ↙L + ↘L + 2↓L - ↖L - ↗L - 2↑L
    psubsw xmm15, xmm10                      ; xmm15 = ↙H + ↙H + 2↓H - ↖H - ↗H - 2↑H
    ;  xmm14 = GyL
    ;  xmm15 = GyH
    pabsw xmm14, xmm14                      ; xmm14 = abs(GyL)
    pabsw xmm15, xmm15                      ; xmm15 = abs(GyH)

    paddw xmm14, xmm12                     ; xmm14 = abs(GyL) + abs(GxL)
    paddw xmm15, xmm13                     ; xmm15 = abs(GyH) + abs(GxH)

    packuswb xmm14, xmm15                    ; xmm14 = abs(Gy) + abs(Gx)

    ;escribimos en el pixel el resultado        
    movdqu [rsi], xmm14                      ; dst[rsi] = abs(Gy) + abs(Gx)

    ;actualizamos los punteros
    add rdi, rowSize
    add rsi, rowSize
    add r10, rowSize
    add r11, rowSize
    ;avanzamos al siguiente pixel contemplando los casos de estar en el ultimo pixel
    dec r9 
    cmp r9,0
    jne .rows

.endCol:
;avanzamos a la siguiente fila escribiento el ultimo pixel en blanco
movdqu [rsi], xmm11
sub rdx, 16
cmp rdx, 16
jge .cols
cmp rdx, 0
jz .fin
;si no es mayor y tampoco termino, proceso los ultimos 16 pixeles
mov r8, 16
sub r8, rdx
mov rdx, 16
sub rax,r8
sub actualDst,r8
jmp .cols

.fin:
    ; Bordes laterales
    ; rowSize = cols , rcx = filas
    mov rax, rcx                            ; rax = filas
    mul rowSize                             ; rax = filas*cols
    xor r9, r9                              ; r9 = indice
    add r9,rowSize
    mov byte [matrixDst], 0xFF                  ; lateral izq
    mov byte [matrixDst + rowSize - 1], 0xFF                  ; lateral izq
    
.cicloLaterales:
    mov byte [matrixDst + r9], 0xFF                  ; lateral izq
    add r9, rowSize
    mov byte [matrixDst + r9 - 1], 0xFF              ; lateral der
    cmp r9, rax
    jl .cicloLaterales
pop actualDst
pop rowSize
pop matrixDst
pop rbp   
ret