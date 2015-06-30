configuration MOPcst {
  provides {
    interface MateBytecode as Cst;
    interface MateBytecode as Int;
    interface MateBytecode as Undefined;
  }
}
implementation {
  components MOPcstM, MProxy;

  Cst = MOPcstM.Cst;
  Int = MOPcstM.Int;
  Undefined = MOPcstM.Undefined;

  MOPcstM.S -> MProxy;
  MOPcstM.C -> MProxy;
  MOPcstM.T -> MProxy;
}
