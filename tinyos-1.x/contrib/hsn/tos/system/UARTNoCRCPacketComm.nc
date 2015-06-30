/*                                                                      tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *
 */
/*                                                                      tab:4
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
 */
/*                                                                      tab:4
 * Copyright (c) 2003 Intel Corporation
 * All rights reserved Contributions to the above software program by Intel
 * Corporation is program is licensed subject to the BSD License, available at
 * http://www.opensource.org/licenses/bsd-license.html
 *
 */
/*
 * Authors:	Jason Hill, David Gay, Philip Levis, York Liu
 *
 */
// This is an copy from UARTNoCRCPacketCommM.nc without hooking up to Radio part. Only the
// UART part which implements the multiple output devices.
// Only dest address to UART will be handled here

configuration UARTNoCRCPacketComm {
   provides {
      interface StdControl as Control;
    
      interface BareSendMsg[uint8_t id];
      interface ReceiveMsg[uint8_t id];

      // How many packets were received in the past second
      command uint16_t activity();
   }

   uses {
      event result_t sendDone();
   }
}

implementation
{
   components UARTNoCRCPacketCommM,
#ifdef NO_UART_FRAMED
// no frame - old-serial@ or old-sf@ + uartserver -2 9001 -r56 COM1 9000
              UARTNoCRCPacket as UARTPacket,
#else
#ifdef TINYOS_UART_FRAMED
// TinyOS frame - serial@ or sf@ + uartserver -2 9001 -r56 COM1 9000
	      UARTFramedPacket as UARTPacket,
#else
// HSN frame - old-sf@ + uartserver -2 COM1 9001 -r56 9000
              UARTFramedNoCRCPacket as UARTPacket,
#endif
#endif
              TimerC,
              HPLPowerManagementM;

   Control = UARTNoCRCPacketCommM.Control;
   BareSendMsg = UARTNoCRCPacketCommM.BareSendMsg;
   ReceiveMsg = UARTNoCRCPacketCommM.ReceiveMsg;
   activity = UARTNoCRCPacketCommM.activity;
   sendDone = UARTNoCRCPacketCommM.sendDone;

   UARTNoCRCPacketCommM.TimerControl -> TimerC.StdControl;  
   UARTNoCRCPacketCommM.ActivityTimer -> TimerC.Timer[unique("Timer")];
  
   UARTNoCRCPacketCommM.UARTControl -> UARTPacket.Control;
   UARTNoCRCPacketCommM.UARTSend -> UARTPacket.Send;
   UARTNoCRCPacketCommM.UARTReceive -> UARTPacket.Receive;
   UARTNoCRCPacketCommM.PowerManagement -> HPLPowerManagementM;
}
