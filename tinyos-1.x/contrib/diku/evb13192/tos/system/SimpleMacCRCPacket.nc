/* $Id: SimpleMacCRCPacket.nc,v 1.1 2005/01/31 21:05:56 freefrag Exp $ */
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
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
configuration SimpleMacCRCPacket {
  provides {
    interface StdControl  as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg  as Receive;
  }
}
implementation {
  components SimpleMacM, SimpleMacCRCPacketM as Packet;
  
  Packet.Mac -> SimpleMacM;
  Control     = Packet.StdControl;
  Send        = Packet.Send;
  Receive     = Packet.Receive;
}
