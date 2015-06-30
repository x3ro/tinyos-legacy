
/**
 * DelugeC.nc - Top level configuration for the Deluge protocol. Links
 * up components necessary to transfer pages, manage metadata, and
 * access to stable storage.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

includes Deluge;
includes DelugePageTransfer;
includes DelugeMsgs;

configuration DelugeC {
  provides {
    interface NetProg;
    interface StdControl;
  }
}
implementation {

  components 
    Main,
    BitVecUtilsC,
    DelugeM,
    DelugeMetadataC as Metadata,
    DelugePageTransferC as PageTransfer,
    DelugeStableStoreC as StableStore,
    RandomLFSR,
//#ifdef PLATFORM_PC
    GenericCommPromiscuous as Comm,
//#else
//    GenericCommPromiscuous as RealComm,
//    GenericCommDbgM as Comm,
//#endif
    LedsC,
    TimerC;

#ifdef DELUGE_REPORTING_MHOP
  components WMEWMAMultiHopRouter as Multihop;
#endif

  StdControl = DelugeM;
  StdControl = TimerC;
  StdControl = StableStore;
  StdControl = Comm;
  NetProg = DelugeM;

  DelugeM.Leds -> LedsC;
  DelugeM.BitVecUtils -> BitVecUtilsC;
  DelugeM.Metadata -> Metadata;
  DelugeM.MetadataControl -> Metadata.StdControl;
  DelugeM.PageTransferControl -> PageTransfer.StdControl;
  DelugeM.PageTransfer -> PageTransfer;
  DelugeM.Timer -> TimerC.Timer[unique("Timer")];
  DelugeM.Random -> RandomLFSR;

  DelugeM.SendAdvMsg -> Comm.SendMsg[AM_DELUGEADVMSG];
  DelugeM.ReceiveAdvMsg -> Comm.ReceiveMsg[AM_DELUGEADVMSG];
  DelugeM.SendReqUpdMetadataMsg -> Comm.SendMsg[AM_DELUGEREQUPDMETADATAMSG];
  DelugeM.ReceiveReqUpdMetadataMsg -> Comm.ReceiveMsg[AM_DELUGEREQUPDMETADATAMSG];
  DelugeM.SendUpdMetadataMsg -> Comm.SendMsg[AM_DELUGEUPDMETADATAMSG];
  DelugeM.ReceiveUpdMetadataMsg -> Comm.ReceiveMsg[AM_DELUGEUPDMETADATAMSG];

//#ifdef PLATFORM_PC
//#else
//  DelugeM.CommControl -> RealComm;
//  Comm.RadioSend -> RealComm.SendMsg;
//  Comm.RadioReceive -> RealComm.ReceiveMsg;
//  Comm.Dump -> RealComm.SendMsg;

  // duration message stuff
//  DelugeM.sendDurationMsg -> Comm.sendDurationMsg;
//  PageTransfer.sendDurationMsg -> Comm.sendDurationMsg;
//#endif

  PageTransfer.SendReqMsg -> Comm.SendMsg[AM_DELUGEREQMSG];
  PageTransfer.ReceiveReqMsg -> Comm.ReceiveMsg[AM_DELUGEREQMSG];
  PageTransfer.SendDataMsg -> Comm.SendMsg[AM_DELUGEDATAMSG];
  PageTransfer.ReceiveDataMsg -> Comm.ReceiveMsg[AM_DELUGEDATAMSG];

#ifdef DELUGE_REPORTING_UART
  DelugeM.SendDbgMsg -> Comm.SendMsg[AM_DELUGEDURATIONMSG];
  PageTransfer.SendDbgMsg -> Comm.SendMsg[AM_DELUGEDURATIONMSG];
#endif

#ifdef DELUGE_REPORTING_MHOP
  StdControl = Multihop;
  DelugeM.SendDbgMHop -> Multihop.Send[AM_DELUGEREPORTINGMSG];
  Multihop.ReceiveMsg[AM_DELUGEREPORTINGMSG] -> 
    Comm.ReceiveMsg[AM_DELUGEREPORTINGMSG];
  DelugeM.RouteControl -> Multihop.RouteControl;
#endif
}
