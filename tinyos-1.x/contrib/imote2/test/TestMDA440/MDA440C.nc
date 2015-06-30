/**
*
*@author Robbie Adler
*
**/

configuration MDA440C{
    provides {
    interface MDA440;
    interface EEPROM;
    interface StdControl;
    }
}

implementation {

  components MDA440M,
    EEPROMC,
    PXA27XGPIOIntC, 
    SSP1C as SSPC;

  StdControl = EEPROMC;
  EEPROM = EEPROMC;
  MDA440 = MDA440M.MDA440;
  MDA440M.SSP ->SSPC.SSP;
  MDA440M.BulkTxRx -> SSPC.BulkTxRx;

  MDA440M.TACHInterrupt -> PXA27XGPIOIntC.PXA27XGPIOInt[107];
}
