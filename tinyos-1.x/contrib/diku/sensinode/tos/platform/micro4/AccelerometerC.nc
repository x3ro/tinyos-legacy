/*
  Copyright (C) 2004 Klaus S. Madsen <klaussm@diku.dk>
  Copyright (C) 2006 Marcus Chang <marcus@diku.dk>

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

configuration AccelerometerC {
	provides {
		interface ThreeAxisAccel;
	}
	uses interface StdOut;
}

implementation {
	components HPLU510R1M, HPLSpiM, BusArbitrationC, TimerC, LocalTimeMicroC;

	ThreeAxisAccel = HPLU510R1M;

StdOut = HPLU510R1M;


	HPLU510R1M.LocalTime		->	LocalTimeMicroC.LocalTime;

	HPLU510R1M.Timer 			->	TimerC.Timer[unique("Timer")];
	HPLU510R1M.Spi				->	HPLSpiM.Spi;
	HPLU510R1M.BusArbitration 	->	BusArbitrationC.BusArbitration[unique("BusArbitration")];
}


