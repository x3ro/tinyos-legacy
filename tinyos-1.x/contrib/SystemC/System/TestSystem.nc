
configuration TestSystem
{
}
implementation
{
  components Main, SystemC;
  Main.StdControl -> SystemC;
}

