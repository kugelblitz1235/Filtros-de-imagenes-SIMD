global Bordes_asm

section .data:
section .rodata:
    align 16
    maskWhite: times 16 db 0xFF
    
section .text:
%define matrixDst rbx
Bordes_asm:
    ; rdi = src 
    ; rsi = dst 
    ; edx = cols
    ; ecx = filas
    ; r8d = src_row_size
    ; r9d = dst_row_size
    push rbp
    mov rbp, rsp
    push matrixDst
    mov matrixDst, rsi
    
    ; limpiamos los tamaños
    mov ecx, ecx                            ; rcx = filas
    mov edx, edx                            ; rdx = cols
    ; calculo ultimo centro a evaluar
    mov rax, rcx                            ; rax = filas
    mov r9, rdx                             ; salvo rdx
    mul rdx                                 ; rax = filas*cols
    mov rdx, r9                             ; restauro rdx
    sub rax, rdx                            ; rax = filas*cols - cols
    ; OPTIMIZAR (escribe la ultima fila)
    lea r9, [rdi + rax - 17]                 ; r9 = ultima posicion a evaluar
    lea r8, [rsi + rax - 17]                 ; r8 = ultima posicion a escribir
    
    ; comienzo por la posicion [1,1]
    lea rdi, [rdi + rdx + 1]                ; rdi = src[1,1]
    lea rsi, [rsi + rdx + 1]                ; rsi = dst[1,1]
    
    ; punteros a los inicios de las filas
    mov r10, rdi
    sub r10, rdx                            ; r10 = src[0,1]
    mov r11, rdi                            
    add r11, rdx                            ; r11 = src[2,1]

    ; xmm0 se va a usar para desempaquetar
    pxor xmm0, xmm0
.ciclo:
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

    ; | , , , | , , , | , , , | , , , |
    ;
    ; |  ,  ,  ,  |  ,  ,  
    
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

    ;  escribimos en el pixel el resultado    
    movdqu [rsi], xmm14                      ; dst[rsi] = abs(Gy) + abs(Gx)
    
    ; actualizamos los punteros
    add rdi, 16
    add rsi, 16
    add r10, 16
    add r11, 16

    ; comparamos con el final
    cmp rdi, r9
    jle .ciclo
    sub rdi, 16
    cmp rdi, r9
    je .fin
    mov rdi, r9
    mov rsi, r8 ; Esta mal, r9 es relativo a rdi, no a rsi
    mov r10, r9
    sub r10, rdx
    mov r11, r9
    add r11, rdx
    jmp .ciclo
    ; fin
    
.fin:
    ; Bordes
    ; rdx = cols, rax = filas*cols - cols
    mov rcx, rax                              ; rcx = filas*cols - cols
    add rcx, rdx                              ; rcx = filas*cols
    xor r9, r9                                ; r9 = indice
    add r9,rdx
.cicloLaterales:
    mov byte [matrixDst + r9], 0xFF                  ; lateral izq
    add r9, rdx
    mov byte [matrixDst + r9 - 1], 0xFF              ; lateral der
    cmp r9, rax
    jl .cicloLaterales
    
    movdqu xmm0, [maskWhite]                 ;xmm0 =;|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|0xFF|
    sub rcx, rdx                             ;rcx=filas*columnas - filas
    lea rsi, [matrixDst+rcx]                 ;rsi=dst[filas-1,0]
    ;borde superior e inferior              
.bordesVerticales:
    cmp rdx, 0
    je .finBordes
    movdqu [matrixDst],xmm0                  ;escribo en la primera fila del destino
    movdqu [rsi],      xmm0                 ;escribo en la ultima fila del destino
    sub rdx,16
    add rsi,16
    add matrixDst,16
    jmp .bordesVerticales
.finBordes:
    pop matrixDst
    pop rbp   
    ret









