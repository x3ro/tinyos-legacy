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
 2  OPand       0x02      00000010   $2 = $1 & $2 
 3  OPor        0x03      00000011   $2 = $1 | $2
 4  OPshift     0x04      00000100   $2 = $1 >> $2 (signed)
 5  OPshiftl    0x05      00000101   $2 = $1 << $2 (signed)
 6  OPadd       0x06      00000110   $2 = $1 + $2
 8  OPputled    0x08      00001000   TOS used as 2-bit cmd + 3-bit oprnd
 9  OPid        0x09      00001001   $0 <= moteID
10  OPinv       0x0a      00001010   $1 = -$1
11  OPcopy      0x0b      00010000   $0 = $1
12  OPpop       0x0c      00001100   (pop $1)
13  OPsense     0x0d      00001101   $1 <= sensor($1)
14  OPsend      0x0e      00001110   send($1) (pop $1)
16  OPcast      0x10      00010000   $1 = const($1)
17  OPpushm     0x11      00010001   $0 = message
18  OPmovm      0x12      00010010   $0 = $m1 (pop $m1)
19  OPclear     0x13      00010011   clear($1)
20  OPson       0x14      00010100   Turn sounder on
21  OPsoff      0x15      00010101   Turn sounder off
22  OPnot       0x16      00010110   $1 = ~$1
23  OPlog       0x17      00010111   log($1) (pop $1)
24  OPlogr      0x18      00011000   $2 = read($1, $2) (msg top of stack)
25  OPlogr2     0x19      00011001   $2 = read($2, $1) (# top of stack)
26  OPsets      0x1a      00011010   set shared variable
27  OPgets      0x1b      00011011   get shared variable
28  OPforwc     0x1c      00011100   broadcast capsule of clock code
29  OPforwm     0x1d      00011101   broadcast capsule of msg code

Msg specific
30  OPgetm      0x1e      00011110   get field from message hdr
31  OPsetm      0x1f      00011111   set field in message hdr
32  OPgetf      0x20      00100000   get variable from frame
33  OPsetf      0x21      00100001   set variable in frame

VCLASS
64  OPpushc     0x40-7f   01xxxxxx   $0 <= signex(xarg)
128 OPblez      0x80-bf   10xxxxxx   if ($1 <= 0) jump xarg (pop $1)
192 OPbeqz      0xc0-ff   11xxxxxx   if ($1 == 0) jump xarg (pop $1)

Memory Model

*/

#define is_vclass(op) (op & 0xC0)

/*
   Base clase |0000oooo|
*/

#define OPhalt      0x00
#define OPreset     0x01

/* Basic Binary Operators with result*/
#define OPand       0x02
#define OPor        0x03
#define OPshiftr    0x04
#define OPshiftl    0x05
#define OPadd       0x06

#define binaryop(op) (op && (op <= OPshift)))

/* Unary Operators */
#define OPputled    0x08
#define OPid        0x09
#define OPinv       0x0a
#define OPcopy      0x0b
#define OPpop       0x0c
#define OPsense     0x0d
#define OPsend      0x0e
//#define OPrecv      0x0f
#define OPcast      0x10
#define OPpushm     0x11
#define OPmovm      0x12
#define OPclear     0x13
#define OPson       0x14
#define OPsoff      0x15
#define OPnot       0x16
#define OPlog       0x17
#define OPlogr      0x18
#define OPlogr2     0x19

#define OPforw      0x20

#define OPblez      0x80
#define OPpushc     0x40

#define xmask    0x1F
#define xsignbit 0x20
#define xopmask  0xC0
#define xarg(op) (((op) & xsignbit) ? (-((op) & xmask)) : ((op) & xmask))

