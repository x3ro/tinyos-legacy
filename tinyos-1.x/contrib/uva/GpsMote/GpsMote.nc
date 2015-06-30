// $Header: /cvsroot/tinyos/tinyos-1.x/contrib/uva/GpsMote/GpsMote.nc,v 1.2 2004/04/09 06:38:42 rsto99 Exp $

/* "Copyright (c) 2000-2004 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

// Author: Radu Stoleru
// Date: 3/26/2004

configuration GpsMote {
}
implementation {
  components Main, GpsMoteM as GpsBaseM, RadioCRCPacket as Comm, 
    UARTNoCRCGpsPacket as Packet, LedsC, TimerC, CC1000ControlM,
    Logger;

  Main.StdControl->GpsBaseM;
  Main.StdControl->Logger;
  GpsBaseM.UARTControl -> Packet;
  GpsBaseM.UARTSend -> Packet;
  GpsBaseM.UARTReceive -> Packet;
  GpsBaseM.RadioControl -> Comm;
  GpsBaseM.RadioSend -> Comm;
  GpsBaseM.RadioReceive -> Comm;
  GpsBaseM.Leds -> LedsC;
  GpsBaseM.Timer->TimerC.Timer[unique("Timer")];
  GpsBaseM.CC1000Control->CC1000ControlM;
  GpsBaseM.LoggerRead->Logger;
  GpsBaseM.LoggerWrite->Logger;
}
