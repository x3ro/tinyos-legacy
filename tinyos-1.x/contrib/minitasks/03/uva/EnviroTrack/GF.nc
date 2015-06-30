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

configuration GF{
	provides{
        interface StdControl;
        interface RoutingSendByLocation [uint8_t app_ID];
        interface RoutingReceive        [uint8_t app_ID];
        interface RoutingSendByAddress  [uint8_t app_ID];
        interface Beacon;
    }
}

implementation{
	components GFM, GenericComm,RandomLFSR, 
	//LogicalTime
	TimerC,LocalM;
	
    GFM.T1_SendBeacon ->TimerC.Timer[unique("Timer")];
	GFM.T2_RefreshNT  ->TimerC.Timer[unique("Timer")];
    GFM.BackOffTimer -> TimerC.Timer[unique("Timer")];
    
    GFM.Random        ->RandomLFSR.Random;
    GFM.Local ->		LocalM.Local;
    GFM.CommControl      ->GenericComm;
    GFM.ReceiveDataMsg   ->GenericComm.ReceiveMsg[AM_GF_DATA_MSG];
    GFM.SendDataMsg         ->GenericComm.SendMsg[AM_GF_DATA_MSG];
    GFM.SendBeaconMsg       ->GenericComm.SendMsg[AM_GF_BEACON_MSG];
    GFM.ReceiveBeaconMsg ->GenericComm.ReceiveMsg[AM_GF_BEACON_MSG];
    
    StdControl            = GFM;
    RoutingSendByLocation = GFM;
    RoutingReceive        = GFM;
    RoutingSendByAddress  = GFM;
    Beacon                = GFM;
}
