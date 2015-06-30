/**
 * Copyright (c) 2003 - The University of Texas at Austin and
 *                      The Ohio State University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs, and the author attribution appear in all copies of this
 * software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE
 * UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL,
 * INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS
 * SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS AT AUSTIN
 * AND THE OHIO STATE UNIVERSITY HAVE BEEN ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY
 * SPECIFICALLY DISCLAIM ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND
 * THE UNIVERSITY OF TEXAS AT AUSTIN AND THE OHIO STATE UNIVERSITY HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */

/*
 *  Author/Contact: Young-ri Choi
 *                  yrchoi@cs.utexas.edu
 *
 *  This implementation is based on the design
 *  by Mohamed G. Gouda, Young-ri Choi, Anish Arora and Vinayak Naik.
 *
 */

includes GridTreeMsg;
includes AM;

configuration GridTree { 
	provides {
		interface GridInfo;
		interface StdControl;
	}
}
implementation {
  components GridTreeM, GenericComm as Comm, TimerC, LedsC, RandomLFSR, ReliableCommC, UARTNoCRCPacket;

  GridInfo = GridTreeM;
  StdControl = GridTreeM;

  GridTreeM.Leds -> LedsC;

  GridTreeM.CommControl -> Comm;
  GridTreeM.CommControl -> TimerC.StdControl; 

  GridTreeM.SendGTMsg -> Comm.SendMsg[AM_GRIDTREEMSG];
  GridTreeM.ReceiveGTMsg -> Comm.ReceiveMsg[AM_GRIDTREEMSG];
  GridTreeM.Timer -> TimerC.Timer[unique("Timer")];
  GridTreeM.Random -> RandomLFSR;
  
  GridTreeM.UARTSendGTMsg -> Comm.SendMsg[AM_UPDATEMSG];
  GridTreeM.UARTReceive -> UARTNoCRCPacket;
  GridTreeM.UARTControl -> UARTNoCRCPacket;
  GridTreeM.UARTSendPathMsg -> Comm.SendMsg[AM_UPDATEMSG2];

  GridTreeM.ReliableSendMsg -> ReliableCommC.ReliableSendMsg[AM_PATHMSG];
  GridTreeM.ReliableReceiveMsg -> ReliableCommC.ReliableReceiveMsg[AM_PATHMSG];
  GridTreeM.CommControl -> ReliableCommC.StdControl;
}
