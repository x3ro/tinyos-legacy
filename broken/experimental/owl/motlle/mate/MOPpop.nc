configuration MOPpop {
  provides {
    interface MateBytecode as Pop;
    interface MateBytecode as ExitN;
  }
}
implementation {
  components MOPpopM, MProxy;

  Pop = MOPpopM.Pop;
  ExitN = MOPpopM.ExitN;
  MOPpopM.S -> MProxy;
  MOPpopM.C -> MProxy;
}
