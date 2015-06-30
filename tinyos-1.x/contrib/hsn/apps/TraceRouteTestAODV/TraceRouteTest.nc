configuration TraceRouteTest {
}

implementation {
   components WSN_Main,
              TraceRouteTestM, 
              TraceRouteAODV as TraceRoute, 
              TimerC;

   TraceRouteTestM.TimerControl -> TimerC;

   TraceRouteTestM.Control <- WSN_Main;

   TraceRouteTestM.TRControl -> TraceRoute;
}
