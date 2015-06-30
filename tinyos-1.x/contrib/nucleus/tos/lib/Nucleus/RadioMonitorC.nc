//$Id: RadioMonitorC.nc,v 1.2 2005/06/14 18:10:10 gtolle Exp $

includes RadioMonitor;

configuration RadioMonitorC {
  provides interface StdControl;
} 
implementation {
  
  components
    RadioMonitorM,
    CC2420RadioM,
    AttrsC;
  
  StdControl = RadioMonitorM;

  RadioMonitorM.SendStats -> CC2420RadioM.SendStats;
  RadioMonitorM.ReceiveStats -> CC2420RadioM.ReceiveStats;

  RadioMonitorM.MA_InPackets -> AttrsC.AttrServer[MA_RadioMonitor_InPackets_ATTR];
  RadioMonitorM.MA_InBytes -> AttrsC.AttrServer[MA_RadioMonitor_InBytes_ATTR];
  RadioMonitorM.MA_InErrors -> AttrsC.AttrServer[MA_RadioMonitor_InErrors_ATTR];
  RadioMonitorM.MA_OutPackets -> AttrsC.AttrServer[MA_RadioMonitor_OutPackets_ATTR];
  RadioMonitorM.MA_OutBytes -> AttrsC.AttrServer[MA_RadioMonitor_OutBytes_ATTR];
  RadioMonitorM.MA_OutErrors -> AttrsC.AttrServer[MA_RadioMonitor_OutErrors_ATTR];
}
