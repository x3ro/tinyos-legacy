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


configuration SimpleMacC {
	provides {
		interface StdControl;
		interface SimpleMac;
	} 
	uses {
		interface StdOut;
	}
}

implementation {
	components SimpleMacM, HALCC2420C, LocalTimeMicroC;//, StdNullC;

	StdControl = SimpleMacM;
	SimpleMac = SimpleMacM;
	
	StdOut = HALCC2420C.StdOut;
	StdOut = SimpleMacM.StdOut;

	//HALCC2420C.StdOut -> StdNullC;


	SimpleMacM.HALCC2420 -> HALCC2420C.HALCC2420;
	SimpleMacM.HALCC2420Control -> HALCC2420C.StdControl;

}


