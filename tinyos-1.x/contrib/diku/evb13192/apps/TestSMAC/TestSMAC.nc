/* $Id: TestSMAC.nc,v 1.1 2005/01/31 21:04:36 freefrag Exp $ */
/** Test application for SimpleMac

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

/** Test application for SimpleMac.
 *
 * <p>This is a very simplistic test of SimpleMac. The application
 * will try to send packets on a fixed channel, while also listening
 * to them. For each packet send, it will flash the number of send
 * packets on the leds, likewise for received.</p>
 *
 * <p>The application also uses an UART to send status messages over.</p>
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>
 * Note: This is a work in progress.
 */
configuration TestSMAC {
}
implementation {
  components Main, TestSMACM, SimpleMacM, SingleTimer, LedsC, HPLUART0C;
  /* Wire up! */
  Main.StdControl -> SingleTimer.StdControl;
  Main.StdControl -> TestSMACM.StdControl;
  TestSMACM.Timer -> SingleTimer.Timer;
  TestSMACM.Leds -> LedsC;
  TestSMACM.Mac -> SimpleMacM;
  TestSMACM.Uart -> HPLUART0C; 
}






