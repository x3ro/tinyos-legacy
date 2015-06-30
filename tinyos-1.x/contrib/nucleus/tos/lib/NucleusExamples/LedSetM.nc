//$Id: LedSetM.nc,v 1.1 2005/07/06 01:48:34 gtolle Exp $

module LedSetM {
  provides interface Attr<uint8_t> as LEDRed @nucleusAttr("LEDRed");
  provides interface Attr<uint8_t> as LEDGreen @nucleusAttr("LEDGreen");
  provides interface Attr<uint8_t> as LEDBlue @nucleusAttr("LEDBlue");

  provides interface AttrSet<uint8_t> as LEDRedSet @nucleusAttr("LEDRed");
  provides interface AttrSet<uint8_t> as LEDGreenSet @nucleusAttr("LEDGreen");
  provides interface AttrSet<uint8_t> as LEDBlueSet @nucleusAttr("LEDBlue");

  uses interface Leds;
}
implementation {

#define BIT_GET(x, i) ((x) & (1 << (i)))
#define BIT_SET(x, i) ((x) | (1 << (i)))
#define BIT_CLEAR(x, i) ((x) & ~(1 << (i)))

  void getLed(uint8_t* buf, uint8_t ledNum);
  void setLed(uint8_t* buf, uint8_t ledNum);

  command result_t LEDRed.get(uint8_t* buf) {
    getLed(buf, 0);
    signal LEDRed.getDone(buf);
    return SUCCESS;
  }

  command result_t LEDGreen.get(uint8_t* buf) {
    getLed(buf, 1);
    signal LEDGreen.getDone(buf);
    return SUCCESS;
  }

  command result_t LEDBlue.get(uint8_t* buf) {
    getLed(buf, 2);
    signal LEDBlue.getDone(buf);
    return SUCCESS;
  }

  void getLed(uint8_t* buf, uint8_t ledNum) {
    uint8_t ledVal = call Leds.get();
    uint8_t ledOn = (ledVal & 1 << ledNum) >> ledNum;
    memcpy(buf, &ledOn, 1);
  }

  command result_t LEDRedSet.set(uint8_t* buf) {
    setLed(buf, 0);
    signal LEDRedSet.setDone(buf);
    return SUCCESS;
  }

  command result_t LEDGreenSet.set(uint8_t* buf) {
    setLed(buf, 1);
    signal LEDGreenSet.setDone(buf);
    return SUCCESS;
  }

  command result_t LEDBlueSet.set(uint8_t* buf) {
    setLed(buf, 2);
    signal LEDBlueSet.setDone(buf);
    return SUCCESS;
  }

  void setLed(uint8_t* buf, uint8_t ledNum) {
    uint8_t ledValue = call Leds.get();
    uint8_t ledSetting;
    memcpy(&ledSetting, buf, 1);
    if (ledSetting == 0) {
      ledValue = BIT_CLEAR(ledValue, ledNum);
    } else {
      ledValue = BIT_SET(ledValue, ledNum);
    }
    call Leds.set(ledValue);
  }
}

