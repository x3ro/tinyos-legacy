// $Id: GenericCommPromiscuous.nc,v 1.5 2006/04/28 18:07:49 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 *
 * Authors:		Jason Hill, David Gay, Philip Levis
 * Date last modified:  $Id: GenericCommPromiscuous.nc,v 1.5 2006/04/28 18:07:49 idgay Exp $
 *
 */

/**
 * @author Jason Hill
 * @author David Gay
 * @author Philip Levis
 */


configuration GenericCommPromiscuous
{
  provides {
    interface StdControl as Control;
    interface CommControl;

    // The interface are as parameterised by the active message id
    interface SendMsg[uint8_t id];
    interface ReceiveMsg[uint8_t id];

    // How many packets were received in the past second
    command uint16_t activity();

  }
  uses {
    // signaled after every send completion for components which wish to
    // retry failed sends
    event result_t sendDone();


  }
}
implementation
{
  // CRCPacket should be multiply instantiable. As it is, I have to use
  // RadioCRCPacket for the radio, and UARTNoCRCPacket for the UART to
  // avoid conflicting components of CRCPacket.
  components AMPromiscuous as AM,
    RadioCRCPacket as RadioPacket, 
    UARTFramedPacket as UARTPacket,
    NoLeds as Leds, 
    TimerC, HPLPowerManagementM;

  Control = AM.Control;
  CommControl = AM.CommControl;
  SendMsg = AM.SendMsg;
  ReceiveMsg = AM.ReceiveMsg;
  sendDone = AM.sendDone;

  activity = AM.activity;
  AM.TimerControl -> TimerC.StdControl;
  AM.ActivityTimer -> TimerC.Timer[unique("Timer")];
  
  AM.UARTControl -> UARTPacket.Control;
  AM.UARTSend -> UARTPacket.Send;
  AM.UARTReceive -> UARTPacket.Receive;

  AM.RadioControl -> RadioPacket.Control;
  AM.RadioSend -> RadioPacket.Send;
  AM.RadioReceive -> RadioPacket.Receive;
  AM.PowerManagement -> HPLPowerManagementM.PowerManagement;

  AM.Leds -> Leds;
}

