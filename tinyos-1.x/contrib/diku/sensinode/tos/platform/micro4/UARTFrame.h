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


#ifndef UARTFRAME_H
#define UARTFRAME_H

#define MAX_FRAME_LENGTH 128

typedef uint8_t * pointer_t __attribute__((combine(pointerCombine)));
/*
pointer_t pointerCombine(pointer_t p1, pointer_t p2)
{
	if (p1 > p2)
		return p1;
	else
		return p2;
}
*/
	typedef enum
	{
		UART_FRAME_RETRANSMIT = 0x00,
		UART_FRAME_INIT = 0x01,
		UART_FRAME_FRAGMENT = 0x02,
		UART_FRAME_ALIVE = 0x03,

	}uart_frame_types;


#endif
