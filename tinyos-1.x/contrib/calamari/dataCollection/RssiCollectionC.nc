/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
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
 */

/* Authors:   Kamin Whitehouse
 *
 */

//$Id: RssiCollectionC.nc,v 1.2 2005/10/14 23:54:57 kaminw Exp $

includes RssiCollection;

configuration RssiCollectionC
{
}
implementation
{
  components Main;
  components RssiCollectionM;
  components new BlockStorageC() as BlockData;
  components GenericComm as Comm
    , TimerC 
    , CC2420RadioC
    , StrawC
    , LedsC;
  components RpcC, RamSymbolsM;
  Main.StdControl -> RpcC;

#ifdef USE_KRAKEN
  components KrakenC;
  Main.StdControl -> KrakenC;
#endif //USE_KRAKEN
  Main.StdControl -> RssiCollectionM;
  Main.StdControl -> Comm;
  Main.StdControl -> StrawC;

  RssiCollectionM.SendChirpMsg -> Comm.SendMsg[AM_CHIRPMSG];
  RssiCollectionM.ReceiveChirpMsg -> Comm.ReceiveMsg[AM_CHIRPMSG];
  RssiCollectionM.CCControl->CC2420RadioC;	
  RssiCollectionM.Timer->TimerC.Timer[unique("Timer")]; 
  RssiCollectionM.TimerControl -> TimerC.StdControl;
  RssiCollectionM.Mount -> BlockData;
  RssiCollectionM.BlockRead -> BlockData;
  RssiCollectionM.Straw->StrawC.Straw[STRAW_TYPE_ID];
  RssiCollectionM.Leds->LedsC;

}

