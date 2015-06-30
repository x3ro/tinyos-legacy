/*
 * Note that the variable 'PIRSimpleThreshEnabled' is meant to be
 * set by rpc.RamSymbols.poke().  We don't define a registry attribute
 * for this enable flag because of limitations on ROM size.
 *
 * @author Cory Sharp, Phoebus Chen
 * @modified 7/21/2005 copied and modified from PIRRawEventM.nc
 */

//$Id: PIRSimpleThreshEventM.nc,v 1.1 2005/07/22 20:37:46 phoebusc Exp $

module PIRSimpleThreshEventM
{
  uses interface DetectionEvent;
  uses interface Attribute<uint16_t> as PIRRawValue @registry("PIRRawValue");
  uses interface Attribute<uint16_t> as PIRRawThresh @registry("PIRRawThresh");
}
implementation
{
  bool PIRSimpleThreshEnabled = FALSE; // Meant to be set by RPC over the network

  event void PIRRawValue.updated( uint16_t data )
  {
    if( PIRSimpleThreshEnabled && call PIRRawThresh.valid() )
    {
      const uint16_t thresh = call PIRRawThresh.get();
      if( (data >= thresh) && (thresh != 65535U) )
      {
        call DetectionEvent.detected(data);
      }
    }
  }

  event void PIRRawThresh.updated( uint16_t thresh ) { }
}

