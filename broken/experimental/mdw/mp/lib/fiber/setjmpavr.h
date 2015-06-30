/* MDW: This file is taken from the AVR-libc distribution. It is placed
 * here because we need to ensure that when building for the AVR, we pick
 * up this definition of setjmp.h rather than the default.
 */

#ifndef __SETJMP_H_
#define __SETJMP_H_ 1

/*
   jmp_buf:
	offset	size	description
	 0	16	call-saved registers (r2-r17)
	16	 2	frame pointer (r29:r28)
	18	 2	stack pointer (SPH:SPL)
	20	 1	status register (SREG)
	21	 3	return address (PC) (2 bytes used for <=128K flash)
	24 = total size
 */

typedef struct {
	/* call-saved registers */
	unsigned char __j_r2;
	unsigned char __j_r3;
	unsigned char __j_r4;
	unsigned char __j_r5;
	unsigned char __j_r6;
	unsigned char __j_r7;
	unsigned char __j_r8;
	unsigned char __j_r9;
	unsigned char __j_r10;
	unsigned char __j_r11;
	unsigned char __j_r12;
	unsigned char __j_r13;
	unsigned char __j_r14;
	unsigned char __j_r15;
	unsigned char __j_r16;
	unsigned char __j_r17;
	/* frame pointer, stack pointer, status register, program counter */
	unsigned int __j_fp;  /* Y */
	unsigned int __j_sp;
	unsigned char __j_sreg;
	unsigned int __j_pc;
	unsigned char __j_pch;  /* only devices with >128K bytes of flash */
} jmp_buf[1];

#ifndef __ATTR_NORETURN__
#define __ATTR_NORETURN__ __attribute__((__noreturn__))
#endif

extern int setjmp(jmp_buf __jmpb);
extern void longjmp(jmp_buf __jmpb, int __ret) __ATTR_NORETURN__;

#endif  /* !__SETJMP_H_ */
