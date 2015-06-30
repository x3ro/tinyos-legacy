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


module LCGM {
	provides {
		interface LCG;
	}
}

implementation {

#define A 1664525
#define B 1013904223
/* #define M 0x100000000 */

	uint64_t v = 0;

	command void LCG.seed(uint32_t seed)
	{
		v = seed;
	}

	command uint32_t LCG.next()
	{
		/* v_i+1 = (A * v_i + B) MOD M */
		v = (A * v + B) & 0xFFFFFFFF;
		
		return v;
	}
		

}
