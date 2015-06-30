/*
 * Copyright (c) 2002 the University of Southern California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice and the following
 * two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF SOUTHERN CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * UNIVERSITY OF SOUTHERN CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF SOUTHERN CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF SOUTHERN CALIFORNIA HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors: Jerry Zhao, Wei Ye
 * Date created: 2/21/2003
 * 
 * This is a Wrapper for S-MAC to provide standard tinyos Send/Receive
 *   interface, so that AMStandard can run over S-MAC.
 *
 * This component is to provide compatibilty to Berkeley's comm stack and 
 *   enable applications developed on Berkeley's stack to run over S-MAC 
 *   without modification. However, to use all functionality provided by 
 *   S-MAC, you need to develop your application directly over S-MAC.
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
  components 
	SMACWrapper,
	SMAC;

  Control= SMACWrapper;
  Send = SMACWrapper; 
  Receive = SMACWrapper;

  SMACWrapper.MACControl -> SMAC;
  SMACWrapper.MACComm -> SMAC;
}
