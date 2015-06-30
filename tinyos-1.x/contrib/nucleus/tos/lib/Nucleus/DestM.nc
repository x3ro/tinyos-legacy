//$Id: DestM.nc,v 1.3 2005/06/14 18:10:10 gtolle Exp $

module DestM {
  provides interface Dest;
}

implementation {

  command void* Dest.getBuffer(DestMsg* destMsg) {
    return &destMsg->data;
  }

  command bool Dest.isIntermediary(DestMsg* destMsg) {
    return (destMsg->ttl > 1);
  }

  command result_t Dest.prepareRebroadcast(DestMsg *destMsg) {
    if (destMsg->ttl > 1) {
      destMsg->ttl--;
    }
    return SUCCESS;
  }
  
  command bool Dest.isEndpoint(DestMsg* destMsg) {

    return (destMsg->addr == TOS_LOCAL_ADDRESS ||
	    destMsg->addr == TOS_BCAST_ADDR);
  }
}
