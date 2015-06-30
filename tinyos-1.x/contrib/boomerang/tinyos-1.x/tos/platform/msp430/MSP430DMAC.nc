configuration MSP430DMAC {
  provides {
    interface DMA[uint8_t channel];
    interface DMAControl;
  }
}
implementation {
  components HALDMAM as MSP430DMAM, MSP430DMAM as HPLDMAM;
  DMA = MSP430DMAM;
  DMAControl = MSP430DMAM;
  MSP430DMAM.MSP430DMAControl -> HPLDMAM.DMAControl;
  MSP430DMAM.DMAChannelCtrl0 -> HPLDMAM.DMAChannelCtrl0;
  MSP430DMAM.DMAChannelCtrl1 -> HPLDMAM.DMAChannelCtrl1;
  MSP430DMAM.DMAChannelCtrl2 -> HPLDMAM.DMAChannelCtrl2;
}
