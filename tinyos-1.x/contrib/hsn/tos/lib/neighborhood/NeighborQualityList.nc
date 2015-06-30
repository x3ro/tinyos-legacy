configuration NeighborQualityList
{
   provides {
      interface Neighbors;
      interface NeighborAge;
      interface StdControl;
      interface NeighborAttr;
      interface NeighborQuality;
   }
   uses {
      interface SequenceNumber;
   }
}
implementation {
   components NeighborsM, NeighborAgeM, NeighborAttrM, NeighborHistoryM, TimerC;

   NeighborsM.StdControl = StdControl;
   NeighborsM.Neighbors = Neighbors;
   NeighborAgeM.NeighborAge = NeighborAge;
   NeighborAttrM.NeighborAttr = NeighborAttr;
   NeighborHistoryM.NeighborQuality = NeighborQuality;
   NeighborHistoryM.SequenceNumber = SequenceNumber;

   NeighborsM.PickForDeletion -> NeighborHistoryM.PickLowestQuality;

   NeighborsM.ModuleControl -> NeighborAgeM;
   NeighborsM.ModuleControl -> NeighborAttrM;
   NeighborsM.ModuleControl -> NeighborHistoryM;
   NeighborsM.NeighborMgmt <- NeighborAgeM;
   NeighborsM.NeighborMgmt <- NeighborAttrM;
   NeighborsM.NeighborMgmt <- NeighborHistoryM;

   NeighborAgeM.Trigger -> NeighborHistoryM.NodeHistory;
   NeighborAgeM.NodeAge <- NeighborHistoryM.NodeAge;

   NeighborAgeM.Timer -> TimerC.Timer[unique("Timer")];
   NeighborHistoryM.Timer -> TimerC.Timer[unique("Timer")];
}
