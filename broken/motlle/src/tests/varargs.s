	.file	"varargs.c"
	.arch avr2
__SREG__ = 0x3f
__SP_H__ = 0x3e
__SP_L__ = 0x3d
__tmp_reg__ = 0
__zero_reg__ = 1
_PC_ = 2
gcc2_compiled.:
	.text
.global	f
	.type	f,@function
f:
/* prologue: frame size=0 */
	push r28
	push r29
	in r28,__SP_L__
	in r29,__SP_H__
/* prologue end (size=4) */
	ldi r24,lo8(5)
	ldi r25,hi8(5)
	add r24,r28
	adc r25,r29
	mov r22,r24
	mov r23,r25
	mov r31,r23
	mov r30,r22
	ld r24,Z+
	mov r22,r30
	mov r23,r31
	ldi r18,lo8(0)
	ldi r19,hi8(0)
	clr r25
	sbrc r24,7
	com r25
	cp r18,r24
	cpc r19,r25
	brge .L8
	mov r21,r19
	mov r20,r18
	mov r18,r24
	mov r19,r25
.L6:
	mov r31,r21
	mov r30,r20
	subi r30,lo8(-(foo))
	sbci r31,hi8(-(foo))
	mov r27,r23
	mov r26,r22
	subi r22,lo8(-(2))
	sbci r23,hi8(-(2))
	ld r24,X+
	ld r25,X
	st Z,r24
	std Z+1,r25
	subi r20,lo8(-(2))
	sbci r21,hi8(-(2))
	subi r18,lo8(-(-1))
	sbci r19,hi8(-(-1))
	brne .L6
.L8:
/* epilogue: frame size=0 */
	pop r29
	pop r28
	ret
/* epilogue end (size=3) */
/* function f size 49 (42) */
.Lfe1:
	.size	f,.Lfe1-f
.global	g
	.type	g,@function
g:
/* prologue: frame size=0 */
/* prologue end (size=0) */
	lds r24,z
	lds r25,(z)+1
	push r25
	push r24
	lds r24,y
	lds r25,(y)+1
	push r25
	push r24
	lds r24,x
	lds r25,(x)+1
	push r25
	push r24
	ldi r24,lo8(1)
	push r24
	rcall f
	in r24,__SP_L__
	in r25,__SP_H__
	adiw r24,7
	in __tmp_reg__,__SREG__
	cli
	out __SP_H__,r25
	out __SREG__,__tmp_reg__
	out __SP_L__,r24
/* epilogue: frame size=0 */
	ret
/* epilogue end (size=1) */
/* function g size 30 (29) */
.Lfe2:
	.size	g,.Lfe2-g
	.comm foo,6,1
	.comm x,2,1
	.comm y,2,1
	.comm z,2,1
/* File varargs.c: code   79 = 0x004f (  71), prologues   4, epilogues   4 */
