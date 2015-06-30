/* $Id: SimpleMacCRCPacketM.nc,v 1.1 2005/01/31 21:05:56 freefrag Exp $ */
/* SimpleMacCRCPacket configuration, for use by the RadioCRCPacket

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

/** 
 * SimpleMacCRCPacket component.
 *
 * <p>Uses the Simple Mac layer to send packets over the radio.</p>
 *
 *
 * <p>This component more or duplicates the work of CRCPacket.nc in
 * the standard TinyOS stack. However, the CRCPacket.nc component
 * assumes that there is some kind of byte level interface. We work
 * with packets. Obviously we could implement a byte level abstraction
 * on top of our packet abstraction, but that really seems silly.</p>
 *
 * <p>NB: This component assumes that the SimpleMac is always
 * ready.</p>
 *
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
includes crc;
module SimpleMacCRCPacketM {
  provides {
    interface StdControl; 
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
  uses {
    interface SimpleMac as Mac;
  }
}
implementation {
  
  tx_packet_t txPacket;
  /** Used to store pointers for sendDone, and also to check if something 
      is going on. */
  TOS_MsgPtr txMsg; 
  
  /* **********************************************************************
   * StdControl stuff
   * *********************************************************************/

  /**************************************************************************/
  /**
   * Initialise the component.
   *
   * <p>Call the mac layers init code, setup our packets and buffers</p>
   *
   * @return The value from the Mac.init call
   */
  /**************************************************************************/
  command result_t StdControl.init() {
    txPacket.data = NULL;
    txMsg         = NULL;
    // txPacket.length = 0;
    return rcombine(call Mac.init(), call Mac.setChannel(0));
  }

  /**************************************************************************/
  /**
   * Start - does nothing.
   *
   * @return SUCCESS always
   */
  /**************************************************************************/
  command result_t StdControl.start() {
    return SUCCESS;
  }

  /**************************************************************************/
  /**
   * Stop - does nothing.
   *
   * @return SUCCESS always
   */
  /**************************************************************************/
  command result_t StdControl.stop() {
    return SUCCESS;
  }

  /* **********************************************************************
   * SimpleMac stuff
   * *********************************************************************/

  /**************************************************************************/
  /**
   * SimpleMac reset.
   *
   * <p>This is a toughie. We just try to init it again. Not neccesarily
   * the right thing to do.</p>
   *
   * @param
   * @return
   */
  /**************************************************************************/
  event void Mac.reset() {
    while (!call Mac.init());
  }

  /* **********************************************************************
   * The following function and two tasks have been "lifted" from 
   * CRCPacket.nc - some license restrictions may apply.
   * *********************************************************************/
  
  /* Internal function to calculate 16 bit CRC */
  uint16_t calcrc(uint8_t *ptr, uint8_t count) {
    uint16_t crc;
    uint8_t i;
  
    crc = 0;
    while (count-- > 0)
      crc = crcByte(crc, *ptr++);

    return crc;
  }
  
  uint8_t *recPtr;
  uint8_t *sendPtr;


  /* A Task to calculate CRC for to check for message integrity */
  /*  task void CRCCheck() {
    uint16_t crc, mcrc;
    uint8_t length;

    rxCount = 0;
    length = rxLength;
    crc = calcrc(recPtr, length - 2);
    mcrc = ((recPtr[length - 1] & 0xff)<< 8);
    mcrc |= (recPtr[length - 2] & 0xff);
    if (crc == mcrc)
      {
	TOS_MsgPtr tmp;

	dbg(DBG_PACKET, "got packet\n");  
	tmp = signal Receive.receive((TOS_MsgPtr)recPtr);
	dbg(DBG_CRC, "CRCPacket: check succeeded: %x, %x\n", crc, mcrc);
	if (tmp)
	  recPtr = (uint8_t *)tmp;  
      }
    else
      dbg(DBG_CRC, "CRCPacket: check failed: %x, %x\n", crc, mcrc);
  }
  */

  /**************************************************************************/
  /**
   * We got a packet.
   *
   * <p>We signal it to the higher levels, iff the packet has an OK CRC.</p>
   *
   * @param packet The packet that was received
   * @return A new packet for this layer.
   */
  /**************************************************************************/
  event rx_packet_t * Mac.receive(rx_packet_t * packet) {
    packet->data = (uint8_t *) signal Receive.receive((TOS_MsgPtr) packet->data);
    return packet;
  }

  /* **********************************************************************
   * Send command
   * *********************************************************************/

  /**************************************************************************/
  /**
   * Send packet task.
   *
   * <p>Send packet task, also put in a CRC.</p>
   *
   */
  /**************************************************************************/
  /* A Task to calculate CRC for message transmission */
  task void sendPacket() {
    uint16_t crc;
    txPacket.dataLength = TOS_MsgLength(txMsg->type);
    txPacket.data       = (uint8_t *)txMsg;
    crc                 = calcrc((uint8_t *) txMsg, txPacket.dataLength - 2);
    txPacket.data[txPacket.dataLength - 2] = crc & 0xff;
    txPacket.data[txPacket.dataLength - 1] = (crc >> 8) & 0xff; 
    if (!call Mac.send(&txPacket)) {
      txMsg = NULL;
    }
  } 

  /** Forward event received from SimpleMac to client */
  event void Mac.sendDone(tx_packet_t * packet) {
    txMsg = NULL;
    signal Send.sendDone((TOS_MsgPtr) packet->data, SUCCESS);
  }


   /**************************************************************************/
  /**
   * Send a packet.
   *
   * <p>Send a TOS_Msg.</p>
   *
   * @param
   * @return SUCCESS if the buffer will be sent, FAIL if not. If
   * SUCCESS a sendDone event should be expected, if FAIL it should
   * not.
   */
  /**************************************************************************/
  command result_t Send.send(TOS_MsgPtr msg) {
    /* We need to translate the TOS_MsgPtr into something we can
       send. */
    if (txMsg == NULL) {
      txMsg = msg;
      post sendPacket();
      return SUCCESS;
    } else {
      return FAIL;
    }
  }
} /* Implementation */
