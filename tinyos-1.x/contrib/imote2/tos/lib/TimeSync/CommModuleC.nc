configuration CommModuleC {
  provides interface StdControl;
  provides interface SendMsg[uint8_t id];
  provides interface ReceiveMsg[uint8_t id];
  provides command result_t ComputeByteOffset(uint8_t* lo, uint8_t* hi);
}

implementation {
  components GenericComm, CommModuleM;

  StdControl = GenericComm.Control;
  SendMsg = GenericComm.SendMsg;
  ReceiveMsg = GenericComm.ReceiveMsg;
  ComputeByteOffset = CommModuleM.ComputeByteOffset;

}

