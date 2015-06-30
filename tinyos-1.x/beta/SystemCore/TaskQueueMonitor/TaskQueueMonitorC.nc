configuration TaskQueueMonitorC {
  provides interface StdControl;
}
implementation {
  
  components 
  TaskQueueMonitorM,
    MgmtAttrsC;

  StdControl = TaskQueueMonitorM;
  
  TaskQueueMonitorM.MA_TaskQueueDiscards -> MgmtAttrsC.MgmtAttr[unique("MgmtAttr")];
  
}
