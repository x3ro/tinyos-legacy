
includes NestArch;

configuration testServiceControl
{
}
implementation
{
  components Main, testServiceControlM, ServiceControlC, ConfigC, TimerM, RoutingC;

  Main.StdControl -> testServiceControlM.StdControl;
  Main.StdControl -> ConfigC.StdControl;
  Main.StdControl -> RoutingC.StdControl;
  Main.StdControl -> TimerM;

  testServiceControlM.ServiceControlControl -> ServiceControlC.StdControl;
  testServiceControlM.Timer -> TimerM.Timer[unique("Timer")];

  ServiceControlC.ServiceControl[1] -> testServiceControlM.LambControl;
  ServiceControlC.ServiceControl[1] -> testServiceControlM.WolfControl;
  ServiceControlC.ServiceControl[2] -> testServiceControlM.WolfControl;
}

