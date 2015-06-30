interface AMPacket {
  command am_addr_t localAddress();
  command am_addr_t destination(TOSMsg* msg);
  command bool isForMe(TOSMsg* msg);
  command bool isAMPacket(TOSMsg* msg);
}



