configuration EEPROMC{

  provides{
    interface StdControl;
    interface EEPROM;
  }
}
implementation{
  components EEPROMM, 
    PXA27XInterruptM;
  
  EEPROM = EEPROMM;
  StdControl = EEPROMM;
  EEPROMM.I2CInterrupt -> PXA27XInterruptM.PXA27XIrq[IID_I2C];
}
