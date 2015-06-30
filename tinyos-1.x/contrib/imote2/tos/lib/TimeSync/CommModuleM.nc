includes TimeSyncMsg;
includes trace;

module CommModuleM {
  provides {
      //interface StdControl as Control;
    command result_t ComputeByteOffset(uint8_t* lo, uint8_t* hi);
  }
}

implementation {
    command result_t ComputeByteOffset(uint8_t* low, uint8_t* high) {
        *low = offsetof(TimeSyncMsg,sendingTime);
        *high = offsetof(TimeSyncMsg,sendingTimeHigh);
        return SUCCESS;
    }

}
