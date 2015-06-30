configuration NeighborAttributeList
{
   provides {
      interface Neighbors;
      interface NeighborAge;
      interface StdControl;
      interface NeighborAttr;
   }
}
implementation {
   components NeighborsM, NeighborAgeM, NeighborAttrM, TimerC;

   NeighborsM.StdControl = StdControl;
   NeighborsM.Neighbors = Neighbors;
   NeighborAgeM.NeighborAge = NeighborAge;
   NeighborAttrM.NeighborAttr = NeighborAttr;

   NeighborsM.PickForDeletion -> NeighborAgeM.PickOldest;
   NeighborsM.ModuleControl -> NeighborAgeM;
   NeighborsM.ModuleControl -> NeighborAttrM;
   NeighborsM.NeighborMgmt <- NeighborAgeM;
   NeighborsM.NeighborMgmt <- NeighborAttrM;

   NeighborAgeM.Timer -> TimerC.Timer[unique("Timer")];
}
