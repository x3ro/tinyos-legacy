//$Id: DelugeStatsC.nc,v 1.2 2005/06/14 18:22:21 gtolle Exp $

configuration DelugeStatsC {

}
implementation {

  components DelugeStatsM;
  components DelugeMetadataC;

  DelugeStatsM.DelugeStats -> DelugeMetadataC;
}
