
// All "PEG Testbed" applications must build from this configuration.

// Basic system services
//   - Initialization Order
//       . Init[0] through Init[9] and Init[255] are RESERVED
//   - Service Control
//       . Service[0] through Service[9] and Service[255] are RESERVED
//   - Low Power State (OnOffC)
//   - Network Reprogrammable (XnpC)

// See TestSystem.nc for a very simple usage of SystemC.
// See ../PEGSensor/PEGSensorC.nc for usage by a real application.


//!! CommandHood = CreateNeighborhood( 0, CommandManager, BroadcastBackend, 180 );

includes DefineCC1000;
includes MsgBuffers;
includes Config;
includes Routing;
includes Neighborhood;
includes Ident;
includes ChangeGroupId;

configuration SystemC
{
  provides interface StdControl;
  uses interface StdControl as Init[ uint8_t init_order ];
  uses interface StdControl as Service[ uint8_t service_number ];
}
implementation
{
  components InitC
	   , ServiceC
	   , ConfigC
	   , ConfigStoreServiceC
	   , TimerC
	   , RoutingC
	   , CommandHoodC
	   , LowPowerStateC
    //	   , XnpServiceC
	   , ResetSystemC
	   , BlinkC
	   , DefaultServiceC
	   , IdentC
	   , ChangeGroupIdC
	   , RFPowerC
	   , RFPowerMaxOverrideC
	   ;

  StdControl = InitC;
  Init = InitC.Init;
  Service = ServiceC.Service;

  InitC.Init[0] -> ConfigC;
  InitC.Init[1] -> ConfigStoreServiceC;
  InitC.Init[2] -> TimerC;
  //  InitC.Init[3] -> XnpServiceC.XnpRequiredControl;
  InitC.Init[4] -> RoutingC;
  InitC.Init[5] -> RFPowerC;
  InitC.Init[6] -> CommandHoodC;
  InitC.Init[255] -> ServiceC;

  ServiceC.Service[0] -> LowPowerStateC;
  ServiceC.Service[1] -> RFPowerMaxOverrideC;
  //  RFPowerMaxOverrideC.BottomStdControl -> XnpServiceC.XnpServiceControl;
  ServiceC.Service[2] -> ResetSystemC;
  ServiceC.Service[3] -> BlinkC;
  ServiceC.Service[255] -> DefaultServiceC;
}

