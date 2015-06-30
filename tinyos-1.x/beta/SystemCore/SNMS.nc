configuration SNMS {
  provides interface StdControl;
}

implementation {
  
  components

    HelloC,
    
    DripC,
    MultiHopRSSI,

    EventLoggerC,
    MgmtQueryC,

    TaskQueueMonitorC,
    GrouperC;

#ifndef PLATFORM_PC
  components DelugeC, DelugeMonitorC, DelugeControlC, RebootC, PowerMgmtC;
#endif

  StdControl = HelloC;
  
#ifndef PLATFORM_PC
  HelloC.SNMSControl -> DelugeC;
  HelloC.SNMSControl -> DelugeMonitorC;
  HelloC.SNMSControl -> DelugeControlC;
  HelloC.SNMSControl -> RebootC;
  HelloC.SNMSControl -> PowerMgmtC;
#endif

  HelloC.SNMSControl -> DripC;
  HelloC.SNMSControl -> MultiHopRSSI;
  HelloC.SNMSControl -> MgmtQueryC;
  HelloC.SNMSControl -> EventLoggerC;
  HelloC.SNMSControl -> TaskQueueMonitorC;
  HelloC.SNMSControl -> GrouperC;
}
