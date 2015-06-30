includes WSN;
includes WSN_Messages;
includes WSN_Settings;

configuration TraceRouteAODV {
   provides {
      interface StdControl as Control;
      interface Intercept;
   }
   uses {
      interface Piggyback;
   }
}

implementation {
   components TraceRoute_AODVM, 
              TimerC, 
#if SINK_NODE
              UART_Gateway as UART,
#else
              NoUART as UART,
#endif
       AODV as RoutingLayer,
       LedsC;

   Control = TraceRoute_AODVM.Control;
   Piggyback = TraceRoute_AODVM.Piggyback;
   Intercept = TraceRoute_AODVM.Intercept;


   TraceRoute_AODVM.Timer->TimerC.Timer[unique("Timer")];
   TraceRoute_AODVM.MHopControl -> RoutingLayer;
   TraceRoute_AODVM.Send -> RoutingLayer.Send[APP_ID_TRACEROUTE];
   TraceRoute_AODVM.Receive -> RoutingLayer.Receive[APP_ID_TRACEROUTE];
   TraceRoute_AODVM.MultiHopIntercept -> RoutingLayer.Intercept[APP_ID_TRACEROUTE];
   TraceRoute_AODVM.UARTControl -> UART;
   TraceRoute_AODVM.UARTSend -> UART;
   TraceRoute_AODVM.MultiHopMsg -> RoutingLayer;
   TraceRoute_AODVM.SingleHopMsg -> RoutingLayer;
   TraceRoute_AODVM.Leds -> LedsC;
}
