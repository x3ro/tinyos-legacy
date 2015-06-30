configuration OPmclosure
{
  provides interface MateBytecode;
}
implementation {
  components MOPclosureM, MProxy;

  MateBytecode = MOPclosureM;

  MOPclosureM.C -> MProxy;
  MOPclosureM.RawLV -> MProxy.RawLV;
  MOPclosureM.RawCV -> MProxy.RawCV;
  MOPclosureM.S -> MProxy;
  MOPclosureM.V -> MProxy;
  MOPclosureM.T -> MProxy;
}
