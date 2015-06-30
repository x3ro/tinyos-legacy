// $Id: FramerM.nc,v 1.1.1.1 2007/11/05 19:11:34 jpolastre Exp $

/* -*- Mode: C; c-basic-indent: 2; indent-tabs-mode: nil -*- */ 
/*									
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
 * Author: Phil Buonadonna
 * Revision: $Revision: 1.1.1.1 $
 * 
 */

/**
 * This modules provides framing for TOS_Msg's using PPP-HDLC-like framing 
 * (see RFC 1662).  When sending, a TOS_Msg is encapsulated in an HLDC frame.
 * Receiving is similar EXCEPT that the component expects a special token byte
 * be received before the data payload. The purpose of the token is to feed back
 * an acknowledgement to the sender which serves as a crude form of flow-control.
 * This module is intended for use with the Packetizer class found in
 * tools/java/net/packet/Packetizer.java.
 * 
 * @author Phil Buonadonna
 */

configuration FramerM {

  provides {
    interface StdControl;
    interface TokenReceiveMsg;
    interface ReceiveMsg;
    interface BareSendMsg;
  }

  uses {
    interface ByteComm;
    interface StdControl as ByteControl;
    interface HPLUSARTControl as USARTControl;
  }
}

implementation {
  components FramerP;
  components HPLUSART1M;
  components UartPresenceC;
  components TimerC;
  StdControl = FramerP;
  TokenReceiveMsg = FramerP;
  ReceiveMsg = FramerP;
  BareSendMsg = FramerP;
  ByteComm = FramerP;
  ByteControl = FramerP;
  USARTControl = FramerP;
  FramerP.Timer -> TimerC.Timer[unique("Timer")];
  FramerP.Detect -> UartPresenceC;
  FramerP.USARTControl -> HPLUSART1M;
}
