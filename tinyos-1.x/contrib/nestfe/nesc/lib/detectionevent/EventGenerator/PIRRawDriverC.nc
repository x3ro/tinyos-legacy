/* 
 * @author Cory Sharp, Phoebus Chen
 * @modified 7/22/2005 copied and modified from PirRawEventC.nc
 */

//$Id: PIRRawDriverC.nc,v 1.1 2005/07/22 20:37:46 phoebusc Exp $

configuration PIRRawDriverC
{
  provides interface StdControl;
}
implementation
{
  components PIRRawDriverM;
#ifdef PLATFORM_PC
  components FakePIRC as PIRC;
#else
  components PIRC;
#endif
  components TimerC;
  components RegistryC;

  StdControl = PIRC;

  PIRRawDriverM.PIR -> PIRC;
  PIRRawDriverM.ADC -> PIRC;
  PIRRawDriverM.Timer -> TimerC.Timer[unique("Timer")];
  PIRRawDriverM.PirSampleTimer -> RegistryC.PirSampleTimer;
  PIRRawDriverM.PIRRawValue -> RegistryC.PIRRawValue;
}
