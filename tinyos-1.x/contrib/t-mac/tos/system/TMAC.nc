/*
 * Copyright (c) 2002-2004 the University of Southern California
 * Copyright (c) 2004 TU Delft/TNO
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement 
 * is hereby granted, provided that the above copyright notice and the
 * following two paragraphs appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE COPYRIGHT HOLDERS BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE
 * COPYRIGHT HOLDERS HAVE BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE COPYRIGHT HOLDERS SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER
 * IS ON AN "AS IS" BASIS, AND THE COPYRIGHT HOLDERS HAVE NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 *
 * Authors:	Wei Ye (S-MAC version), Tom Parker (T-MAC modifications)
 * 
 * This module implements Timeout-MAC (T-MAC)
 * http://www.consensus.tudelft.nl/documents_delft/03vandam.pdf 
 *
 * It has the following functions.
 *  1) Low-duty-cycle operation on radio -- periodic listen and sleep
 *  2) Broadcast only uses CSMA
 *  3) Many features for unicast
 *     - RTS/CTS for hidden terminal problem
 *     - fragmentation support for a long message
 *       A long message is divided (by upper layer) into multiple fragments.
 *       The RTS/CTS reserves the medium for the entire message.
 *       ACK is used for each fragment for immediate error recovery.
 *     - Node goes to sleep when its neighbors are talking to other nodes.
 *
 * This configuration sets T-MAC to put time stamp on each received pkt
 *   using internal clock (1ms resolution). If fine-grained time stamp is 
 *   needed, provide an external implementation of TimeStamp interface to
 *   suply the time. To do it, change the wiring of ExtTimeStamp to your 
 *   own TimeStamp implementation. Please give the new configuration a new
 *   name.
 */

/**
 * @author Wei Ye
 * @author Tom Parker
 */


configuration TMAC
{
   provides {
      interface StdControl;
      interface MACComm;
      interface MACTest;
      //interface MACPerformance;
	  interface RoutingHelpers;
   }
   /*uses {
      interface TimeStamp;
   }*/
}

implementation
{
   components TMACM, RadioControl as PhyRadio, RandomLFSR, ClockMSM, RadioSPIM;
   
   StdControl = TMACM;
   MACComm = TMACM;
   MACTest = TMACM;
   //MACPerformance = TMACM;
   //TimeStamp = TMACM;
   RoutingHelpers = TMACM;
   
   // wiring to lower layers
   
   TMACM.PhyControl -> PhyRadio;
   TMACM.RadioState -> PhyRadio.PhyState;
   TMACM.CarrierSense -> PhyRadio;
   TMACM.PhyComm -> PhyRadio;
   TMACM.Random -> RandomLFSR;
   
   TMACM.Clock -> ClockMSM.Clock[unique("ClockMSM")];
   TMACM.ClockControl -> ClockMSM;
   
   TMACM.Debug -> PhyRadio;
   TMACM.RadioSettings -> RadioSPIM;
}
