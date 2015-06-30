// $Id: XnpC.nc,v 1.1.1.1 2007/11/05 19:10:05 jpolastre Exp $

includes Xnp;

configuration XnpC
{
  provides interface Xnp;
  
}

implementation{
  components Main, XnpM, GenericComm, EEPROM,LedsC, RandomLFSR, TSC;

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
  XnpM.TS -> TSC.TS;
}

//end
