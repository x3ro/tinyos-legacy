/**
*
*@author Robbie Adler
*
**/

configuration QuickFilterQF4A512C{
    provides {
      //      interface DSPManager;
      interface SensorData[uint8_t channel];
      interface StdControl;
      interface QuickFilterQF4A512;
    }
}

implementation {

  components QuickFilterQF4A512M as Data,
    PXA27XGPIOIntC,
    DVFSC,
    LedsC,
    BluSHC,
    //    NoDSPM as DSPM,
    SSP1C as SSPC;
  
  SensorData = Data.SensorData;
  StdControl = Data.StdControl;
  
  QuickFilterQF4A512 = Data.QuickFilterQF4A512;
  Data.DVFS -> DVFSC;
  Data.SSP ->SSPC.SSP;
  Data.RawData -> SSPC.BulkTxRx;
  Data.DRDYInterrupt -> PXA27XGPIOIntC.PXA27XGPIOInt[10];
  Data.Leds->LedsC;

  BluSHC.BluSH_AppI[unique("BluSH")] -> Data.ManualRead;
  BluSHC.BluSH_AppI[unique("BluSH")] -> Data.ClearCal;
}
