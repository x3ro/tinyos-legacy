
module AMTestsC
{
  provides interface MsgTestAll as CrcTest;
  provides interface MsgTestAny as LocalGroupTest;
  provides interface MsgTestAny as LocalAddressTest;
  provides interface MsgTestAny as BroadcastAddressTest;
}
implementation
{
  command bool_all_t CrcTest.passes( TOS_MsgPtr msg ) {
    return msg->crc == 1;
  }

  command bool_any_t LocalGroupTest.passes( TOS_MsgPtr msg ) {
    return msg->group == TOS_AM_GROUP;
  }

  command bool_any_t LocalAddressTest.passes( TOS_MsgPtr msg ) {
    return msg->addr == TOS_LOCAL_ADDRESS;
  }

  command bool_any_t BroadcastAddressTest.passes( TOS_MsgPtr msg ) {
    return msg->addr == TOS_BCAST_ADDR;
  }
}

