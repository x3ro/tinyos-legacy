configuration NeighborList
{
   provides {
      interface Neighbors;
      interface NeighborAge;
      interface StdControl;
   }
}
implementation {
   components NeighborsM, NeighborAgeM, TimerC;

   NeighborsM.StdControl = StdControl;
   NeighborsM.Neighbors = Neighbors;
   NeighborAgeM.NeighborAge = NeighborAge;

   NeighborsM.PickForDeletion -> NeighborAgeM.PickOldest;
   NeighborsM.ModuleControl -> NeighborAgeM;
   NeighborsM.NeighborMgmt <- NeighborAgeM;

   NeighborAgeM.Timer -> TimerC.Timer[unique("Timer")];
}
