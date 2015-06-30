/**
*
*@author Robbie Adler
*
**/

configuration SensorboardFrameworkC{
    provides {
      interface StdControl;
      interface GenericSampling;
    }
    uses{
      interface BufferManagement;
      interface WriteData;
      interface SensorData[uint8_t dataChannel];
      interface DSPManager[uint8_t dataChannel];
      interface BoardManager;
    }
}

implementation {
#include "frameworkconfig.h"

  components SensorboardFrameworkM,
    Main,
    PXA27XWallClockM,
    TimerC,
    TriggerManagerM,
    ChannelManagerM,
    BufferManagementDispatchM,
#ifdef BLUSH_TRIGGER
    BluSHC,
#endif
#ifdef USE_UNIQUE_SEQUENCE_ID
    UniqueSequenceIDC,
#endif
    ChannelParamsManagerM;
    
    
  StdControl = SensorboardFrameworkM.StdControl;
  GenericSampling = SensorboardFrameworkM;
  
  SensorboardFrameworkM.DependentControl -> ChannelManagerM.StdControl;
  SensorboardFrameworkM.DependentControl -> ChannelParamsManagerM.StdControl;
  SensorboardFrameworkM.DependentControl -> TriggerManagerM.StdControl;

  SensorboardFrameworkM.ChannelManager -> ChannelManagerM;
  ChannelManagerM.TriggerManager -> TriggerManagerM;  
  ChannelManagerM.ChannelParamsManager -> ChannelParamsManagerM;
  
  
  BoardManager  = ChannelManagerM.BoardManager;
  DSPManager = ChannelManagerM.DSPManager;
  SensorData = TriggerManagerM.SensorData;
  BufferManagement =  BufferManagementDispatchM.OutsideBufferManagement;
  TriggerManagerM.BufferManagement-> BufferManagementDispatchM.InsideBufferManagement;
  ChannelManagerM.BufferManagement-> BufferManagementDispatchM.InsideBufferManagement;
  WriteData = ChannelManagerM;
      
  ChannelManagerM.ADCWarmupTimer -> TimerC.Timer[unique("Timer")];
  SensorboardFrameworkM.AcquisitionTimeout -> TimerC.Timer[unique("Timer")];
  
  ChannelManagerM.WallClock -> PXA27XWallClockM;
  Main.StdControl -> PXA27XWallClockM.StdControl;

#ifdef USE_UNIQUE_SEQUENCE_ID
  ChannelManagerM.UniqueSequenceID ->UniqueSequenceIDC.UniqueSequenceID;
  ChannelManagerM.UniqueSequenceIDControl ->UniqueSequenceIDC.StdControl;
#endif
  
  //-----------
  //BluSH commands
  
#ifdef BLUSH_TRIGGER
  BluSHC.BluSH_AppI[unique("BluSH")] -> TriggerManagerM.ForceTrigger;
#endif
}
