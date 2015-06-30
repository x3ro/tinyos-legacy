/*
 * Copyright (C) 2002-2003 Dennis Haney <davh@diku.dk>
 * Copyright (C) 2003 Mads Bondo Dydensborg <madsdyd@diku.dk>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/* Interface that defines a number of operations used to send packets
   over the simulated Bluetooth Frequency Hopping channels. */
interface BTFHChannel
{
  /**
   * Initialize the module. */
  command void Init();
  
  /**
   * Add a listener.
   *
   * <p>Add a number to the linked list of listeners on a channel.</p>
   *
   * @param channel the channel to add the listener to
   * @param who the number of the listener
   * @return SUCCESS */
  command result_t addToChannel(int channel, int who);

  /**
   * BTFHChannel.removeFromChannel.
   *
   * <p>Remove a number from the linked list.</p>
   *
   * @param channel the channel to remove the listener from
   * @param who the number of the listener
   * @return SUCCESS */
  command result_t removeFromChannel(int channel, int who);
  
  /**
   * Send packet to all listening nodes.
   *
   * <p>Take packet and schedule a receive event forevery node that is
   * listening on the channel.</p>
   *
   * @param p the packet to send. p->bt->fs_ is the channel to send on.
   * @return SUCCESS */
  command result_t sendUp(struct BTPacket* p);
}
