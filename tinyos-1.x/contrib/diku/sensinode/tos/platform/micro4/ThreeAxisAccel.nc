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


	enum conversion_status {
		ACCEL_STATUS_SUCCESS = 0x00,
        ACCEL_STATUS_CONVERSION_FAILED = 0x01,
        ACCEL_STATUS_BLOCKMODE_FAILED = 0x02,
        ACCEL_STATUS_OUT_OF_BOUNCE = 0x04,
	};
	
	enum accelerometer_range {
		ACCEL_RANGE_2x5G = 0x00,
		ACCEL_RANGE_6x7G = 0x01,
		ACCEL_RANGE_3x3G = 0x02,
		ACCEL_RANGE_10x0G = 0x03,
	};

interface ThreeAxisAccel {

  command result_t setRange(uint8_t range);
	
  command result_t getData();
  event result_t dataReady(uint16_t xaxis, uint16_t yaxis, uint16_t zaxis, uint8_t status);
}
