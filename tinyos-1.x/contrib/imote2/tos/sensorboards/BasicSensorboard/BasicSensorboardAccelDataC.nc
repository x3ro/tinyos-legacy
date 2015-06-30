/**
*
*@author Robbie Adler
*
**/

configuration BasicSensorboardAccelDataC{
    provides {
      //      interface DSPManager;
      interface SensorData;
      interface StdControl;
    }
}

implementation {

  components BasicSensorboardAccelDataM as Data,
    PXA27XGPIOIntC,
    DVFSC,
    //    NoDSPM as DSPM,
    SSP1C as SSPC;
  
  SensorData = Data.SensorData;
  StdControl = Data.StdControl;
  
  
  Data.DVFS -> DVFSC;
  Data.SSP ->SSPC.SSP;
  Data.RawData -> SSPC.BulkTxRx;
  Data.RDYInterrupt -> PXA27XGPIOIntC.PXA27XGPIOInt[96];
}
