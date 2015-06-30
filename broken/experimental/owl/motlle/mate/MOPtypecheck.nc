configuration MOPtypecheck {
  provides {
    interface MateBytecode as StackCheck;
    interface MateBytecode as VarCheck;
  }
}
implementation {
  components MOPtypecheckM, MProxy;

  StackCheck = MOPtypecheckM.StackCheck;
  VarCheck = MOPtypecheckM.VarCheck;
  MOPtypecheckM.C -> MProxy;
  MOPtypecheckM.S -> MProxy;
  MOPtypecheckM.T -> MProxy;
  MOPtypecheckM.E -> MProxy;
  MOPtypecheckM.LV -> MProxy.LV;
}
