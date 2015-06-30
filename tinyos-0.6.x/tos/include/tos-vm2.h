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
 *  Date:   Feb 6.2002
 *  DESCR:  Instruction formats for TinyOS VM; borrows heavily from Culler's
 *          previous implementation.
 *
 */

/*

Needed opcodes:
pushm (push message)    System wide constant message (storage)
pushc (push constant)

copy  (push (car stack) stack)
pop   (pop stack)

or    (push (or (pop stack) (pop stack)))
and   (push (and (pop stack) (pop stack)))
shift ($0 = (pop stack), $1 = (pop stack), (push (shift $1 $0)))
add   (push (add (pop stack) (pop stack)))
        - Different semantics depending on types:
	  value + value -> value        binary addition
	  sense + value -> sense        binary add to sensor reading
	  msg   + value -> message      add value to message payload
	  sense + sense -> sense        add sensor readings
	  sense + msg   -> msg          add sensor reading to message payload
	  msgA  + msgB   -> msg         merge msg payloads; msgB truncated
	  
inv   (push (- (pop stack)))	  
id    (push (moteID))
leds  (set-leds (pop stack))
send  (send (pop stack))
recv  (push (recv))                 has a timeout; buffer provided if expired


Opcode 


Op code formats:

   base opcode |00000000|  0x00
          thru |00111111|  0x3f
   vclass      |01xxxxxx|  0x40
          thru |11xxxxxx|  0xFF

Shared instructions:

 0  OPhalt      0x00      00000000   
 1  OPreset     0x01      00000001   Clear stack
 2  OPand       0x02      00000010   push($0 & $1)
 3  OPor        0x03      00000011   push($0 | $1)
 4  OPshiftr    0x04      00000100   push($0 >> $1) (signed)
 5  OPshiftl    0x05      00000101   push($0 << $1) (signed)
 6  OPadd       0x06      00000110   push($0 + $1) -- depends on types
 8  OPputled    0x08      00001000   $1 used as 2-bit cmd + 3-bit oprnd
 9  OPid        0x09      00001001   push(moteID)
10  OPinv       0x0a      00001010   push(-$0)
11  OPcopy      0x0b      00010000   copy $0 on top of stack
12  OPpop       0x0c      00001100   (pop $0)
13  OPsense     0x0d      00001101   push(sensor($0))
14  OPsend      0x0e      00001110   send($0)
15  OPsendr     0x0f      00001111   send($0) with capsule 5
16  OPcast      0x10      00010000   push(const($0))
17  OPpushm     0x11      00010001   push(message)
18  OPmovm      0x12      00010010   push(pull entry off $0)
19  OPclear     0x13      00010011   clear($0), don't pop it
20  OPson       0x14      00010100   Turn sounder on
21  OPsoff      0x15      00010101   Turn sounder off
22  OPnot       0x16      00010110   push(~$0)
23  OPlog       0x17      00010111   log($0)
24  OPlogr      0x18      00011000   read(line $2 into) (msg top of stack)
25  OPlogr2     0x19      00011001   read(line $0 into $1) (keep $1 on stack)

26  OPsets      0x1a      00011010   set shared variable to $0
27  OPgets      0x1b      00011011   push(shared variable)

28  OPrand      0x1c      00011100   push 16 bit random number onto stack

29  OPeq        0x1d      00011100   push 1 on stack if $0 == $1, 0 otherwise
30  OPneq       0x1e      00011101   push 1 on stack if $0 != $1, 0 otherwise
31  OPcall      0x1f      00011111   call $0

32  OPswap      0x20      00100000   swap $0 and $1
46  OPforw      0x2e      00101110   forward this code capsule
47  OPforwo     0x2f      00101111   forward capsule $10

48  OPusr0      0x30      00110000   user instruction 0
49  OPusr1      0x31      00110001   user instruction 1
50  OPusr2      0x32      00110010   user instruction 2
51  OPusr3      0x33      00110011   user instruction 3
52  OPusr4      0x34      00110100   user instruction 4
53  OPusr5      0x35      00110101   user instruction 5
54  OPusr6      0x36      00110110   user instruction 6
55  OPusr7      0x37      00110111   user instruction 7

58  OPsetgrp    0x3a      00111010   set group id to $0
59  OPpot       0x3b      00111011   push(potentiometer setting)
60  OPpots      0x3c      00111100   Set potentiometer setting to $0
61  OPclockc    0x3d      00111101   set clock counter with $0
62  OPclockf    0x3e      00111110   set clock freq with $0
63  OPret       0x3f      00111111   return from subroutine

SCLASS
64  OPgetms     0x40-47   01000xxx   push(short xxx from msg header)
72  OPgetmb     0x48-4f   01001xxx   push(byte xxx from msg header)
80  OPgetfs     0x50-57   01010xxx   push(short xxx from frame)
88  OPgetfb     0x58-5f   01011xxx   push(byte xxx from frame)
96  OPsetms     0x60-67   01100xxx   short xxx of msg header = $0
102 OPsetmb     0x68-6f   01101xxx   byte xxx of msg header = $0
108 OPsetfs     0x70-77   01110xxx   short xxx of frame = $0
114 OPsetfb     0x78-7f   01111xxx   byte xxx of frame = $0

XCLASS
128 OPpushc     0x80-bf   01xxxxxx   push(xarg)  (unsigned)
192 OPblez      0xC0-ff   10xxxxxx   if ($0 <= 0) jump xarg

Msg specific
*/

