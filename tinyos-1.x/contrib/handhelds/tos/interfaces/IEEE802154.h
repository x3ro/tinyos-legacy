// $Id: IEEE802154.h,v 1.3 2006/09/07 18:36:07 ayer1 Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:	        Joe Polastre
 *
 */

/**
 * @author Joe Polastre
 */

/**
 *  Trimmed down for testing in our local contrib tree.  This file can (and will) be
 *  replaced by the IEEE802154.h file from the tos/beta tree.
 *
 *  Andrew Christian <andrew.christian@hp.com>
 *  May 2005
 * 
 */

#ifndef _IEEE802154_H
#define _IEEE802154_H

/**************************************************** 
 * #defines for PHY sublayer constants
 */
#define IEEE802154_aMaxPHYPacketSize            127
#define IEEE802154_aTurnaroundTime              12

/**************************************************** 
 * #defines for MAC sublayer constants
 */
#define IEEE802154_aBaseSlotDuration            60
#define IEEE802154_aNumSuperframeSlots          16
#define IEEE802154_aBaseSuperframeDuration      IEEE802154_aBaseSlotDuration * IEEE802154_aNumSuperframeSlots
#define IEEE802154_aExtendedAddress
#define IEEE802154_aMaxBE                       5
#define IEEE802154_aMaxBeaconOverhead           75
#define IEEE802154_aMaxBeaconPayloadLength      IEEE802154_aMaxPHYPacketSize - IEEE802154_aMaxBeaconOverhead
#define IEEE802154_aGTSDescPersistenceTime      4
#define IEEE802154_aMaxFrameOverhead            25
#define IEEE802154_aMaxFrameResponseTime        1220
#define IEEE802154_aMaxFrameRetries             3
#define IEEE802154_aMaxLostBeacons              4
#define IEEE802154_aMaxMACFrameSize             IEEE802154_aMaxPHYPacketSize - aMaxFrameOverhead
#define IEEE802154_aMaxSIFSFrameSize            18
#define IEEE802154_aMinCAPLength                440
#define IEEE802154_aMinLIFSPeriod               40
#define IEEE802154_aMinSIFSPeriod               12
#define IEEE802154_aResponseWaitTime            32 * IEEE802154_aBaseSuperframeDuration
#define IEEE802154_aUnitBackoffPeriod           20

/* 
 * A symbol is 16 uS (in the 2.4 GHz band)
 * There are 32768 jiffies per second.
 * This macro is only useful for static conversions 
 */

#define SYMBOLS_TO_JIFFIES(_sym) ((int)(_sym * 0.524288 + 1))
#define SYMBOLS_TO_MILLISECONDS(_sym) ((int)(_sym * 0.016 + 1))

#endif /* _IEEE802154_H */
