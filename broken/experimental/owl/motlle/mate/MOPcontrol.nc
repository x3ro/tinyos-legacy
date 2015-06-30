configuration MOPcontrol {
  provides {
    interface MateBytecode as Branch;
    interface MateBytecode as BranchIfFalse;
    interface MateBytecode as BranchIfTrue;
  }
}
implementation {
  components MOPcontrolM, MProxy;

  Branch = MOPcontrolM.Branch;
  BranchIfTrue = MOPcontrolM.BranchIfTrue;
  BranchIfFalse = MOPcontrolM.BranchIfFalse;

  MOPcontrolM.T -> MProxy;
  MOPcontrolM.S -> MProxy;
  MOPcontrolM.V -> MProxy;
  MOPcontrolM.C -> MProxy;
}
