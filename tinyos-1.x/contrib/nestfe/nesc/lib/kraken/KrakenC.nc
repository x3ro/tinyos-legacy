// $Id: KrakenC.nc,v 1.18 2005/08/24 19:00:57 jwhui Exp $

/*									tab:4
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
 */

/* Pull in and initialize the core services of the Kraken environment.
 * A kraken is a multi-tentacle water monster (aka giant squid).
 */

configuration KrakenC
{
  provides interface StdControl;
}
implementation
{
  components KrakenMain;

  // pre control
  components TimerC;
  components ADCC;

  // app control
  components GenericComm;

#ifndef NO_NUCLEUS
  components RemoteSetC;
  StdControl = RemoteSetC;
  components GrouperC;
  StdControl = GrouperC;
  components IdentC;
  StdControl = IdentC;
  components LedsAttrC;
  components McuTemperatureAttrC;
  StdControl = McuTemperatureAttrC;
  components McuVoltageAttrC;
  StdControl = McuVoltageAttrC;
#endif

  // pre control
  KrakenMain.PreInitControl -> TimerC;

#ifndef NO_SENSORS //we need this for the pc platform, but it doesn't work yet
  components KrakenWatchdogC;
  KrakenMain.PreInitControl -> KrakenWatchdogC;
  KrakenMain.PreInitControl -> ADCC;
#endif //NO_SENSORS

#ifndef NO_PROMETHEUS
  components IOSwitchC;
  components VoltageCheckC;
  KrakenMain.PreInitControl -> IOSwitchC.StdControl;
  KrakenMain.PreInitControl -> VoltageCheckC;
  KrakenMain.Init -> VoltageCheckC;
  components ChargerC;
  components PWSwitchC;
  components WakeupC;
  StdControl = ChargerC;
  StdControl = PWSwitchC;
  StdControl = WakeupC;
  //components VoltageHysteresisC;
  //KrakenMain.PreInitControl -> VoltageHysteresisC;
  //KrakenMain.Init -> VoltageHysteresisC;
#endif //NO_PROMETHEUS

  // app control, probably wired to Main.StdControl, which gets wired back to
  // KrakenMain.AppControl by KrakenMain
  StdControl = GenericComm;

#ifndef NO_REGISTRY
  components RegistryC;
  StdControl = RegistryC;
#endif //NO_REGISTRY

#ifndef NO_REGISTRY_STORE
  components RegistryStoreC;
#endif //NO_REGISTRY_STORE

#ifndef NO_TIMESYNC
  components TimeSyncC;
  components TimeSyncAttrC;
  StdControl = TimeSyncC;
#endif //NO_TIMESYNC

#ifndef NO_RPC
  components RpcC;
  StdControl = RpcC;
#endif //NO_RPC

#ifndef NO_PYTHON
  components RamSymbolsM;
#endif //NO_PYTHON

#ifndef NO_NUCLEUS
  components MgmtQueryC;
  StdControl = MgmtQueryC;
#ifndef NO_DELUGE
  components DelugeStatsC;
#endif //NO_DELUGE
#endif //NO_NUCLEUS

#ifndef NO_DELUGE
  components DelugeC;
  StdControl = DelugeC;
#endif //NO_DELUGE

#ifndef NO_LOCATION
  components LocationC;
  StdControl = LocationC;
#endif //NO_LOCATION
}

