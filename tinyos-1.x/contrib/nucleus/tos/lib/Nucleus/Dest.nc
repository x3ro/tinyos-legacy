//$Id: Dest.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

includes DestMsg;

interface Dest {
  command void *getBuffer(DestMsg* destMsg);
  command bool isIntermediary(DestMsg* destMsg);
  command bool isEndpoint(DestMsg* destMsg);
  command result_t prepareRebroadcast(DestMsg *destMsg);
}
