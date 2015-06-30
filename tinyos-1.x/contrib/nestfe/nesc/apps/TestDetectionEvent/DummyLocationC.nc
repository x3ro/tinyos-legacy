//$Id: DummyLocationC.nc,v 1.1 2005/07/06 16:57:18 cssharp Exp $

configuration DummyLocationC
{
}
implementation
{
  components DummyLocationM;
  components RegistryC;

  DummyLocationM.Location -> RegistryC.Location;
}

