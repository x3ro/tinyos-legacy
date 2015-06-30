/* 
 * See PIRSimpleThreshEventM for comments on important parameters
 * not exported by the Registry or interfaces.
 *
 * @author Cory Sharp, Phoebus Chen
 * @modified 7/21/2005 copied and modified from PIRRawEventM.nc
 */

//$Id: PIRSimpleThreshEventC.nc,v 1.2 2005/08/04 23:43:47 phoebusc Exp $

includes DetectionEvent;

configuration PIRSimpleThreshEventC
{
  provides interface StdControl;
}
implementation
{
  components PIRSimpleThreshEventM;
  components PIRRawDriverC; //Communicates through RegistryC.PIRRawValue
  components DetectionEventC;
  components RegistryC;

  StdControl = PIRRawDriverC;

  PIRSimpleThreshEventM.DetectionEvent -> DetectionEventC.DetectionEvent[PIR_SIMPLE_THRESH];
  PIRSimpleThreshEventM.PIRRawValue -> RegistryC.PIRRawValue;
  PIRSimpleThreshEventM.PIRRawThresh -> RegistryC.PIRRawThresh;
}

