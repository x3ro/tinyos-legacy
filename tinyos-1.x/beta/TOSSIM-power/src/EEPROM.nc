
configuration EEPROM
{
  provides {
    interface StdControl;
    interface EEPROMRead;
    interface EEPROMWrite[uint8_t writerId];
  }
}
implementation
{
     components EEPROMM, PowerStateM;
     EEPROMRead = EEPROMM.EEPROMRead;
     EEPROMWrite = EEPROMM.EEPROMWrite;
     StdControl = EEPROMM.StdControl;
     EEPROMM.PowerState -> PowerStateM;
}




