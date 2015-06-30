/*
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Author: Tom Parker
 * This module provides the byte-level RadioSPI interface to the TOSSIM radio
 */

configuration RadioSPIC
{
	provides interface RadioSPI;
	provides interface UARTDebug;
}

implementation {
	components RadioSPIM, SpiByteFifoC, UARTDebugC;
#ifdef PC_POWERSTATE	
	components PowerStateM;
	SpiByteFifoC.PowerState -> PowerStateM;
#endif
	RadioSPI = RadioSPIM;
	RadioSPIM.SpiByteFifo -> SpiByteFifoC;
	RadioSPIM.Debug -> UARTDebugC;
	UARTDebug = UARTDebugC;
}
