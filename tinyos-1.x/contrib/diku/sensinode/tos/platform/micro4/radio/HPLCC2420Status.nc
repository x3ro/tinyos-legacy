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

interface HPLCC2420Status {
	/**
	 * FIFO retrieves the status of the FIFO pin.
	 *
	 * @return bool  True if the FIFO pin is high
	 */
	async command bool FIFO();

	/**
	 * FIFOP retrieves the status of the FIFOP pin.
	 *
	 * @return bool  True if the FIFOP pin is high
	 */
	async command bool FIFOP();

	/**
	 * CCA retrieves the status of the CCA pin.
	 *
	 * @return bool  True if the CCA pin is high
	 */
	async command bool CCA();

	/**
	 * SFD retrieves the status of the SFD pin.
	 *
	 * @return bool  True if the SFD pin is high
	 */
	async command bool SFD();
}
