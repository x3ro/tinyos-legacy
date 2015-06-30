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


configuration FlashAccessC {
	provides {
		interface StdControl as FlashControl;
		interface FlashAccess;
	}
}

implementation {
	components FlashAccessM, HALSTM25P40M, HPLSTM25P40M, HPLSpiM, TimerC, BusArbitrationC, StdOutC;

	FlashControl = FlashAccessM.FlashControl;
	FlashAccess = FlashAccessM.FlashAccess;

	FlashAccessM.Flash		->	HALSTM25P40M.Flash;

	HALSTM25P40M.BusArbitration 	->	BusArbitrationC.BusArbitration[unique("BusArbitration")];
	HALSTM25P40M.Timer 				->	TimerC.Timer[unique("Timer")];
	HALSTM25P40M.Spi				->	HPLSpiM.Spi;
	HALSTM25P40M.HPLFlash			->	HPLSTM25P40M.HPLFlash;

	HPLSTM25P40M.Spi		->	HPLSpiM.Spi;
	
	HALSTM25P40M.StdOut	-> StdOutC;
	HPLSTM25P40M.StdOut	-> StdOutC;
}


