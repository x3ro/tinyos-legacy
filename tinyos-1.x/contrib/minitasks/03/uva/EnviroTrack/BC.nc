/* "Copyright (c) 2000-2002 University of Virginia.  
 * All rights reserved.
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF VIRGINIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * VIRGINIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF VIRGINIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF VIRGINIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 * 
 * Authors: Gary Zhou,Tian He 
 */


includes UVARouting;

configuration BC{
    provides{
        interface StdControl;
        interface RoutingSendByBroadcast     [uint8_t app_ID];
        interface RoutingReceive             [uint8_t app_ID];
    }
}

implementation{
    components BCM, GenericComm,//LogicalTime
    TimerC,RandomLFSR;

    BCM.RoutingControl  -> GenericComm;
    BCM.ReceiveDataMsg  -> GenericComm.ReceiveMsg   [AM_BC_DATA_MSG];
    BCM.SendDataMsg     -> GenericComm.SendMsg      [AM_BC_DATA_MSG];
	BCM.BackOffTimer ->  TimerC.Timer[unique("Timer")];
    StdControl              =  BCM;
    RoutingSendByBroadcast  =  BCM;
    RoutingReceive          =  BCM;
    BCM.Random -> RandomLFSR;
}
