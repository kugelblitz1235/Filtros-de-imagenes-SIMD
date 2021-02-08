section .data:

section .rodata
ALIGN 16
sequence0to7Mask: db 0,0,1,1,4,4,5,5,2,2,3,3,6,6,7,7
section .text

global Rombos02_asm

%define v_value xmm0
%define h_value xmm1
%define i_index xmm2
%define j_index xmm3
%define FFMask xmm7
%define zeroMask xmm8
%define alpha xmm9
%define mod64 xmm10
%define sequence0to7 xmm11
%define sizeDiv2 xmm12
%define const1 xmm13
%define const4 xmm14
%define const8 xmm15

Rombos02_asm:
;uint8_t *src RDI
;uint8_t *dst RSI
;int width	EDX
;int height	ECX
;int src_row_size R8D
;int dst_row_size R9D

mov ecx,ecx
mov edx,edx

movdqa sequence0to7,[sequence0to7Mask] ; xmm10 = | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |

mov r10d,0xFF000000
movd alpha,r10d
pshufd alpha,alpha,0 ;alpha = 0 | 0 | 0 | 255 | 0 | 0 | 0 | 255 | 0 | 0 | 0 | 255 | 0 | 0 | 0 | 255 |

mov r10d,0x20202020
movd sizeDiv2,r10d
pshufd sizeDiv2,sizeDiv2,0 ;sizeDiv2 = 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |

mov r10d,0x3F3F3F3F
movd mod64,r10d
pshufd mod64,mod64,0 		;sizeDiv2 = 63 | 63 | 63 | 63 | 63 | 63 | 63 | 63 |

mov r10d,0x01010101
movd const1,r10d
pshufd const1,const1,0  	;const1 = 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
movdqa const4,const1
psllw const4,2  			;const2 = 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 |
movdqa const8,const1
psllw const8,3				;const8 = 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |

pxor i_index,i_index ; i = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
pxor zeroMask,zeroMask ; zeroMask = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
pcmpeqb FFMask,FFMask
.rows:
	mov edx,r8d

	movdqa v_value,sizeDiv2 ; ii = | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |
	psubb v_value,i_index ; ii = | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i |
	pabsb v_value,v_value ; ii = | abs(i) | abs(i) | abs(i) | abs(i) | abs(i) | abs(i) | abs(i) | abs(i)
	
	movdqa j_index,sequence0to7 ; j = | 0 | 2 | 4 | 6 | 1 | 3 | 5 | 7 |

	.cols:

		movdqa h_value,sizeDiv2 ; h_value = | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |
		psubsb h_value,j_index ; h_value = | 32-j0 | 32-j2 | 32-j4 | 32-j6 | 32-j1 | 32-j3 | 32-j5 | 32-j7 |
		pabsb h_value,h_value ; h_value = | abs(32-j0) | abs(32-j2) | abs(32-j4) | abs(32-j6) | abs(32-j1) | abs(32-j3) | abs(32-j5) | abs(32-j7) |

		paddsb h_value,v_value ; h_value = | jj0+ii | jj2+ii | jj4+ii | jj6+ii | jj1+ii | jj3+ii | jj5+ii | jj7+ii |
		psubsb h_value,sizeDiv2 ; h_value = | jj0+ii-32 | jj2+ii-32 | jj4+ii-32 | jj6+ii-32 | jj1+ii-32 | jj3+ii-32 | jj5+ii-32 | jj7+ii-32 |
		movdqa xmm4,h_value ; xmm4 = | x0 | x2 | x4 | x6 | x1 | x3 | x5 | x7 |
		pcmpgtb xmm4,const4 ; xmm4 = | x0 > 4 | x2 > 4 | x4 > 4 | x6 > 4 | x1 > 4 | x3 > 4 | x5 > 4 | x7 > 4 |
		pcmpeqb xmm4,zeroMask ; xmm4 = | ~(x0 > 4) | ~(x2 > 4) | ~(x4 > 4) | ~(x6 > 4) | ~(x1 > 4) | ~(x3 > 4) | ~(x5 > 4) | ~(x7 > 4) |
		pand h_value,xmm4 ; h_value = | ~(x0 > 4) & x0 | ~(x2 > 4) & x2 | ~(x4 > 4) & x4  | ~(x6 > 4) & x6  | ~(x1 > 4) & x1  | ~(x3 > 4) & x3  | ~(x5 > 4) & x5  | ~(x7 > 4) & x7  |
		paddsb h_value,h_value ; h_value = | x0*2 | x2*2 | x4*2 | x6*2 | x1*2 | x3*2 | x5*2 | x7*2 |
		


		pshuflw xmm4,h_value,0b01010000 ; xmm4 = | x0 | x0 | x0 | x0 | x1 | x3 | x5 | x7 |
		pshufhw xmm4,xmm4,0b01010000 ; xmm4 = | x0 | x0 | x0 | x0 | x1 | x1 | x1 | x1 |
	
		movdqa xmm5,zeroMask
		pcmpgtb xmm5,xmm4
		pand xmm5,xmm4
		pxor xmm5,FFMask
		paddb xmm5,const1
		movdqu xmm6,[rdi] 
		psubusb xmm6,xmm5

		movdqa xmm5,xmm4
		pcmpgtb xmm5,zeroMask
		pand xmm4,xmm5
		paddusb xmm6,xmm4 
		por xmm6,alpha
		movdqa [rsi],xmm6



		pshuflw xmm4,h_value,0b11111010
		pshufhw xmm4,xmm4,0b11111010
		
		movdqa xmm5,zeroMask
		pcmpgtb xmm5,xmm4
		pand xmm5,xmm4
		pxor xmm5,FFMask
		paddb xmm5,const1
		movdqu xmm6,[rdi+16]
		psubusb xmm6,xmm5

		movdqa xmm5,xmm4
		pcmpgtb xmm5,zeroMask
		pand xmm4,xmm5
		paddusb xmm6,xmm4
		por xmm6,alpha 
		movdqa [rsi+16],xmm6

		paddusb j_index,const8
		pand j_index,mod64

		add rdi,32
		add rsi,32
		sub edx,32
		cmp edx,0
		jne .cols
	
	paddusb i_index,const1 ; i = | i+1 | i+1 | i+1 | i+1 | i+1 | i+1 | i+1 | i+1 |
	pand i_index,mod64 ; i = | i%64 | i%64 | i%64 | i%64 | i%64 | i%64 | i%64 | i%64 |
	
	dec ecx
	cmp ecx,0
	jne .rows
ret
