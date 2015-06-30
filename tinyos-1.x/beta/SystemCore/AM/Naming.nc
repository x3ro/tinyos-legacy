includes AMNamingMsg;

interface Naming {
  command void *getBuffer(NamingMsg* namingMsg);
  command result_t prepareRebroadcast(TOS_MsgPtr msg, NamingMsg *namingMsg);
  command bool isIntermediary(NamingMsg* namingMsg);
  command bool isEndpoint(NamingMsg* namingMsg);
}
