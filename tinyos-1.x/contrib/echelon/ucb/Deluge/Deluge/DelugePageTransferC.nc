
/**
 * DelugePageTransferC.nc - Handles the transfer of individual data
 * pages between neighboring nodes.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @since  0.1
 */

configuration DelugePageTransferC {
  provides {
    interface DelugePageTransfer;
    interface StdControl;
  }
  uses {
    interface SendMsg as SendReqMsg;
    interface SendMsg as SendDataMsg;
    interface ReceiveMsg as ReceiveReqMsg;
    interface ReceiveMsg as ReceiveDataMsg;

#ifdef DELUGE_REPORTING_UART
    interface SendMsg as SendDbgMsg;
#endif

#ifndef PLATFORM_PC
    event result_t sendDurationMsg(uint8_t status, uint16_t value);
#endif
  }
}
implementation {
  components
    DelugePageTransferM,
    BitVecUtilsC,
    DelugeMetadataC as Metadata,
    DelugeStableStoreC as StableStore,
    RandomLFSR,
    LedsC,
    TimerC;

  StdControl = DelugePageTransferM;
  DelugePageTransfer = DelugePageTransferM;
#ifndef PLATFORM_PC
  DelugePageTransferM.sendDurationMsg = sendDurationMsg;
#endif

  DelugePageTransferM.Leds -> LedsC;
  DelugePageTransferM.BitVecUtils -> BitVecUtilsC;
  DelugePageTransferM.Metadata -> Metadata;
  DelugePageTransferM.StableStore -> StableStore;
  DelugePageTransferM.Random -> RandomLFSR;
  DelugePageTransferM.SendReqMsg = SendReqMsg;
  DelugePageTransferM.ReceiveReqMsg = ReceiveReqMsg;
  DelugePageTransferM.SendDataMsg = SendDataMsg;
  DelugePageTransferM.ReceiveDataMsg = ReceiveDataMsg;
  DelugePageTransferM.ReqTimer -> TimerC.Timer[unique("Timer")];
  DelugePageTransferM.SendTimer -> TimerC.Timer[unique("Timer")];

#ifdef DELUGE_REPORTING_UART
  DelugePageTransferM.SendDbgMsg = SendDbgMsg;
#endif
}
