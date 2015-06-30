//$Id: SensirionHumTempM.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

module SensirionHumTempM {
  provides interface StdControl;

  uses interface SplitControl;
  uses interface ADC as Humidity;
  uses interface ADC as Temperature;

  provides interface Attr<uint16_t> as SensirionHumidity
    @nucleusAttr("SensirionHumidity");

  provides interface Attr<uint16_t> as SensirionTemperature
    @nucleusAttr("SensirionTemperature");
}

implementation {
  
  uint16_t* humidityBuf;
  uint16_t* temperatureBuf;

  task void humidityDone();
  task void temperatureDone();

  command result_t StdControl.init() {
    call SplitControl.init();
    return SUCCESS;
  }
  event result_t SplitControl.initDone() { return SUCCESS; }

  command result_t StdControl.start() {
    call SplitControl.start();
    return SUCCESS;
  }
  event result_t SplitControl.startDone() { return SUCCESS; }

  command result_t StdControl.stop() {
    call SplitControl.stop();
    return SUCCESS;
  }
  event result_t SplitControl.stopDone() { return SUCCESS; }  

  command result_t SensirionHumidity.get(uint16_t* buf) {
    uint16_t* humidBuf;
    atomic humidBuf = humidityBuf;
      
    if (humidBuf != NULL)
      return FAIL;

    atomic humidityBuf = buf;
    if (call Humidity.getData() == FAIL) {
      atomic humidityBuf = NULL;
      return FAIL;
    }
    return SUCCESS;
  }

  async event result_t Humidity.dataReady(uint16_t data) {
    uint16_t* humidBuf;
    
    atomic humidBuf = humidityBuf;

    memcpy(humidBuf, &data, sizeof(uint16_t));

    post humidityDone();
    return SUCCESS;
  }

  task void humidityDone() {
    uint16_t* humidBuf;
    
    atomic humidBuf = humidityBuf;
    signal SensirionHumidity.getDone(humidBuf);
    atomic humidityBuf = NULL;
  }

  command result_t SensirionTemperature.get(uint16_t* buf) {
    uint16_t* tempBuf;
    atomic tempBuf = temperatureBuf;
      
    if (tempBuf != NULL)
      return FAIL;

    atomic temperatureBuf = buf;
    if (call Temperature.getData() == FAIL) {
      atomic temperatureBuf = NULL;
      return FAIL;
    }
    return SUCCESS;
  }

  async event result_t Temperature.dataReady(uint16_t data) {
    uint16_t* tempBuf;
    
    atomic tempBuf = temperatureBuf;

    memcpy(tempBuf, &data, sizeof(uint16_t));

    post temperatureDone();
    return SUCCESS;
  }

  task void temperatureDone() {
    uint16_t* tempBuf;
    
    atomic tempBuf = temperatureBuf;
    signal SensirionTemperature.getDone(tempBuf);
    atomic temperatureBuf = NULL;
  }  

  default event result_t SensirionHumidity.getDone(uint16_t* buf) { return SUCCESS; }
  default event result_t SensirionTemperature.getDone(uint16_t* buf) { return SUCCESS; }
}
