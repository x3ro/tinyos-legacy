/* 
 * PIRDetectEventM only serves as a bridge to interface DetectionEvent.
 * This allows the underlying PIR Detection module to interface with
 * other code without using interface DetectionEvent.
 *
 * @author Phoebus Chen
 * @modified 7/21/2005
 */
//$Id: PIRDetectEventM.nc,v 1.1 2005/07/22 20:37:46 phoebusc Exp $

module PIRDetectEventM
{
  uses interface DetectionEvent;
  uses interface Attribute<uint16_t> as PIRDetectValue @registry("PIRDetectValue");
}
implementation
{
  event void PIRDetectValue.updated( uint16_t data ) {
      call DetectionEvent.detected( data );
  }
}

