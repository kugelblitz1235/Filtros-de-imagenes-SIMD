section .data:

section .rodata
ALIGN 16
sequence0to7Mask: dw 0x0000,0x0002,0x0004,0x0006,0x0001,0x0003,0x0005,0x0007
section .text

global Rombos_asm

%define v_value xmm0
%define h_value xmm1
%define i_index xmm2
%define j_index xmm3
%define zeroMask xmm8
%define alpha xmm9
%define mod64 xmm10
%define sequence0to7 xmm11
%define sizeDiv2 xmm12
%define const1 xmm13
%define const4 xmm14
%define const8 xmm15

Rombos_asm:
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

mov r10d,0x200020
movd sizeDiv2,r10d
pshufd sizeDiv2,sizeDiv2,0 ;sizeDiv2 = 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |

mov r10d,0x3F003F
movd mod64,r10d
pshufd mod64,mod64,0 		;sizeDiv2 = 63 | 63 | 63 | 63 | 63 | 63 | 63 | 63 |

mov r10d,0x10001
movd const1,r10d
pshufd const1,const1,0  	;const1 = 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
movdqa const4,const1
psllw const4,2  			;const2 = 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 |
movdqa const8,const1
psllw const8,3				;const8 = 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |

pxor i_index,i_index ; i = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
pxor zeroMask,zeroMask ; zeroMask = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

