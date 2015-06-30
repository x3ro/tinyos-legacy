includes WSN;
includes WSN_Messages;
includes WSN_Settings;

configuration TraceRouteSoI {
}

implementation {
   components WSN_Main,
              TraceRouteSoIM, 
              TraceRoute_DSDV_SoI as TraceRoute, 
              GenericSettingsHandler,
#ifdef MEASURE_METRIC
              DSDV_SoI as DSDV,
              MetricMeasure,
#endif
              TimerC;

   TraceRouteSoIM.TimerControl -> TimerC;

   TraceRouteSoIM.Control <- WSN_Main;

   TraceRouteSoIM.TRControl -> TraceRoute;

#ifdef MEASURE_METRIC
   MetricMeasure.Control <- WSN_Main;
   MetricMeasure.Intercept -> TraceRoute.Intercept;
   MetricMeasure.Router -> DSDV.Router;
   MetricMeasure.MultiHopMsg -> DSDV.MultiHopMsg;
   TraceRoute.SoIIntercept -> MetricMeasure.AltIntercept;
#else
   TraceRoute.SoIIntercept -> TraceRoute.Intercept;
#endif

   TraceRouteSoIM.SettingsControl -> GenericSettingsHandler;
   TraceRoute.Piggyback -> GenericSettingsHandler;
   GenericSettingsHandler.Settings -> TraceRoute.Settings;

#ifdef MEASURE_METRIC
   GenericSettingsHandler.Settings[SETTING_ID_METRIC_MEASURE]
                              -> MetricMeasure.Settings;
#endif
}
