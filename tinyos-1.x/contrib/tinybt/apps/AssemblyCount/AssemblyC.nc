/*
  Assembly program - second version of self assembly program
  Based on an approach where children are looking for their parents.

  Copyright (C) 2002 & 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
  
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

/* This must be changed both here and in AssemblyM.nc */
//#define CLOCK_DEBUG 1

/** Assembly configuration that uses two Bluetooth devices and builds
    a simple tree. */

configuration AssemblyC {
  provides {
    interface AssemblyI;
  }
}
implementation {
  components Main,
    AssemblyM,
    HCICore0C,
    HCICore1C,
#ifdef CLOCK_DEBUG
    ClockC,
#endif
    HPLInterrupt, LedDebugC;

  /* Setup the interfaces */
  AssemblyI            =  AssemblyM;

  /* Wire the components */
#ifdef CLOCK_DEBUG
  AssemblyM.Clock      -> ClockC.Clock;
  Main.StdControl      -> ClockC.StdControl;
#endif
  
  Main.StdControl      -> AssemblyM.StdControl;
  AssemblyM.Bluetooth0 -> HCICore0C.Bluetooth;
  AssemblyM.Bluetooth1 -> HCICore1C.Bluetooth;
  AssemblyM.Interrupt  -> HPLInterrupt;
  AssemblyM.Debug      -> LedDebugC.LedDebugI;
}
