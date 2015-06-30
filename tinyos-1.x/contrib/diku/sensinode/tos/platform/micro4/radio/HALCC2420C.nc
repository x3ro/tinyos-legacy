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



configuration HALCC2420C {
	provides {
		interface HALCC2420;
		interface StdControl;
	}
	uses {
		interface StdOut;
	}
}

implementation {
	components HALCC2420M, HPLCC2420M, MSP430InterruptC, HPLSpiM, 
		BusArbitrationC, HPL1wireM;

	StdControl = HALCC2420M.HALCC2420Control;
	HALCC2420 = HALCC2420M.HALCC2420;
	StdOut = HALCC2420M.StdOut;
	
	HALCC2420M.Spi -> HPLSpiM.Spi;
	HALCC2420M.MSP430Interrupt -> MSP430InterruptC.Port17;
	HALCC2420M.HPLCC2420Control -> HPLCC2420M.HPLCC2420Control;
	HALCC2420M.HPLCC2420 -> HPLCC2420M.HPLCC2420;
	HALCC2420M.HPLCC2420RAM -> HPLCC2420M.HPLCC2420RAM;
	HALCC2420M.HPLCC2420FIFO -> HPLCC2420M.HPLCC2420FIFO;
	HALCC2420M.HPLCC2420Status -> HPLCC2420M.HPLCC2420Status;
	HALCC2420M.BusArbitration -> BusArbitrationC.BusArbitration[unique("BusArbitration")];
	HALCC2420M.HPL1wire -> HPL1wireM.HPL1wire;

	HPLCC2420M.Spi -> HPLSpiM.Spi;
}


