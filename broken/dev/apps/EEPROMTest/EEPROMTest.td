configuration EEPROMTest { }
implementation
{
  components Main, EEPROMTestM, EEPROM, GenericComm as Comm, LedsC;

  Main.StdControl -> EEPROMTestM;

  EEPROMTestM.EEPROMControl -> EEPROM;
  EEPROMTestM.EEPROMRead -> EEPROM;
  EEPROMTestM.EEPROMWrite -> EEPROM.EEPROMWrite[42];

  EEPROMTestM.Leds -> LedsC;

  EEPROMTestM.CommControl -> Comm;
  EEPROMTestM.ReceiveTestMsg -> Comm.ReceiveMsg[100];
  EEPROMTestM.SendResultMsg -> Comm.SendMsg[101];
}
