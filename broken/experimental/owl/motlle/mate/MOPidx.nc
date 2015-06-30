configuration MOPidx {
  provides {
    interface MateBytecode as Set;
    interface MateBytecode as Ref;
  }
}
implementation {
  components MOPidxM, MProxy;

  Ref = MOPidxM.Ref;
  Set = MOPidxM.Set;

  MOPidxM.S -> MProxy;
  MOPidxM.V -> MProxy;
  MOPidxM.T -> MProxy;
  MOPidxM.E -> MProxy;
  MOPidxM.GC -> MProxy;
}
