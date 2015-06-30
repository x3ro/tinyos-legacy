// $Id: HPLCC2420C.nc,v 1.1 2006/04/14 00:19:14 binetude Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors: Joe Polastre
 * Date last modified:  $Revision: 1.1 $
 *
 */

/**
 * Low level hardware access to the CC2420
 * @author Joe Polastre
 */

configuration HPLCC2420C {
  provides {
    interface StdControl;
    interface HPLCC2420;
    interface HPLCC2420RAM;
    interface HPLCC2420FIFO;
    interface HPLCC2420Interrupt as InterruptFIFOP;
    interface HPLCC2420Interrupt as InterruptFIFO;
    interface HPLCC2420Interrupt as InterruptCCA;
    interface HPLCC2420Capture as CaptureSFD;
  }
}
implementation
{
  components HPLCC2420M,
             PowerStateM;
//         , HPLUSART0M
//         , TimerC
//         , CC2420RXFIFO
//         , HPLCC2420InterruptM;
//         , MSP430InterruptC
//         , MSP430TimerC
//         , BusArbitrationC;

  StdControl = HPLCC2420M;
  HPLCC2420 = HPLCC2420M;
  HPLCC2420RAM = HPLCC2420M;
  HPLCC2420FIFO = HPLCC2420M;

  InterruptFIFOP = HPLCC2420M.FIFOP;
  InterruptFIFO = HPLCC2420M.FIFO;
  InterruptCCA = HPLCC2420M.CCA;
  CaptureSFD = HPLCC2420M.SFD;

  HPLCC2420M.PowerState -> PowerStateM;

//  HPLCC2420M.USARTControl -> HPLUSART0M;
//  HPLCC2420M.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];

//  HPLCC2420InterruptM.FIFOPInterrupt -> MSP430InterruptC.Port10;
//  HPLCC2420InterruptM.FIFOInterrupt -> MSP430InterruptC.Port13;
//  HPLCC2420InterruptM.CCAInterrupt -> MSP430InterruptC.Port14;
//  HPLCC2420InterruptM.SFDControl -> MSP430TimerC.ControlB1;
//  HPLCC2420InterruptM.SFDCapture -> MSP430TimerC.CaptureB1;

//  HPLCC2420InterruptM.SFDTimer -> TimerC.Timer[unique("Timer")];
}
