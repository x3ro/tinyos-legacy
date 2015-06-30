/*
    BTBech - measures throughput and other charactaristics of the 
             BT interface
    Copyright (C) 2003 Martin Leopold <leopold@diku.dk>
	    
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
 * BTBench program - benchmark various Bluetooth operations */
configuration BTBench {
}
implementation {
  components Main,
       IntToLeds,
       BTBenchM,
       HCICore0C,
       StdOutC,
       ClockC;

  /* Connect Main with other components */
  Main.StdControl -> BTBenchM.StdControl;

  BTBenchM.IntOutput -> IntToLeds.IntOutput;
  BTBenchM.Bluetooth -> 
       HCICore0C.Bluetooth;
  
  BTBenchM.StdOut -> StdOutC;

  BTBenchM.Clock -> ClockC.Clock;
  Main.StdControl -> ClockC.StdControl;
}
