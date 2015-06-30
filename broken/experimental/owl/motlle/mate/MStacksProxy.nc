configuration MStacksProxy {
  provides {
    interface MateStacks;
  }
}
implementation {
  components MateEmulation, MProxy;

  MateStacks = MateEmulation;
  MateEmulation.V -> MProxy;
  MateEmulation.S -> MProxy;
  MateEmulation.T -> MProxy;
  MateEmulation.E -> MProxy;
}
