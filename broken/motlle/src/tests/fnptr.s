	.file	"fnptr.c"
	.arch avr2
__SREG__ = 0x3f
__SP_H__ = 0x3e
__SP_L__ = 0x3d
__tmp_reg__ = 0
__zero_reg__ = 1
_PC_ = 2
gcc2_compiled.:
	.text
.global	g
	.type	g,@function
g:
/* prologue: frame size=0 */
/* prologue end (size=0) */
	ldi r24,lo8(pm(f))
	ldi r25,hi8(pm(f))
	sts (ff)+1,r25
	sts ff,r24
/* epilogue: frame size=0 */
	ret
/* epilogue end (size=1) */
/* function g size 7 (6) */
.Lfe1:
	.size	g,.Lfe1-g
.global	h
	.type	h,@function
h:
/* prologue: frame size=0 */
/* prologue end (size=0) */
	lds r30,ff
	lds r31,(ff)+1
	ldi r24,lo8(0)
	ldi r25,hi8(0)
	icall
/* epilogue: frame size=0 */
	ret
/* epilogue end (size=1) */
/* function h size 8 (7) */
.Lfe2:
	.size	h,.Lfe2-h
	.comm ff,2,1
/* File fnptr.c: code   15 = 0x000f (  13), prologues   0, epilogues   2 */
