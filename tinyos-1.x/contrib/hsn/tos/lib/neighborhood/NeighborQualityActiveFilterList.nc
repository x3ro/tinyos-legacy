configuration NeighborQualityActiveFilterList
{
   provides {
      interface Neighbors;
      interface NeighborAge;
      interface StdControl;
      interface NeighborAttr;
      interface NeighborQuality;
      interface NeighborIsActive;
   }
   uses {
      interface SequenceNumber;
   }
}
implementation {
   components NeighborsM, NeighborAgeM, NeighborAttrM, NeighborHistoryM, NeighborIsActiveM, TimerC;

   NeighborsM.StdControl = StdControl;
   NeighborsM.Neighbors = Neighbors;
   NeighborAgeM.NeighborAge = NeighborAge;
   NeighborAttrM.NeighborAttr = NeighborAttr;
   NeighborHistoryM.NeighborQuality = NeighborQuality;
   NeighborHistoryM.SequenceNumber = SequenceNumber;
   NeighborIsActiveM.NeighborIsActive = NeighborIsActive;

   NeighborsM.PickForDeletion -> NeighborHistoryM.PickLowestQuality;

   NeighborsM.ModuleControl -> NeighborAgeM;
   NeighborsM.ModuleControl -> NeighborAttrM;
   NeighborsM.ModuleControl -> NeighborHistoryM;
   NeighborsM.ModuleControl -> NeighborIsActiveM;
   NeighborsM.NeighborMgmt <- NeighborAgeM;
   NeighborsM.NeighborMgmt <- NeighborAttrM;
   NeighborsM.NeighborMgmt <- NeighborHistoryM;
   NeighborsM.NeighborMgmt <- NeighborIsActiveM;

   NeighborAgeM.Trigger -> NeighborHistoryM.NodeHistory;
   NeighborIsActiveM.NodeHistory -> NeighborHistoryM.NodeHistory;
   NeighborAgeM.NodeAge <- NeighborHistoryM.NodeAge;

   NeighborAgeM.Timer -> TimerC.Timer[unique("Timer")];
   NeighborHistoryM.Timer -> TimerC.Timer[unique("Timer")];
}
