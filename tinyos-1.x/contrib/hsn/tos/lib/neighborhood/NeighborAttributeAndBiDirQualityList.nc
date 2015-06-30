includes WSN_Settings;
configuration NeighborAttributeAndBiDirQualityList
{
   provides {
      interface Neighbors;
      interface NeighborAge;
      interface StdControl;
      interface NeighborQuality;
      interface Piggyback;
      interface Settings[uint8_t id];
      interface NeighborAttr;
   }
   uses {
      interface SequenceNumber;
   }
}

implementation {
   components NeighborsM, NeighborAgeM, NeighborHistoryM,
              NeighborExchangeInfoM, NeighborAttrM, TimerC, LedsC;

   NeighborsM.StdControl = StdControl;
   NeighborsM.Neighbors = Neighbors;
   NeighborAgeM.NeighborAge = NeighborAge;
   NeighborExchangeInfoM.NeighborBiDirQuality = NeighborQuality;
   NeighborExchangeInfoM.Piggyback = Piggyback;
   NeighborHistoryM.SequenceNumber = SequenceNumber;

   NeighborAttrM.NeighborAttr = NeighborAttr;

   NeighborHistoryM.Settings = Settings[SETTING_ID_NBR_HISTORY];
   NeighborExchangeInfoM.Settings = Settings[SETTING_ID_NBR_QUALITY];

   NeighborsM.PickForDeletion -> NeighborHistoryM.PickLowestQuality;

   NeighborsM.ModuleControl -> NeighborAgeM;
   NeighborsM.ModuleControl -> NeighborHistoryM;
   NeighborsM.ModuleControl -> NeighborExchangeInfoM;
   NeighborsM.ModuleControl -> NeighborAttrM;

   NeighborsM.NeighborMgmt <- NeighborAgeM;
   NeighborsM.NeighborMgmt <- NeighborHistoryM;
   NeighborsM.NeighborMgmt <- NeighborExchangeInfoM;
   NeighborsM.NeighborMgmt <- NeighborAttrM;

   NeighborAgeM.Trigger -> NeighborHistoryM.NodeHistory;
   NeighborAgeM.NodeAge <- NeighborHistoryM.NodeAge;
   NeighborExchangeInfoM.NodeHistory -> NeighborHistoryM.NodeHistory;

   NeighborAgeM.Timer -> TimerC.Timer[unique("Timer")];
   NeighborHistoryM.Timer -> TimerC.Timer[unique("Timer")];

   NeighborHistoryM.Leds -> LedsC;
   NeighborAgeM.Leds -> LedsC;
}