#ifndef TOS_VM2_H_INCLUDED
#define TOS_VM2_H_INCLUDED

#define PGMSIZE 24

/* Types of capsules */
#define CAPSULE_NUM   7 /* How many capsules there are */
#define CAPSULE_SUB0  0
#define CAPSULE_SUB1  1
#define CAPSULE_SUB2  2
#define CAPSULE_SUB3  3
#define CAPSULE_CLOCK 4
#define CAPSULE_SEND  5
#define CAPSULE_RECV  6

typedef struct {
  char type;
  char version;
  char code[PGMSIZE];
} capsule_t;

#define is_xclass(op) (op & 0x80)
#define is_sclass(op) (((op) & 0xC0) == 0x40)
/*
   Base clase |0000oooo|
*/

/* Zero operand */

#define OPhalt      0x00
#define OPreset     0x01
#define OPrand      0x02
#define OPid        0x03
#define OPpot       0x04
#define OPgets      0x05
#define OPpushm     0x06
#define OPret       0x07
#define OPson       0x08
#define OPsoff      0x09
#define OPforw      0x0a

/* One operand */
#define OPputled    0x10
#define OPinv       0x11
#define OPcopy      0x12
#define OPpop       0x13
#define OPsense     0x14
#define OPsend      0x15   // Send a packet with default routing protocol
#define OPsendr     0x16   // Send a raw packet
#define OPcast      0x17
#define OPclear     0x18
#define OPnot       0x19
#define OPcall      0x1a
#define OPuart      0x1b
#define OPforwo     0x1c
#define OPsetgrp    0x1d
#define OPlog       0x1e
#define OPmovm      0x1f

/* Basic Binary Operators with result*/
#define OPand       0x20
#define OPor        0x21
#define OPshiftr    0x22
#define OPshiftl    0x23
#define OPadd       0x24
#define OPsets      0x25
#define OPeq        0x26
#define OPneq       0x27
#define OPswap      0x28
#define OPlogr      0x29
#define OPlogr2     0x2a

#define binaryop(op) (op && (op <= OPshift)))

/* User Instructions */

#define OPusr0      0x30
#define OPusr1      0x31
#define OPusr2      0x32
#define OPusr3      0x33
#define OPusr4      0x34
#define OPusr5      0x35
#define OPusr6      0x36
#define OPusr7      0x37

#define OPpots      0x1e
#define OPclockc    0x1f
#define OPclockf    0x3e


/*   sclass   */
#define OPgetms     0x40
#define OPgetmb     0x48
#define OPsetms     0x50
#define OPsetmb     0x58
#define OPgetfs     0x60
#define OPgetfb     0x68
#define OPsetfs     0x70
#define OPsetfb     0x78

/*   xclass   */
#define OPblez      0x80
#define OPpushc     0xC0

#define xmask       0x1F
#define xsignbit    0x20
#define xopmask     0xC0
#define xarg(op) ((op) & xmask)

#define smask       0x7
#define sopmask     0xf8
#define sarg(op) ((op) & smask)
#define sop(op)  ((op) & sopmask)

#endif
