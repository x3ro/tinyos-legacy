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

includes HPLSpi;

interface Spi
{

  async command result_t init();

  /**
   * Enable the SPI bus functionality
   */
  async command result_t enable(uint8_t params, uint8_t id);

  /**
   * Disable the SPI bus functionality
   */
  async command result_t disable();

  /**
   * Write a byte to the SPI bus
   * @param data value written to the MOSI pin
   * @return value read on the MISO pin
   */
  async command uint8_t write(uint8_t data);
}
