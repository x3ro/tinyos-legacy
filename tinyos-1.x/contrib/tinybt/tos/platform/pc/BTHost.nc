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

/**************************************************************************/
/**
 * BTHost interface. Responds to the BTHost class???
 *
 * <p>Fill in description here.</p>
 */
interface BTHost
{
     command void Init(struct LMP* linkq);
     command void recvd(struct BTPacket* p, linkid_t lid, struct BTPacket* recvdPkt);
     command void recvdAppl(struct BTPacket* p, linkid_t lid, struct BTPacket* recvdPkt);
     command void transmitted(struct BTPacket* p, linkid_t lid);
     command void linkEstablished(linkid_t cd, bool bMaster);
     command void droppedApplPacket(struct BTPacket* p);
     command struct BTPacket* send(linkid_t lid);

     /** Get the bdaddr from the host.
      * 
      * \return the bdaddr of the host. */
     command btaddr_t hciGetBdAddr();
}
