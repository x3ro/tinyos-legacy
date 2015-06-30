/*
 * Copyright (c) 2002-2004 the University of Southern California
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
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 *
 * This module implements the radio control functions:
 *   1) Put radio into different states:
 *   	a) idle; b) sleep; c) receive; d) transmit
 *   2) Physical carrier sense
 *   3) Tx and Rx of packets, and the handling of bytes in/out to/from the platform
 *      specific-layer
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */


configuration RadioControl
{
   provides {
      interface StdControl as PhyControl;
      interface RadioState as PhyState;
      interface PhyComm;
      interface CarrierSense;
	  interface UARTDebug;
   }
}

implementation
{
   components RadioControlM, RadioSPIC;
   
   CarrierSense = RadioControlM;
   PhyState = RadioControlM.PhyState;
   PhyComm = RadioControlM;
   RadioControlM.RadioSPI -> RadioSPIC;
   RadioControlM.Debug -> RadioSPIC;
   UARTDebug = RadioSPIC;
   PhyControl = RadioControlM;
}
