module CalamariRangeOnceCmdMNull
{
  provides interface CalamariRangeOnceCmd;
  provides interface StdControl;
}
implementation
{
  command result_t StdControl.init()
  {
    return SUCCESS;
  }

  command result_t StdControl.start()
  {
    return SUCCESS;
  }

  command result_t StdControl.stop()
  {
    return SUCCESS;
  }

      
  command result_t CalamariRangeOnceCmd.sendCall( nodeID_t id, CalamariRangeOnceCmdArgs_t args )
  {
    return SUCCESS;
  }

  command result_t CalamariRangeOnceCmd.sendReturn( CalamariRangeOnceCmdReturn_t rets )
  {
    return SUCCESS;
  }

  command result_t CalamariRangeOnceCmd.dropReturn()
  {
    return SUCCESS;
  }
}

