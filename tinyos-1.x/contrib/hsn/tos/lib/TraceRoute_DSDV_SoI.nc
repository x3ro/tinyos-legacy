includes WSN;
includes WSN_Messages;
includes WSN_Settings;

configuration TraceRoute_DSDV_SoI {
   provides {
      interface StdControl as Control;
      interface Settings[uint8_t id];
      interface Intercept;
   }
   uses {
      interface Piggyback;
      interface Intercept as SoIIntercept;
   }
}

implementation {
   components TraceRouteM, 
              TimerC, 
#ifdef NETWORK_MODULE  // Can't wire whole UART, TinyDBShim also uses it
              UARTNoCRCPacketComm as UART,
#else
              UART_Gateway as UART,
#endif
              DSDV_SoI as RoutingLayer,
              LedsC;

   Control = TraceRouteM.Control;
   Piggyback = TraceRouteM.Piggyback;

   Settings[SETTING_ID_TRACEROUTE] = TraceRouteM.Settings;
   Settings = RoutingLayer.Settings;

   SoIIntercept = RoutingLayer.SoIPlugin;
   Intercept = TraceRouteM.Intercept;

   TraceRouteM.Timer->TimerC.Timer[unique("Timer")];
   TraceRouteM.MHopControl -> RoutingLayer;
   TraceRouteM.Send -> RoutingLayer.Send[APP_ID_TRACEROUTE_SOI];
   TraceRouteM.Receive -> RoutingLayer.Receive[APP_ID_TRACEROUTE_SOI];
   TraceRouteM.MultiHopIntercept -> RoutingLayer.Intercept[APP_ID_TRACEROUTE_SOI];
   TraceRouteM.UARTControl -> UART;
#ifdef NETWORK_MODULE
   TraceRouteM.UARTSend -> UART.BareSendMsg[APP_ID_TRACEROUTE_SOI];
#else
   TraceRouteM.UARTSend -> UART;
#endif
   TraceRouteM.MultiHopMsg -> RoutingLayer;
   TraceRouteM.SingleHopMsg -> RoutingLayer;
   TraceRouteM.Leds -> LedsC;
}
