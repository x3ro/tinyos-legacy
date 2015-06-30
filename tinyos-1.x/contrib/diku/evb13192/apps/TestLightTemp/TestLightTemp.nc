/*
    TestLightTemp program - tests the sampling of the lighttemp sensorboard.
    Copyright (C) 2004 Mads Bondo Dydensborg <madsdyd@diku.dk>

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

configuration TestLightTemp
{
}

//#define USENULL 1
/**
 * Test program for the lighttemp sensor board.
 * 
 * <p>Will output readings on the USB port.</p>
 *
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
implementation
{
  components Main,
    TestLightTempM,
    SingleTimer, LedsC,
    Light, Temp,
#ifdef USENULL
    StdNullC;
  TestLightTempM.StdOut -> StdNullC;
#else
  ConsoleC;
  TestLightTempM.Console -> ConsoleC;
#endif
  
  // TestLightTemp.Leds  -> LedsC;
  TestLightTempM.Timer -> SingleTimer.Timer;
  TestLightTempM.Light -> Light;
  TestLightTempM.Temp -> Temp;
  TestLightTempM.Leds -> LedsC;
  
  /* Connect Main with other components */
  Main.StdControl -> Light.StdControl;
  Main.StdControl -> Temp.StdControl;
  Main.StdControl -> TestLightTempM.StdControl;
  Main.StdControl -> SingleTimer.StdControl;
}
