/*
  LedDebug interface - provides an interface to "debugging" with 
  the leds.

  Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>

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
/**
 * Define an interface for displaying debug output on the Leds, and
 * also fail while repeating a pattern. */
configuration LedDebugC {
  provides {
    interface LedDebugI;
  }
}
implementation {
  components IntToLeds, LedDebugM;
  LedDebugM.IntOutput -> IntToLeds.IntOutput;
  LedDebugI = LedDebugM;
}
