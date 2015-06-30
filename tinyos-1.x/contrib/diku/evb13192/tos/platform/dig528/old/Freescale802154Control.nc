/* $Id: Freescale802154Control.nc,v 1.1 2005/10/12 15:01:42 janflora Exp $ */
/* SimpleMac module. Wrapper around Freescale SMAC library.

  Copyright (C) 2004 Mads Bondo Dydensborg, <madsdyd@diku.dk>

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

// TODO: Include the needed Freescale header files.

/** 
 * Freescale 802.15.4 control interface.
 *
 * <p>Allow the user to control the Freescale 802.15.4 stack.</p>
 */

interface Freescale802154Control {
  
  /** Call this, before you start using any other parts of the interface. */
  command result_t init();

}
 
