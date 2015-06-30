//$Id: RemoteSetC.nc,v 1.4 2005/06/16 21:56:16 cssharp Exp $

includes Attrs;
includes DestMsg;
includes RemoteSet;
includes AM;

/**
 * This module processes messages used to set attributes remotely, and
 * calls the set methods of the attributes.
 *
 * @author Gilman Tolle
 */
configuration RemoteSetC {
  provides {
    interface StdControl;
  }
}
implementation {

  components 
    RemoteSetM,
    AttrsC,
    GenericComm,
    DestC;

#ifdef NUCLEUS_NO_LEDS
  components NoLeds as Leds;
#else
  components LedsC as Leds;
#endif

  components DripC, DripStateC;

  StdControl = RemoteSetM;

  RemoteSetM.SubControl -> AttrsC;
  RemoteSetM.SubControl -> GenericComm;
  RemoteSetM.SubControl -> DripC;

  RemoteSetM.Leds -> Leds;
  
  RemoteSetM.AttrSetClient -> AttrsC.AttrSetClient;

  RemoteSetM.SetReceiveLocal -> GenericComm.ReceiveMsg[AM_REMOTESETMSG];

  RemoteSetM.SetReceive -> DripC.Receive[AM_REMOTESETMSG];
  RemoteSetM.SetDrip -> DripC.Drip[AM_REMOTESETMSG];
  DripC.DripState[AM_REMOTESETMSG] -> DripStateC.DripState[unique("DripState")];

  RemoteSetM.Dest -> DestC;
}

