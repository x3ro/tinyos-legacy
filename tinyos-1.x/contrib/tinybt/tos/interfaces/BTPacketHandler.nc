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
includes btpackets;

/*
 *
 *
 */

interface BTPacketHandler {
  /**
   * Initialize the packet handler
   *
   * @return SUCCESS, when initialized.
   */
  command result_t init();

  /**
   * Locates a free packet in the buffer-pool, and returns it. If
   * there is no free packets NULL is returned, and getFailure is
   * signaled.
   *
   * @return A free packet, or NULL if no free packets exists
   */
  async command gen_pkt* get(); 

  /**
   * Returns a packet to the buffer-pool. If successful, the function
   * will return SUCCESS. Otherwise it returns FAIL, and putFailure is
   * signalled.
   *
   * @return SUCCESS, if the packet could be returned.
   */
  async command result_t put(gen_pkt* pkt);

  command uint8_t getFreePackets();

  /**
   * This event is signaled when the user called get, but there
   * is no free packets left in the system
   */
  async event result_t getFailure(); 

  /**
   * This event is signaled when the user calls put, but there
   * is no space for the returned packet.
   */
  async event result_t putFailure();
}
