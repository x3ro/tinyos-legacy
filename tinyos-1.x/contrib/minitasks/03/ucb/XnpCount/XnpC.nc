includes Xnp;

configuration XnpC
{
  provides interface Xnp;
  
}

implementation{
  components Main, XnpM, GenericComm, EEPROM,LedsC, RandomLFSR;

  Xnp = XnpM.Xnp;

  Main.StdControl -> XnpM.StdControl;
  XnpM.ReceiveMsg -> GenericComm.ReceiveMsg[AM_XnpMsg_ID];
  XnpM.SendMsg    -> GenericComm.SendMsg[AM_XnpMsg_ID];  
  XnpM.GenericCommCtl -> GenericComm;
  XnpM.Leds -> LedsC;
  XnpM.EEPROMControl -> EEPROM;
  XnpM.EEPROMRead -> EEPROM.EEPROMRead;
  XnpM.EEPROMWrite -> EEPROM.EEPROMWrite[EEPROM_ID];
  XnpM.Random -> RandomLFSR;
}

//end
