configuration MotlleRep
{
  provides interface MotlleValues as V;
}
implementation
{
  components MotlleRepM, MProxy;

  V = MotlleRepM;
  MotlleRepM.GC -> MProxy;
}
