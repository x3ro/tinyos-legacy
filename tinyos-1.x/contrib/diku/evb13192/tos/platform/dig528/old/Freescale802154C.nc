/*
    Console configurations - module that buffers and perhaps
    eventually will do some printf like thing.  

    Copyright (C) 2002-2004 Mads Bondo Dydensborg <madsdyd@diku.dk>

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
/**
 * Simple Freescale802154 component that uses Uart interface.  
 *
 * <p>This configuration maps onto the uart that is normally used to
 * connect onto a pc.</p>
 *
 * 

 */
configuration Freescale802154C
{
	provides
	{
		interface Freescale802154Control;
		interface MLME_GET;
		interface MLME_SCAN;
		interface MLME_SET;
		interface MLME_START;
		interface MLME_ASSOCIATE;
		interface MLME_DISASSOCIATE;
		interface MCPS_DATA;
	}
	uses
	{
		interface Console;
		interface Leds;
	}
}

implementation
{
	components Freescale802154M;

	Freescale802154M.Console = Console;
	Freescale802154M.Leds = Leds;
	Freescale802154Control = Freescale802154M.Control;

	MLME_GET = Freescale802154M.MLME_GET;
	MLME_DISASSOCIATE = Freescale802154M.MLME_DISASSOCIATE;
	MLME_SCAN = Freescale802154M.MLME_SCAN;
	MLME_START = Freescale802154M.MLME_START;
	MLME_SET = Freescale802154M.MLME_SET;
	MLME_ASSOCIATE = Freescale802154M.MLME_ASSOCIATE;

	MCPS_DATA = Freescale802154M.MCPS_DATA;
}
