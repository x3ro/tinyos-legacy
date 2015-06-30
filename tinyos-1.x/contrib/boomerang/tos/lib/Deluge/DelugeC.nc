// $Id: DelugeC.nc,v 1.1.1.1 2007/11/05 19:11:24 jpolastre Exp $

/*									tab:4
 *
 *
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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

/**
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 */

#include "BitVecUtils.h"
#include "crc.h"
#include "Deluge.h"
#include "DelugeMetadata.h"
#include "DelugeMsgs.h"
#include "NetProg.h"

configuration DelugeC {
  provides {
    interface StdControl;
  }
}

implementation {

  components MainDelugeC;
  components
    BitVecUtilsC,
    CrcC,
    DelugeM,
    DelugeMetadataC as Metadata,
    DelugePageTransferC as PageTransfer,
    NetProgC,
    RandomLFSR,
    new SharedMsgBufM() as Buf1,
    new SharedMsgBufM() as Buf2,
    new SharedMsgBufM() as Buf3,
    new SharedMsgBufM() as Buf4,
    NullStdControl,
    GenericComm as Comm,
    TimerC;

#ifdef DELUGE_LEDS
  components LedsC as Leds;
#else
  components NoLeds as Leds;
#endif

#if defined(DELUGE_LEDS) || defined(DELUGE_PAGETRANSFER_LEDS)
  components LedsC as PageTransferLeds;
#else
  components NoLeds as PageTransferLeds;
#endif

#ifndef PLATFORM_PC
  components InternalFlashC as IFlash;
  DelugeM.IFlash -> IFlash;
#endif

  // controlled by Main* components.
  StdControl = NullStdControl;

  DelugeM.MetadataControl -> Metadata;
  DelugeM.PageTransferControl -> PageTransfer;

  DelugeM.Crc -> CrcC;
  DelugeM.Leds -> Leds;
  DelugeM.Metadata -> Metadata;
  DelugeM.NetProg -> NetProgC;
  DelugeM.PageTransfer -> PageTransfer;
  DelugeM.Random -> RandomLFSR;
  DelugeM.ReceiveAdvMsg -> Comm.ReceiveMsg[AM_DELUGEADVMSG];
  DelugeM.SendAdvMsg-> Comm.SendMsg[AM_DELUGEADVMSG];
  DelugeM.Buf1 -> Buf1;
  DelugeM.Buf2 -> Buf2;
  DelugeM.Timer -> TimerC.Timer[unique("Timer")];

  PageTransfer.Leds -> PageTransferLeds;
  PageTransfer.ReceiveDataMsg -> Comm.ReceiveMsg[AM_DELUGEDATAMSG];
  PageTransfer.ReceiveReqMsg -> Comm.ReceiveMsg[AM_DELUGEREQMSG];
  PageTransfer.SendDataMsg -> Comm.SendMsg[AM_DELUGEDATAMSG];
  PageTransfer.SendReqMsg -> Comm.SendMsg[AM_DELUGEREQMSG];
  PageTransfer.SharedMsgBufTX -> Buf3;
  PageTransfer.SharedMsgBufRX -> Buf4;

}
