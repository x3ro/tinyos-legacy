includes DiagnosticMsg;

configuration Diagnostic {
}
implementation {
  components Main, DiagnosticM, GenericComm as Comm, ClockC, LedsC;

  Main.StdControl -> DiagnosticM.StdControl;
  DiagnosticM.Clock -> ClockC;
  DiagnosticM.Leds -> LedsC;
  DiagnosticM.CommControl -> Comm ;
  DiagnosticM.SendDiagMsg -> Comm.SendMsg[AM_DIAG_RESP];
  DiagnosticM.ReceiveDiagMsg -> Comm.ReceiveMsg[AM_DIAG_MSG];
}