.rows:
	mov edx,r8d

	movdqa v_value,sizeDiv2 ; ii = | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |
	psubw v_value,i_index ; ii = | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i | 32-i |
	pabsw v_value,v_value ; ii = | abs(i) | abs(i) | abs(i) | abs(i) | abs(i) | abs(i) | abs(i) | abs(i)
	
	movdqa j_index,sequence0to7 ; j = | 0 | 2 | 4 | 6 | 1 | 3 | 5 | 7 |

	.cols:

		movdqa h_value,sizeDiv2 ; h_value = | 32 | 32 | 32 | 32 | 32 | 32 | 32 | 32 |
		psubw h_value,j_index ; h_value = | 32-j0 | 32-j2 | 32-j4 | 32-j6 | 32-j1 | 32-j3 | 32-j5 | 32-j7 |
		pabsw h_value,h_value ; h_value = | abs(32-j0) | abs(32-j2) | abs(32-j4) | abs(32-j6) | abs(32-j1) | abs(32-j3) | abs(32-j5) | abs(32-j7) |

		paddusw h_value,v_value ; h_value = | jj0+ii | jj2+ii | jj4+ii | jj6+ii | jj1+ii | jj3+ii | jj5+ii | jj7+ii |
		psubsw h_value,sizeDiv2 ; h_value = | jj0+ii-32 | jj2+ii-32 | jj4+ii-32 | jj6+ii-32 | jj1+ii-32 | jj3+ii-32 | jj5+ii-32 | jj7+ii-32 |
		movdqa xmm4,h_value ; xmm4 = | x0 | x2 | x4 | x6 | x1 | x3 | x5 | x7 |
		pcmpgtw xmm4,const4 ; xmm4 = | x0 > 4 | x2 > 4 | x4 > 4 | x6 > 4 | x1 > 4 | x3 > 4 | x5 > 4 | x7 > 4 |
		pcmpeqw xmm4,zeroMask ; xmm4 = | ~(x0 > 4) | ~(x2 > 4) | ~(x4 > 4) | ~(x6 > 4) | ~(x1 > 4) | ~(x3 > 4) | ~(x5 > 4) | ~(x7 > 4) |
		pand h_value,xmm4 ; h_value = | ~(x0 > 4) & x0 | ~(x2 > 4) & x2 | ~(x4 > 4) & x4  | ~(x6 > 4) & x6  | ~(x1 > 4) & x1  | ~(x3 > 4) & x3  | ~(x5 > 4) & x5  | ~(x7 > 4) & x7  |
		paddsw h_value,h_value ; h_value = | x0*2 | x2*2 | x4*2 | x6*2 | x1*2 | x3*2 | x5*2 | x7*2 |
		
		pshuflw xmm4,h_value,0b00000000 ; xmm4 = | x0 | x0 | x0 | x0 | x1 | x3 | x5 | x7 |
		pshufhw xmm4,xmm4,0b00000000 ; xmm4 = | x0 | x0 | x0 | x0 | x1 | x1 | x1 | x1 |
		pshuflw xmm5,h_value,0b01010101 ; xmm5 = | x2 | x2 | x2 | x2 | x1 | x3 | x5 | x7 |
		pshufhw xmm5,xmm5,0b01010101 ; xmm5 = | x2 | x2 | x2 | x2 | x3 | x3 | x3 | x3 |
		movdqu xmm6,[rdi] ; xmm6 = | p0r | p0g | p0b | p0a | p1r | p1g | p1b | p1a | p2r | p2g | p2b | p2a | p3r | p3g | p3b | p3a |
		movdqa xmm7,xmm6 ; xmm7 = | p0r | p0g | p0b | p0a | p1r | p1g | p1b | p1a | p2r | p2g | p2b | p2a | p3r | p3g | p3b | p3a |
		punpcklbw xmm6,zeroMask ; xmm6 = | p0r | p0g | p0b | p0a | p1r | p1g | p1b | p1a |
		punpckhbw xmm7,zeroMask ; xmm7 = | p2r | p2g | p2b | p2a | p3r | p3g | p3b | p3a |
		paddsw xmm4,xmm6 ; xmm4 = | p0r+x0 | p0g+x0 | p0b+x0 | p0a+x0 | p1r+x1 | p1g+x1 | p1b+x1 | p1a+x1 |
		paddsw xmm5,xmm7 ; xmm5 = | p2r+x2 | p2g+x2 | p2b+x2 | p2a+x2 | p3r+x3 | p3g+x3 | p3b+x3 | p3a+x3 |
		packuswb xmm4,xmm5 ; xmm4 =  | p0r+x0 | p0g+x0 | p0b+x0 | p0a+x0 | p1r+x1 | p1g+x1 | p1b+x1 | p1a+x1 | p2r+x2 | p2g+x2 | p2b+x2 | p2a+x2 | p3r+x3 | p3g+x3 | p3b+x3 | p3a+x3 |
		por xmm4,alpha ; xmm4 =  | p0r+x0 | p0g+x0 | p0b+x0 | 255 | p1r+x1 | p1g+x1 | p1b+x1 | 255 | p2r+x2 | p2g+x2 | p2b+x2 | 255 | p3r+x3 | p3g+x3 | p3b+x3 | 255 |
		movdqa [rsi],xmm4 ; [dst] =  | p0r+x0 | p0g+x0 | p0b+x0 | 255 | p1r+x1 | p1g+x1 | p1b+x1 | 255 | p2r+x2 | p2g+x2 | p2b+x2 | 255 | p3r+x3 | p3g+x3 | p3b+x3 | 255 |

		pshuflw xmm4,h_value,0b10101010 ; xmm4 = | x4 | x4 | x4 | x4 | x1 | x3 | x5 | x7 |
		pshufhw xmm4,xmm4,0b10101010 ; xmm4 = | x4 | x4 | x4 | x4 | x5 | x5 | x5 | x5 |
		pshuflw xmm5,h_value,0b11111111 ; xmm5 = | x6 | x6 | x6 | x6 | x1 | x3 | x5 | x7 |
		pshufhw xmm5,xmm5,0b11111111 ; xmm5 = | x6 | x6 | x6 | x6 | x7 | x7 | x7 | x7 |
		movdqu xmm6,[rdi+16] ; xmm6 = | p4r | p4g | p4b | p4a | p5r | p5g | p5b | p5a | p6r | p6g | p6b | p6a | p7r | p7g | p7b | p7a |
		movdqa xmm7,xmm6 ; xmm7 = | p4r | p4g | p4b | p4a | p5r | p5g | p5b | p5a | p6r | p6g | p6b | p6a | p7r | p7g | p7b | p7a |
		punpcklbw xmm6,zeroMask ; xmm6 = | p4r | p4g | p4b | p4a | p5r | p5g | p5b | p5a |
		punpckhbw xmm7,zeroMask ; xmm7 = | p6r | p6g | p6b | p6a | p7r | p7g | p7b | p7a |
		paddsw xmm4,xmm6 ; xmm4 = | p4r+x4 | p4g+x4 | p4b+x4 | p4a+x4 | p5r+x5 | p5g+x5 | p5b+x5 | p5a+x5 |
		paddsw xmm5,xmm7 ; xmm5 = | p6r+x6 | p6g+x6 | p6b+x6 | p6a+x6 | p7r+x7 | p7g+x7 | p7b+x7 | p7a+x7 |
		packuswb xmm4,xmm5 ; xmm4 = | p4r+x4 | p4g+x4 | p4b+x4 | p4a+x4 | p5r+x5 | p5g+x5 | p5b+x5 | p5a+x5 | p6r+x6 | p6g+x6 | p6b+x6 | p6a+x6 | p7r+x7 | p7g+x7 | p7b+x7 | p7a+x7 |
		por xmm4,alpha ; xmm4 = | p4r+x4 | p4g+x4 | p4b+x4 | 255 | p5r+x5 | p5g+x5 | p5b+x5 | 255 | p6r+x6 | p6g+x6 | p6b+x6 | 255 | p7r+x7 | p7g+x7 | p7b+x7 | 255 |
		movdqa [rsi+16],xmm4 ; [dst+16] = | p4r+x4 | p4g+x4 | p4b+x4 | 255 | p5r+x5 | p5g+x5 | p5b+x5 | 255 | p6r+x6 | p6g+x6 | p6b+x6 | 255 | p7r+x7 | p7g+x7 | p7b+x7 | 255 |

		paddusw j_index,const8 ; j = | j0+8 | j2+8 | j4+8 | j6+8 | j1+8 | j3+8 | j5+8 | j7+8 |
		pand j_index,mod64 ; j = | (j0+8)%64 | (j2+8)%64 | (j4+8)%64 | (j6+8)%64 | (j1+8)%64 | (j3+8)%64 | (j5+8)%64 | (j7+8)%64 |

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
