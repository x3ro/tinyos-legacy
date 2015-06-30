/*
 * Copyright (c) 2004-2006 Rincon Research Corporation.  
 * All rights reserved.
 * 
 * Rincon Research will permit distribution and use by others subject to
 * the restrictions of a licensing agreement which contains (among other things)
 * the following restrictions:
 * 
 *  1. No credit will be taken for the Work of others.
 *  2. It will not be resold for a price in excess of reproduction and 
 *      distribution costs.
 *  3. Others are not restricted from copying it or using it except as 
 *      set forward in the licensing agreement.
 *  4. Commented source code of any modifications or additions will be 
 *      made available to Rincon Research on the same terms.
 *  5. This notice will remain intact and displayed prominently.
 * 
 * Copies of the complete licensing agreement may be obtained by contacting 
 * Rincon Research, 101 N. Wilmot, Suite 101, Tucson, AZ 85711.
 * 
 * There is no warranty with this product, either expressed or implied.  
 * Use at your own risk.  Rincon Research is not liable or responsible for 
 * damage or loss incurred or resulting from the use or misuse of this software.
 */


/**
 * Transceiver configuration  v.2.1
 *  Combines AMStandard, GenericComm, UARTComm, and
 *  QueuedSend into one while adding memory sharing
 *  functionality across an entire system.
 *
 *  This module should be used in place of everything
 *  dealing with any type of mote communication.
 *
 *  Just make sure the MAX_TOS_MSGS in the Transceiver.h
 *  file reflects the most amount of messages your
 *  app will require to send at any given time.
 *  
 *  @author David Moss - dmm@rincon.com
 */

includes Transceiver;

configuration TransceiverC {
  provides {
    interface StdControl;
    interface Packet;
    interface Transceiver[uint8_t type];
  }
}

implementation {
  components TransceiverM, StateC, PacketFilterM, PacketM;
  components RadioCRCPacket, UARTFramedPacket;
  
  Transceiver = TransceiverM;
  Packet = PacketM;
  
  StdControl = TransceiverM;
  StdControl = StateC;
  StdControl = RadioCRCPacket;
  StdControl = UARTFramedPacket;
  
  TransceiverM.WriteState -> StateC.State[unique("State")];
  TransceiverM.SendState -> StateC.State[unique("State")];
  TransceiverM.PacketFilter -> PacketFilterM;

  TransceiverM.ReceiveRadio -> RadioCRCPacket.Receive;
  TransceiverM.ReceiveUart -> UARTFramedPacket.Receive;
  TransceiverM.SendRadio -> RadioCRCPacket.Send;
  TransceiverM.SendUart -> UARTFramedPacket.Send;
}

