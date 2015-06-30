/* $Id: TestMain.nc,v 1.2 2005/04/14 13:16:50 janflora Exp $ */
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

/** Test application for 802.15.4
 *
 * @author Mads Bondo Dydensborg, <madsdyd@diku.dk>
 * Note: This is a work in progress.
 */
configuration TestMain {
}
implementation {
	components Main,
	           TestMainM,
	           SingleTimer,
	           LedsC,
	           ConsoleC,
	           Freescale802154C;
	           
	/* Wire up! */
	Main.StdControl -> SingleTimer.StdControl;
	Main.StdControl -> TestMainM.StdControl;
 
	TestMainM.Timer -> SingleTimer.Timer;
	TestMainM.Leds -> LedsC; 
	TestMainM.Console -> ConsoleC;

	/* Wire up the 802.15.4 interfaces */
	Freescale802154C.Console -> ConsoleC;
	Freescale802154C.Leds -> LedsC;

	/* And the stuff we need */
	TestMainM.Control		-> Freescale802154C;
	TestMainM.MLME_GET		-> Freescale802154C;
	TestMainM.MLME_START		-> Freescale802154C;
	TestMainM.MLME_SCAN		-> Freescale802154C;
	TestMainM.MLME_SET		-> Freescale802154C;
	TestMainM.MLME_ASSOCIATE	-> Freescale802154C;
	TestMainM.MLME_DISASSOCIATE -> Freescale802154C;

	TestMainM.MCPS_DATA		-> Freescale802154C;
  
}






