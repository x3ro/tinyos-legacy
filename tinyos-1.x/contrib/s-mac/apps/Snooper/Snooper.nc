/*									tab:4
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye
 * Date created: 1/21/2003
 *
 * listens all packets and pass them to UART.
 * Support different packet length. The first byte must be packet length.
 * Data is received from radio and passed to UART on a per byte basis.
 * If on a per packet basis, a short packet following a long packet may get
 * lost because the UART can't finish sending the long packet when the short
 * packet arrives.
 * The contents of each packet can be displayed by snoope.c at tools/.
 *
 */

includes config;

configuration Snooper { }

implementation
{
   components Main, SnooperM, PhyRadio, UART;
   
   Main.StdControl -> SnooperM;
   SnooperM.PhyControl -> PhyRadio;
   SnooperM.PhyComm -> PhyRadio;
   SnooperM.PhyStreamByte -> PhyRadio;
   SnooperM.UARTControl -> UART;
   SnooperM.UARTComm -> UART;
}




