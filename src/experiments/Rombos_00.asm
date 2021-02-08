section .data:

section .rodata
ALIGN 16
zeroTo3seqMask: dw 0x0000,0x0000,0x0002,0x0002,0x0001,0x0001,0x0003,0x0003
constantFFMask: db 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF
constant4Mask: 	times 8 dw 0x4
constant1Mask: 	times 8 dw 0x1
mod64Mask: 		times 8 dw 0x40
sizeDiv2Mask: 	dw 0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020,0x0020
alphaMask: 		db 0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF,0x00,0x00,0x00,0xFF
section .text

global Rombos00_asm

%define v_value xmm0
%define h_value xmm1
%define i_index xmm2
%define j_index xmm3
%define alpha xmm9
%define constFF xmm10
%define sequence0to3 xmm11
%define sizeDiv2 xmm12
%define const1 xmm13
%define const4 xmm14
%define mod64 xmm15

Rombos00_asm:
;uint8_t *src RDI
;uint8_t *dst RSI
;int width	EDX
;int height	ECX
;int src_row_size R8D
;int dst_row_size R9D

shl rcx,32
shr rcx,32
shl rdx,32
shr rdx,32

movdqa sequence0to3,[zeroTo3seqMask] ; xmm10 = | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
movdqa const4,[constant4Mask] ; xmm11 = | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
movdqa mod64,[mod64Mask]    ; 
movdqa sizeDiv2,[sizeDiv2Mask]
movdqa const1,[constant1Mask]
movdqa constFF,[constantFFMask]
movdqa alpha,[alphaMask]

pxor i_index,i_index ; i = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
pxor xmm8,xmm8

.rows:
	mov edx,r8d

	movdqa v_value,sizeDiv2 ; ii = | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |
	psubw v_value,i_index ; ii = | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i |
	pabsw v_value,v_value ; ii = | abs(j0) | abs(j1) | abs(j2) | abs(j3) | abs(j0) | abs(j1) | abs(j2) | abs(j3) |
	
	movdqa j_index,sequence0to3 ; j = | 0 | 0 | 1 | 1 | 2 | 2 | 3 | 3 |

	.cols:

		movdqa h_value,sizeDiv2 ; h_value = | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |
		psubw h_value,j_index ; h_value = | 32-j0 | 32-j0 | 32-j1 | 32-j1 | 32-j2 | 32-j2 | 32-j3 | 32-j3 |
		pabsw h_value,h_value ; h_value = | abs(j0) | abs(j0) | abs(j1) | abs(j1) | abs(j2) | abs(j2) | abs(j3) | abs(j3) |

		paddusw h_value,v_value ; h_value = | j0+i | j0+i | j1+i | j1+i | j2+i | j2+i | j3+i | j3+i |
		psubsw h_value,sizeDiv2 ; v_value = | j0+i | j0+i | j1+i | j1+i | j2+i | j2+i | j3+i | j3+i |
		movdqa xmm4,h_value
		pcmpgtw xmm4,const4
		pxor xmm4,constFF
		pand h_value,xmm4
		paddsw h_value,h_value
		pshuflw xmm4,h_value,0b00000000
		pshufhw xmm4,xmm4,0b00000000
		pshuflw xmm5,h_value,0b10101010
		pshufhw xmm5,xmm5,0b10101010
		movdqu xmm6,[rdi]
		movdqa xmm7,xmm6
		punpcklbw xmm6,xmm8
		punpckhbw xmm7,xmm8
		paddsw xmm4,xmm6
		paddsw xmm5,xmm7
		packuswb xmm4,xmm5
		por xmm4,alpha
		movdqa [rsi],xmm4

		paddusw j_index,const4 ; j = | j0+4 | j0+4 | j1+4 | j1+4 | j2+4 | j2+4 | j3+4 | j3+4 | j4+4 | j4+4 |
        movdqa xmm7,mod64 
        pcmpgtw xmm7,j_index
        pcmpeqw xmm7,xmm8
        pand xmm7,mod64
		psubw j_index,xmm7 ; j = | j0%64 | j0%64 | j1%64 | j1%64 | j2%64 | j2%64 | j3%64 | j3%64 | j4%64 | j4%64 |

		add rdi,16
		add rsi,16
		sub edx,16
		cmp edx,0
		jne .cols
	
	paddusb i_index,const1 ; i = | i+1 | i+1 | i+1 | i+1 | i+1 | i+1 | i+1 | i+1 |
    movdqa xmm7,mod64 
    pcmpgtw xmm7,i_index
    pcmpeqw xmm7,xmm8
    pand xmm7,mod64
    psubw i_index,xmm7 ; i = | i%64 | i%64 | i%64 | i%64 | i%64 | i%64 | i%64 | i%64 |
	
	dec ecx
	cmp ecx,0
	jne .rows
ret
