/*
    TestAccelerometer program - test the SARD board.
    Copyright (C) 2005 Marcus Chang <marcus@diku.dk>

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

configuration TestAccelerometer
{
}

/**
 * Test program for the lighttemp sensor board.
 * 
 * <p>Will output readings on the UART port.</p>
 *
 * @author Marcus Chang <marcus@diku.dk>.
 */
implementation
{
    components Main,
    TestAccelerometerM,
    SingleTimer, LedsC,
    Xaxis, 
    Yaxis, 
    Zaxis, 
    ConsoleC;
    
  
    TestAccelerometerM.Timer -> SingleTimer.Timer;
    TestAccelerometerM.Xaxis -> Xaxis;
    TestAccelerometerM.Yaxis -> Yaxis;
    TestAccelerometerM.Zaxis -> Zaxis;
    TestAccelerometerM.Leds -> LedsC;
    TestAccelerometerM.Console -> ConsoleC.ConsoleOut;


    /* Connect Main with other components */
    Main.StdControl -> ConsoleC.StdControl;
    Main.StdControl -> Xaxis.StdControl;
    Main.StdControl -> Yaxis.StdControl;
    Main.StdControl -> Zaxis.StdControl;
    Main.StdControl -> TestAccelerometerM.StdControl;
    Main.StdControl -> SingleTimer.StdControl;
}
