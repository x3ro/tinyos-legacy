/*
    Copyright (C) 2006 Klaus S. Madsen <klaussm@diku.dk>

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
module BTPacketHandlerM {
  provides {
    interface BTPacketHandler;
  }
}

implementation {

#define PACKETS 6

  gen_pkt realPackets[PACKETS];
  gen_pkt *freePackets[PACKETS];

  command result_t BTPacketHandler.init()
  {
    uint8_t i;

    // Insert all the real packets into the freePackets list.
    atomic {
      for (i = 0; i < PACKETS; i++)
	freePackets[i] = &realPackets[i];
    }

    return SUCCESS;
  }

  async command gen_pkt* BTPacketHandler.get()
  {
    gen_pkt * res = NULL;
    uint8_t i;
    
    for (i = 0; i < PACKETS; i++) {
      atomic {
	if (freePackets[i] != 0) {
	  res = freePackets[i];
	  freePackets[i] = 0;
	}
      }
      if (res)
	return res;
    }
    
    signal BTPacketHandler.getFailure();
    return 0;
  }

  async command result_t BTPacketHandler.put(gen_pkt* pkt)
  {
    uint8_t i;
    bool found = FALSE;
    for (i = 0; i < PACKETS; i++) {
      atomic {
	if (freePackets[i] == NULL) {
	  freePackets[i] = pkt;
	  found = TRUE;
	}
      }
      if (found)
	return SUCCESS;
    }
    signal BTPacketHandler.putFailure();
    return FAIL;
  }
  
  command uint8_t BTPacketHandler.getFreePackets()
  {
    uint8_t i;
    uint8_t res = 0;
    atomic {
      for (i = 0; i < PACKETS; i++) {
	if (freePackets[i])
	  res++;
      }
    }
    return res;
  }
}
