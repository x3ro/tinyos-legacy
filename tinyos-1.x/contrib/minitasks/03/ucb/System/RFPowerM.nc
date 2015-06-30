
//!! Config 3 { uint16_t RFPower = 15; }

includes DefineCC1000;

module RFPowerM
{
  provides interface StdControl;
#if defined(RADIO_CC1000)
  uses interface CC1000Control;
#endif
  uses interface Config_RFPower;
}
implementation
{
#if defined(RADIO_CC1000)
  uint16_t GetRFPower()
  {
    return call CC1000Control.GetRFPower();
  }

  void SetRFPower( uint16_t rfpower )
  {
    call CC1000Control.SetRFPower( rfpower );
  }
#else
  uint16_t GetRFPower()
  {
    return 0;
  }

  void SetRFPower( uint16_t rfpower )
  {
  }
#endif

  command result_t StdControl.init()
  {
    G_Config.RFPower = GetRFPower();
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    G_Config.RFPower = GetRFPower();
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event void Config_RFPower.updated()
  {
    SetRFPower( G_Config.RFPower );
  }
}

