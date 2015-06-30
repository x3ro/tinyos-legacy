// $Id: MultiCharMonibus.nc,v 1.1 2005/06/15 09:58:09 neturner Exp $

/*
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
 */

/**
 * At some interval, send a MonibusMsg (via UART/USB [TelosB]) containing
 * the Monibus reading.
 */

includes MonibusMsg;

configuration MultiCharMonibus {
}

implementation {
  components Main, 
    CC2420RadioC,
    MultiCharMonibusM,
    TimerC,
    LedsC as LEDs,
    GenericComm as Radio,
    MonibusHPLUARTC;

  Main.StdControl -> MultiCharMonibusM.StdControl;

  MultiCharMonibusM.TimerControl -> TimerC.StdControl;
  MultiCharMonibusM.MessageControl -> Radio.Control;

  MultiCharMonibusM.Timer  -> TimerC.Timer[unique("Timer")];
  MultiCharMonibusM.ResponseTimeout  -> TimerC.Timer[unique("Timer")];
  MultiCharMonibusM.Leds -> LEDs;
  MultiCharMonibusM.SendMsg -> Radio.SendMsg[AM_MONIBUSMSG];
  MultiCharMonibusM.Monibus -> MonibusHPLUARTC.UART;
}
