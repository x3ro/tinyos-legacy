configuration MOPrel {
  provides interface MateBytecode as Rel;
}
implementation {
  components MOPrelM, MProxy;

  Rel = MOPrelM.Rel;
  MOPrelM.S -> MProxy;
  MOPrelM.T -> MProxy;
  MOPrelM.E -> MProxy;
}
