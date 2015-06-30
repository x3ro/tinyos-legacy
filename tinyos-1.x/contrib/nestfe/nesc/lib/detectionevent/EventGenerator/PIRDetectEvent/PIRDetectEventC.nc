/* 
 * The workhorse module for PIRDetectEvent is actually PIRDetectFilterM.
 * PIRDetectEventM is just a bridge between PIRDetectFilterM and
 * DetectionEventC.  See the comments in PIRDetectEventM for details.
 *
 * @author Cory Sharp, Phoebus Chen
 * @modified 7/21/2005
 */
//$Id: PIRDetectEventC.nc,v 1.2 2005/08/04 23:43:47 phoebusc Exp $

includes DetectionEvent;

configuration PIRDetectEventC
{
  provides interface StdControl;
}
implementation
{
  components PIRDetectEventM;
  components PIRDetectFilterC; //Communicates through RegistryC.PIRDetectValue
  components DetectionEventC;
  components RegistryC;

  StdControl = PIRDetectFilterC;

  PIRDetectEventM.DetectionEvent -> DetectionEventC.DetectionEvent[PIR_FILTER];
  PIRDetectEventM.PIRDetectValue -> RegistryC.PIRDetectValue;
}

