/* $Id: RadioCRCPacket.nc,v 1.1 2005/01/31 21:05:56 freefrag Exp $ */
/* RadioCRCPacket configuration, for use by the GenericComm component

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
 * RadioCRCPacket configuration, for use by the GenericComm component.
 * 
 * @author Mads Bondo Dydensborg <madsdyd@diku.dk>
 */
configuration RadioCRCPacket
{
  provides {
    interface StdControl as Control;
    interface BareSendMsg as Send;
    interface ReceiveMsg as Receive;
  }
}
implementation
{
  components SimpleMacCRCPacket as Packet;

  Control = Packet.Control;
  Send    = Packet.Send;
  Receive = Packet.Receive;

}
