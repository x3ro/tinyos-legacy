includes WSN_Settings;
includes WSN;
includes WSN_Messages;

configuration SoIMesh {
}

implementation {
   components WSN_Main,
              SoIMeshM, 
              TraceRoute_DSDV as TraceRoute, 
              GenericSettingsHandler,
              EnergyModel, 
              DSDV_Quality,
#ifdef SMAC_ENERGY
              SMAC,
#endif
              TimerC;

   SoIMeshM.TimerControl -> TimerC;

   SoIMeshM.Control <- WSN_Main;

   SoIMeshM.TRControl -> TraceRoute;

   SoIMeshM.SettingsControl -> GenericSettingsHandler;

   EnergyModel.Intercept -> TraceRoute.Intercept;
   EnergyModel.MultiHopMsg -> DSDV_Quality;
   EnergyModel.Control <- WSN_Main;
#ifdef SMAC_ENERGY
   EnergyModel.MACPerformance -> SMAC;
#endif

   GenericSettingsHandler.Settings -> TraceRoute.Settings;
}
