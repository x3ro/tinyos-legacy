// $Id: GenericComm.nc,v 1.1.1.1 2007/11/05 19:11:28 jpolastre Exp $
/*
 * Copyright (c) 2006 Moteiv Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached MOTEIV-LICENSE     
 * file. If you do not find these files, copies can be found at
 * http://www.moteiv.com/MOTEIV-LICENSE.txt and by emailing info@moteiv.com.
 */

/**
 * GenericComm wrapper for legacy support for TinyOS 1.x applications.
 * All new applications should use SPC instead of GenericComm.
 *
 * @author Joe Polastre, Moteiv Corporation <info@moteiv.com>
 */
configuration GenericComm
{
  provides {
    // for backwards compatibility
    interface StdControl as Control;

    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];
  }
}
implementation
{
  // CRCPacket should be multiply instantiable. As it is, I have to use
  // RadioCRCPacket for the radio, and UARTNoCRCPacket for the UART to
  // avoid conflicting components of CRCPacket.
  components SPC;
  components NullStdControl;

  // This wrapper doesn't allow the user to start/stop the radio
  // instead, they must use the interfaces provided by SP
  Control = NullStdControl;

  // Wrappers for the send and receive functions for backwards compatibility
  SendMsg = SPC.SendMsg;
  ReceiveMsg = SPC.ReceiveMsg;
  
}
