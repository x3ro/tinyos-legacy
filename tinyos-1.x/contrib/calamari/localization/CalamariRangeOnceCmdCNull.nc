configuration CalamariRangeOnceCmdCNull
{
  provides interface CalamariRangeOnceCmd;
  provides interface StdControl;
}
implementation
{
  components CalamariRangeOnceCmdM, CommandHoodC, MsgBuffersC;

  CalamariRangeOnceCmd = CalamariRangeOnceCmdM.CalamariRangeOnceCmd;
  StdControl = CalamariRangeOnceCmdM.StdControl;

  CalamariRangeOnceCmdM.CommandHood_private -> CommandHoodC.CommandHood_private;
  CalamariRangeOnceCmdM.CallComm -> CommandHoodC.NeighborhoodComm[62];
  CalamariRangeOnceCmdM.ReturnComm -> CommandHoodC.NeighborhoodComm[63];

  CalamariRangeOnceCmdM.MsgBuffers -> MsgBuffersC;
}

