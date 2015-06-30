/** 
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2004/10/27 16:31:46 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
configuration TestTDA5250Send {
}
implementation {
  components Main, LedsC, DataLinkC, TestTDA5250SendM, TimerC, RandomLFSR; 

  Main.StdControl -> DataLinkC;
  Main.StdControl -> TestTDA5250SendM;
  Main.StdControl -> TimerC;

  TestTDA5250SendM.Leds -> LedsC;
  TestTDA5250SendM.TimeoutTimer -> TimerC.TimerJiffy[unique("TimerJiffy")];
  
  TestTDA5250SendM.BareSendMsg -> DataLinkC;
  TestTDA5250SendM.ReceiveMsg -> DataLinkC;
}

