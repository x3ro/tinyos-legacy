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


module CRC16M
{
  provides interface CRC16;
}

implementation
{

#include "crc.h"

  command uint16_t CRC16.calc(uint8_t *data, uint16_t len)
  {
    // In order to be fully compliant with CRC16-CCITT, the CRC must
    // have an initial value of 0xFFFF. 
    uint16_t crc = 0xFFFF;
    uint16_t i;

    for (i = 0; i < len; i++)
      crc = crcByte(crc, data[i]);

    return crc;
  }

}
