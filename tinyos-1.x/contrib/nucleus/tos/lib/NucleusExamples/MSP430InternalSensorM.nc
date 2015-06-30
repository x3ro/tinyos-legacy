//$Id: MSP430InternalSensorM.nc,v 1.3 2005/06/14 18:22:21 gtolle Exp $

module MSP430InternalSensorM {
  provides {
    interface StdControl;
    interface Attr<uint16_t> as Voltage @nucleusAttr("Voltage");
    interface Attr<uint16_t> as Temperature @nucleusAttr("Temperature");
  }
  uses {
    interface StdControl as SubControl;

    interface ADC as VoltageADC;
    interface ADC as TemperatureADC;
  }    
}
implementation {

  uint16_t* temperatureBuf;
  uint16_t* voltageBuf;

  task void tempDone();
  task void voltageDone();

  command result_t StdControl.init() {
    return call SubControl.init();
  }

  command result_t StdControl.start() {
    return call SubControl.start();
  }

  command result_t StdControl.stop() {
    return call SubControl.stop();
  }

  command result_t Temperature.get(uint16_t* buf) {
    uint16_t* tempBuf;
    atomic tempBuf = temperatureBuf;
      
    if (tempBuf != NULL)
      return FAIL;

    atomic temperatureBuf = buf;
    return call TemperatureADC.getData();
  }

  async event result_t TemperatureADC.dataReady(uint16_t data) {
    uint16_t* tempBuf;
    
    atomic tempBuf = temperatureBuf;

    memcpy(tempBuf, &data, sizeof(uint16_t));

    post tempDone();
    return SUCCESS;
  }

  task void tempDone() {
    uint16_t* tempBuf;
    
    atomic tempBuf = temperatureBuf;
    signal Temperature.getDone(tempBuf);
    atomic temperatureBuf = NULL;
  }

  command result_t Voltage.get(uint16_t* buf) {
    uint16_t* voltBuf;
    atomic voltBuf = voltageBuf;
      
    if (voltBuf != NULL)
      return FAIL;

    atomic voltageBuf = buf;
    return call VoltageADC.getData();
  }

  async event result_t VoltageADC.dataReady(uint16_t data) {
    uint16_t* voltBuf;
    
    atomic voltBuf = voltageBuf;

    memcpy(voltBuf, &data, sizeof(uint16_t));

    post voltageDone();
    return SUCCESS;
  }

  task void voltageDone() {
    uint16_t* voltBuf;
    
    atomic voltBuf = voltageBuf;
    signal Voltage.getDone(voltBuf);
    atomic voltageBuf = NULL;
  }

  default event result_t Voltage.getDone(uint16_t* buf) { return SUCCESS; }
  default event result_t Temperature.getDone(uint16_t* buf) { return SUCCESS; }
}



