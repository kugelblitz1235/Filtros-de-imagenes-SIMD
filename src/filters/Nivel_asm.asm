section .data:
section .rodata:
    ALIGN 16
    mask0: times 16 db 0x00
    const1: times 16 db 0x01
    alpha: db 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF

section .text:

    global Nivel_asm
    Nivel_asm:
    ;uint8_t *src RDI
    ;uint8_t *dst RSI
    ;int width  EDX
    ;int height ECX
    ;int src_row_size R8D
    ;int dst_row_size R9D
    ;int n RSP
    
    mov ecx,ecx                           ;limpiamos la parte alta de los registros que poseen los tamaños
    mov edx,edx                           
    
    movdqa xmm15,[alpha]                  ;xmm15 =|0x00|0x00|0x00|0xFF|0x00|0x00|0x00|0xFF|0x00|0x00|0x00|0xFF|0x00|0x00|0x00|0xFF|
    movdqa xmm14,[const1]                 ;xmm14 =|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01| 
    
    mov r10d,[rsp+8]                      ;r10d=|----|  n  |
    movdqa xmm0,xmm14                     ;xmm0= |0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|0x01|
    movd xmm1,r10d                        ;xmm1 =|0x0000|0x0000|0x0000|0x0000|       indice        |
    psllw xmm0,xmm1                       ;xmm0=|1<<indice|1<<indice|1<<indice|1<<indice|
    movdqa xmm14,xmm0                     ;xmm14|1<<indice|1<<indice|1<<indice|1<<indice|
    
    .rows:
      mov edx,r8d                         ;actualizo el tamaño de la fila, para una fila nueva
    
      .cols:                              ;itero avanzando sobre el ancho
        movdqu xmm1,[rdi]                 ;levantamos los 4 pixeles indicados a partir del puntero de source
        pand xmm1,xmm0                    ;deja en xmm0 todos los bits de cada canal en cero ecxepto el indicado por el indice
        pcmpeqb xmm1,xmm14                ;deja todos los canales de cada pixel en FF exepto el indicado por el indice
    
        por xmm1,xmm15                    ;escribimos 0xFF en el canal alpha de cada pixel 
        movdqa [rsi],xmm1                 ;escribimos en en el destino el resultado
    
        add rdi,16                        ;avanzamos los punteros y decrementamos el ancho de lo que avanzamos
        add rsi,16
        sub edx,16
        cmp edx,0
        jne .cols                         ;avanzamos a la siguiente columna si la fila no termino
      
      dec ecx
      cmp ecx,0                           ;avanzamos a la siguiente fila si se terminaron las columnas
      jne .rows
    ret                                  
