configuration CycleCountsC {
     provides interface CycleCounts;
}
implementation {
     components CycleCountsM, PowerStateM;

     CycleCounts = CycleCountsM.CycleCounts;

     CycleCountsM.PowerState -> PowerStateM;
}
     
