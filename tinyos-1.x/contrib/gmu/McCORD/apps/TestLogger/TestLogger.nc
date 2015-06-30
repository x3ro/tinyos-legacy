

configuration TestLogger { }
implementation
{
  components Main, TestLoggerM, Logger, UARTComm as Comm, LedsC;

  Main.StdControl -> TestLoggerM;

  TestLoggerM.LoggerInit -> Logger;
  TestLoggerM.LoggerRead -> Logger;
  TestLoggerM.LoggerWrite -> Logger;

  TestLoggerM.Leds -> LedsC;

  TestLoggerM.CommControl -> Comm;
  TestLoggerM.ReceiveTestMsg -> Comm.ReceiveMsg[100];
  TestLoggerM.SendResultMsg -> Comm.SendMsg[101];

}
