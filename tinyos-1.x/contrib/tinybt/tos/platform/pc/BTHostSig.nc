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

/**
 * BTHostSig interface.
 *
 * <p>We need to split the BTHost implementation in two interfaces, as
 * the modules calling the commands are not the same as the modules
 * that wants to have the events. This does not fit the TinyOS
 * programming model very well, but perhaps it could have been done
 * smarter.</p> */
interface BTHostSig
{
     event void dropped(struct BTPacket* p);
     event void queueFull(linkid_t outLid, linkid_t inLid);

     event void hci2HostTimerExpiredEvent();
     event void hciCommandStatusEvent(enum hci_cmd cmd, bool succ);
     event void hciConnectionCompleteEvent(linkid_t ch, bool bMasRole);
     event void hciConnectionRequestEvent(linkid_t ch);
     event void hciDisconnectionCompleteEvent(linkid_t ch);

     event void hciHoldExpiredEvent(linkid_t ch);
     event void hciInqRespSentEvent();
     
     /** Signal an inquiry result. */
     event void hciInquiryResult(struct fhspayload* addr_vec);

     /** Signal that the inquiry is over */
     event void hciInquiryComplete();


     event void hciModeChangeEvent(linkid_t ch, bool bSuccess, enum btmode cur, int intv);
     event void hciRoleChangeEvent(bool bMaster, linkid_t ch);
     event void hciScanCompleteEvent(enum timer_t tm, bool bRespTO);
     event void pollMissed(linkid_t ch);
     event void recvPkt(struct BTPacket* p, linkid_t ch);
     event void recvPktAppl(struct BTPacket* p);
}
