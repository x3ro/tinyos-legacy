/*
  HCIPacket interface collects bytes from an Ericsson ROK 101 007 modules
  and provides a packet-oriented abstraction.
  Copyright (C) 2002 Martin Leopold <leopold@diku.dk>

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

/*
 A packet based interface to the Bluetooth module
 */

includes btpackets;

/** 
 * HCIPacket interface collects bytes from an Ericsson ROK 101 007 modules
 * and provides a packet-oriented abstraction. */
interface HCIPacket {
 /** 
  * Initialize the BT module.
  *
  * <p>Wait for the BT_ready event.</p>
  *
  * @return SUCCESS always */
  command result_t init_BT();

  /**
   * Signalled when the BT module is ready to receive commands. 
   *
   * @param s TODO: Martin 
   * @return TODO: Martin */
  async event result_t BT_ready(result_t s);

  /**
   * Initialize TODO: Initialize what, Martin?.
   *
   * @return ??? SUCCESS always. */
  command result_t init();

  /**
   * Send one packet to the Blutooth module. 
   *
   * <p>There should only one outstanding send at any time; one must
   * wait for the <code>putDone</code> event before calling
   * <code>put</code> again. You must handle several outstanding
   * Bluetooth packets.</p>
   *
   * @param data is a pointer to a well formed HCI-packet 
   * @param type is the type of data contained in the packet
   * (command/ACL/SCO)
   * @return SUCCESS always */
  command result_t putPacket(gen_pkt *data, hci_data_t type);

  /**
   * The previous call to <code>put</code> has completed; another
   * packet may now be sent.
   *
   * @param data A packet that can be reused
   * @return SUCCESS always */
  async event result_t putPacketDone(gen_pkt *data);

  /**
   * An event packet has been received.
   *
   * @param data The event
   * @return An unused packet */
  async event gen_pkt* get_event(gen_pkt* data);

  /**
   * An ACL data packet has been received.
   *
   * @param data The ACL packet
   * @return SUCCESS always */
  async event gen_pkt* get_acl_data(gen_pkt* data);

  /**
   * An error has occured.
   *
   * @param e is the errorcode
   * @param param is any additional information associated with the error */
  async event void error(errcode e, uint16_t param);

  /**
   * Set the rate of the associated UART.
   *
   * @param rate is the rate to set the Uart to
   * @return TODO: Martin */
  command result_t setRate(uint8_t rate);
}
