
//!! Config 7 { uint8_t RFPowerMaxOverridePrev = 15; }

module RFPowerMaxOverrideM
{
  provides interface StdControl;
  uses interface StdControl as BottomStdControl;
  uses interface Config_RFPower;
}
implementation
{
  command result_t StdControl.init()
  {
    return call BottomStdControl.init();
  }

  command result_t StdControl.start()
  {
    G_Config.RFPowerMaxOverridePrev = G_Config.RFPower;
    call Config_RFPower.set( 255 );
    return call BottomStdControl.start();
  }

  command result_t StdControl.stop()
  {
    call Config_RFPower.set( G_Config.RFPowerMaxOverridePrev );
    return call BottomStdControl.stop();
  }

  event void Config_RFPower.updated()
  {
  }
}

