includes Xnp;

configuration XnpC
{
  provides interface Xnp;
  provides interface StdControl;
  
}

implementation{
  components EEPROM, XnpM, GenericComm, LedsC, RandomLFSR;

// CSS: I've put EEPROM first in the components list so that any #define's
// as a side-effect occur before XnpM.  Because, if it happens to pull in
// PageEEPROM.h, we must throw an error.

  Xnp = XnpM.Xnp;
  StdControl = XnpM.StdControl;

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
