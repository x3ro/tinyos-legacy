/* @modified 11/7/2005 added a Metrics module for changing RF power and
 *                     testing latency
 */
//$Id: TestDetectionEventC.nc,v 1.11 2005/11/13 22:01:06 phoebusc Exp $

includes DetectionEvent; //for definition of location_t type in RegistryC
includes MetricsMsg;
configuration TestDetectionEventC
{
}
implementation
{
  components Main;
  components KrakenC;
  components DetectionEventC;
  //  components DetectionLogC;
  //  components DummyLocationC;

  components KrakenMetricsC;

  components DummyEventGenC;
  components UserButtonEventC;
  components PIRSimpleThreshEventC;
  components PIRDetectEventC;

  Main.StdControl -> KrakenC;
  Main.StdControl -> DetectionEventC;
  //  Main.StdControl -> DetectionLogC;
  Main.StdControl -> KrakenMetricsC;

  //Comment these out as necessary (and above under 'components')
  //to save ROM space
  Main.StdControl -> DummyEventGenC;
  Main.StdControl -> UserButtonEventC;
  Main.StdControl -> PIRSimpleThreshEventC;
  Main.StdControl -> PIRDetectEventC;
}

