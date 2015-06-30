includes AMEnhanced;

module AMNamingM {
  provides interface Naming;
}

implementation {

  command void* Naming.getBuffer(NamingMsg* namingMsg) {
    return &namingMsg->data;
  }

  command bool Naming.isIntermediary(NamingMsg* namingMsg) {
    if (namingMsg->ttl > 1)
      return TRUE; 
    else
      return FALSE;
  }

  command result_t Naming.prepareRebroadcast(TOS_MsgPtr msg, 
					     NamingMsg *namingMsg) {
    if (namingMsg->group == TOS_BCAST_GROUP)
      msg->group = namingMsg->group;

    if (namingMsg->ttl > 1) {
      namingMsg->ttl--;
    }
    return SUCCESS;
  }

  command bool Naming.isEndpoint(NamingMsg* namingMsg) {
    if (namingMsg->addr == TOS_LOCAL_ADDRESS ||
	namingMsg->addr == TOS_BCAST_ADDR) {
      return TRUE;
    } else {
      return FALSE;
    }
  }
}
