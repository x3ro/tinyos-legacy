/*									tab:4
 * Byte-code instruction definitions for mote byte-class interpreter
 *
 * "Copyright (c) 2000 and The Regents of the University 
 * of California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 *  Author: Phil Levis <pal@cs.berkeley.edu>
 *  Date:   Mar 24.2002
 *  DESCR:  Instruction formats for database-centric Mate.
 */

/*

Needed opcodes:
add   (push (add (pop stack) (pop stack)))
        - Different semantics depending on types:
	  value + value -> value        binary addition
	  sense + value -> sense        binary add to sensor reading
	  buf   + value -> message      append value to message payload
	  value + buf   -> message      prepend value to message payload
	  sense + sense -> sense        add sensor readings
	  sense + buf   -> buf          add sensor reading to message payload
	  bufA  + bufB  -> buf         merge buf payloads; bufB truncated
	  


Opcode 

Op code formats:

   base opcode |00000000|  0x00
          thru |00111111|  0x3f
   vclass      |01xxxxxx|  0x40
          thru |11xxxxxx|  0xFF

Shared instructions:

 0  OPhalt      0x00      00000000   
 1  OPland      0x01      00000001   push($0 & $1)
 2  OPlor       0x02      00000010   push($0 | $1)
 3  OPlnot      0x03      00000011   push(~$0)
 4  OPand       0x04      00000100   push($0 && $1)
 5  OPor        0x05      00000101   push($0 || $1)
 6  OPnot       0x06      00000110   push(!$0)
 7  OPshiftr    0x07      00000111   push($0 >> $1) (signed)
 8  OPshiftl    0x08      00001000   push($0 << $1) (signed)
 9  OPadd       0x09      00001001   push($0 + $1) -- depends on types
10  OPmod       0x0a      00001010   push($1 % $0)
11  OPinv       0x0b      00001011   push(-$0)
12  OPid        0x0c      00001100   push(moteID)
13  OPrand      0x0d      00001101   push 16 bit random number onto stack
14  OPsense     0x0e      00001110   push(sensor($0))
15  OPcopy      0x0f      00001111   copy $0 on top of stack

16  OPeq        0x10      00010000   push 1 on stack if $0 == $1, 0 otherwise
17  OPneq       0x11      00010001   push 1 on stack if $0 != $1, 0 otherwise
18  OPlt        0x12      00010010   push 1 on stack if $0 < $1, 0 otherwise
19  OPgt        0x13      00010011   push 1 on stack if $0 > $1, 0 otherwise
20  OPlte       0x14      00010100   push 1 on stack if $0 <= $1, 0 otherwise
21  OPgte       0x15      00010101   push 1 on stack if $0 >= $1, 0 otherwise
22  OPeqtype    0x16      00010110   push 1 on stack if type($0) == type($1)
23  OPpop       0x17      00010111   (pop $0)
24  OPswap      0x18      00011000   swap $0 and $1
25  OPctrue     0x19      00011001   set branch condition variable to 1
26  OPcfalse    0x1a      00011010   set branch condition variable to 0
27  OPcneg      0x1b      00011011   invert branch condition variable
28  OPcpush     0x1c      00011100   push branch cond variable on stack
29  OPcpull     0x1d      00011101   set branch condition variable to $0
30  OPsend      0x1e      00011110   send($0)
31  OPsendr     0x1f      00011111   send($0) with capsule 5

32  OPlogw      0x20      00100000   write log($0)
33  OPlogw2     0x21      00100001   write log line $0 with $1
34  OPlogp      0x22      00100010   push(last log line# used)
35  OPlogr      0x23      00100011   read(line $1 into $0) (buffer @ top)
36  OPbpush0    0x24      00100100   push(buffer0)
37  OPbpush1    0x25      00100101   push(buffer1)
38  OPbpush     0x26      00100110   push(buffer $0)
39  OPbhead     0x27      00100111   push(pull entry off head of $0)
40  OPbtail     0x28      00101000   push(pull entry off tail of $0)
41  OPbnth      0x29      00101001   push($1[$0]) (not remove)
42  OPbyank     0x2a      00101010   push($1[$0]) (remove element)
43  OPbwhich    0x2b      00101011   push 1 if $0 is buffer 1, 0 if buffer 0
44  OPbclear    0x2c      00101100   clear($0)
45  OPbsort     0x2d      00101101   sort $0
46  OPbfull     0x2e      00101110   push 1 if no space in $0, 0 otherwise
47  OPbsize     0x2f      00101111   push # full entries in $0


57  OPdepth     0x39      00111001   push(depth of operand stack)
58  OPuart      0x3a      00111010   Send buffer out on UART
59  OPputled    0x3b      00111011   $1 used as 2-bit cmd + 3-bit oprnd
60  OPcast      0x3c      00111100   push(const($0))
61  OPcall      0x3d      00111101   call $0
62  OPret       0x3e      00111110   return from subproc
63  OPmotectl   0x3f      00111111   execute internal system command
    $0 == 1     - set pot to $1
    $0 == 2     - push(pot setting)
    $0 == 3     - sounder on
     $0 == 4     - sounder off
    $0 == 5     - set clock freqency (how many 32Hz ticks)
    $0 == 6     - set clock counter overflow
    $0 == 7     - push(clock counter)
    $0 == 8     - push(clock frequency)
    $0 == 9     - push(clock overflow)
    $0 == 10    - halt and reset current context

MCLASS
64  OPgetms     0x40-47   01000xxx   push(short xxx from msg header)
72  OPgetmb     0x48-4f   01001xxx   push(byte xxx from msg header)
80  OPsetms     0x50-57   01010xxx   short xxx of msg header = $0
88  OPsetmb     0x58-5f   01011xxx   byte xxx of msg header = $0

VCLASS
96  OPgetvar    0x60-6f   0110xxxx   push variable xxxx
112 OPsetvar    0x70-7f   0111xxxx   variable xxxx = $0

JCLASS
128 OPjumpc     0x80-9f   100xxxxx   if (cond) (jump xarg, cond--)
160 OPjumps     0xa0-bf   101xxxxx   if ($0) (jump xarg)

XCLASS
192 OPpushc     0xc0-ff   11xxxxxx   push(xarg)  (unsigned)
*/

