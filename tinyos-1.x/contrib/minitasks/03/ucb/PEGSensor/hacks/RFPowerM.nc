
//!! Config 3 { uint16_t RFPower = 15; }

module RFPowerM
{
  provides interface StdControl;
  uses interface Config_RFPower;
}
implementation
{
  command result_t StdControl.init()
  {
    G_Config.RFPower = 5;
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    G_Config.RFPower = 5;
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

  event void Config_RFPower.updated()
  {
  }
}

