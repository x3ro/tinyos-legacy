configuration OCEEPROM {
  provides {
    interface StdControl;
    interface SimpleEEPROM;
  }
}
implementation {
  components HPLOCEEPROM;

  StdControl = HPLOCEEPROM.StdControl;
  SimpleEEPROM = HPLOCEEPROM.SimpleEEPROM;
}
