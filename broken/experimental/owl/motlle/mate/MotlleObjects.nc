configuration MotlleObjects {
  provides interface MotlleTypes as T;
}
implementation {
  components MotlleObjectsM, MProxy;

  T = MotlleObjectsM;
  MotlleObjectsM.V -> MProxy;
  MotlleObjectsM.GC -> MProxy;
}
