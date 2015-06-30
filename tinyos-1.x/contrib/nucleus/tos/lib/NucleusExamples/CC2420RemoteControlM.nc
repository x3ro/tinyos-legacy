includes CC2420RemoteControl;

module CC2420RemoteControlM {
  provides interface Attr<uint8_t> as CC2420RFPower @nucleusAttr("CC2420RFPower", ATTR_CC2420RFPower);
  provides interface AttrSet<uint8_t> as CC2420RFPowerSet @nucleusAttr("CC2420RFPower", ATTR_CC2420RFPower);

  provides interface Attr<uint8_t> as CC2420AckEnabled @nucleusAttr("CC2420AckEnabled", ATTR_CC2420AckEnabled);
  provides interface AttrSet<uint8_t> as CC2420AckEnabledSet @nucleusAttr("CC2420AckEnabled", ATTR_CC2420AckEnabled);

  provides interface Attr<uint8_t> as CC2420Channel @nucleusAttr("CC2420Channel", ATTR_CC2420Channel);
  provides interface AttrSet<uint8_t> as CC2420ChannelSet @nucleusAttr("CC2420Channel", ATTR_CC2420Channel);
    
  uses interface CC2420Control;
  uses interface MacControl;
}
implementation {
  uint8_t ackEnabled;

  command result_t CC2420RFPower.get(uint8_t* buf) {
    uint8_t value = call CC2420Control.GetRFPower();
    memcpy(buf, &value, 1);
    signal CC2420RFPower.getDone(buf);
    return SUCCESS;
  }

  command result_t CC2420RFPowerSet.set(uint8_t* buf) {
    uint8_t value;
    memcpy(&value, buf, 1);
    call CC2420Control.SetRFPower(value);
    signal CC2420RFPowerSet.setDone(buf);
    return SUCCESS;
  }

  command result_t CC2420AckEnabled.get(uint8_t* buf) {
    memcpy(buf, &ackEnabled, 1);
    signal CC2420AckEnabled.getDone(buf);
    return SUCCESS;
  }

  command result_t CC2420AckEnabledSet.set(uint8_t* buf) {
    uint8_t value;
    memcpy(&value, buf, 1);
    if (value == 1) {
      call MacControl.enableAck();
    } else if (value == 0) {
      call MacControl.disableAck();
    } else {
      return FAIL;
    }
    memcpy(&ackEnabled, &value, sizeof(uint8_t));
    signal CC2420AckEnabledSet.setDone(buf);
    return SUCCESS;
  }

  command result_t CC2420Channel.get(uint8_t* buf) {
    uint8_t channel;
    channel = call CC2420Control.GetPreset();
    memcpy(buf, &channel, sizeof(uint8_t));
    signal CC2420Channel.getDone(buf);
    return SUCCESS;
  }

  command result_t CC2420ChannelSet.set(uint8_t* buf) {
    uint8_t channel;
    memcpy(&channel, buf, sizeof(uint8_t));
    call CC2420Control.TunePreset(channel);
    signal CC2420ChannelSet.setDone(buf);
    return SUCCESS;
  }
}