#ifndef MATE_DB_H_INCLUDED
#define MATE_DB_H_INCLUDED
/*
   Base clase |00oooooo|
*/

/* Zero operand instructions */
#define OPhalt      0x00
#define OPid        0x01
#define OPrand      0x02
#define OPctrue     0x03
#define OPcfalse    0x04
#define OPcpush     0x05
#define OPlogp      0x06
#define OPbpush0    0x07
#define OPbpush1    0x08
#define OPdepth     0x09
#define OPerr       0x0a
#define OPret       0x0b
#define OPcall0     0x0c
#define OPcall1     0x0d
#define OPcall2     0x0e
#define OPcall3     0x0f

#define is_call(instr) (((instr) & 0xfc) == 0x0c)
#define carg(instr) ((instr) & 0x3)

/* One operand instructions */
#define OPinv       0x10
#define OPsense     0x11
#define OPcopy      0x12
#define OPnot       0x13
#define OPpop       0x14
#define OPsend      0x15
#define OPsendr     0x16
#define OPuart      0x17
#define OPcpull     0x18
#define OPlogw      0x19
#define OPbpush     0x1a
#define OPbhead     0x1b 
#define OPbtail     0x1c
#define OPbwhich    0x1d
#define OPbclear    0x1e
#define OPbsize     0x1f


#define OPbsorta    0x20
#define OPbsortd    0x21
#define OPbfull     0x22
#define OPcall      0x23
#define OPputled    0x24
#define OPcast      0x25
#define OPlnot      0x26
#define OPunlock    0x27
#define OPunlockb   0x28
#define OPpunlock   0x29
#define OPpunlockb  0x2a

/* Two-operand instructions */
#define OPlogwl     0x2b
#define OPlogr      0x2c
#define OPbnth      0x2d
#define OPbyank     0x2e
/* Special instruction */
#define OPmotectl   0x2f

/* Two operand-instructions */
#define OPswap      0x30
#define OPland      0x31
#define OPlor       0x32
#define OPand       0x33
#define OPor        0x34
#define OPshiftr    0x35
#define OPshiftl    0x36
#define OPadd       0x37
#define OPmod       0x38
#define OPeq        0x39
#define OPneq       0x3a
#define OPlt        0x3b
#define OPgt        0x3c
#define OPlte       0x3d
#define OPgte       0x3e
#define OPeqtype    0x3f



/*   mclass   */
#define OPgetms     0x40
#define OPgetmb     0x48
#define OPsetms     0x50
#define OPsetmb     0x58

/*   vclass  */
#define OPgetvar    0x60
#define OPsetvar    0x70

/*   jclass   */
#define OPjumpc     0x80
#define OPjumps     0xa0

/*   xclass   */
#define OPpushc     0xc0

#define margmask      0x07
#define mopmask       0xf8
#define mclassmask    0xe0
#define marg(op)      ((op) & margmask)
#define mop(op)       ((op) & mopmask)
#define is_mclass(op) (((op) & mclassmask) == 0x40)

#define vargmask      0x0f
#define vopmask       0xf0
#define vclassmask    0xe0
#define varg(op)      ((op) & vargmask)
#define vop(op)       ((op) & vopmask)
#define is_vclass(op) (((op) & vclassmask) == 0x60)

#define jargmask      0x1f
#define jopmask       0xe0
#define jclassmask    0xc0
#define jarg(op)      ((op) & jargmask)
#define jop(op)       ((op) & jopmask)
#define is_jclass(op) (((op) & jclassmask) == 0x80)

#define xargmask      0x3f
#define xopmask       0xc0
#define xarg(op)      ((op) & xargmask)
#define is_xclass(op) (((op) & xopmask) == xopmask)

#endif
