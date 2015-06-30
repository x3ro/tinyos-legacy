/** 
 * - Revision -------------------------------------------------------------
 * $Revision: 1.2 $
 * $Date: 2004/10/27 16:31:47 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
configuration TestTDA5250Receive {
}
implementation {
  components Main, LedsC, DataLinkC, TestTDA5250ReceiveM, TimerC; 

  Main.StdControl -> TestTDA5250ReceiveM;
  Main.StdControl -> DataLinkC;

  TestTDA5250ReceiveM.Leds -> LedsC;
  
  TestTDA5250ReceiveM.BareSendMsg -> DataLinkC;
  TestTDA5250ReceiveM.ReceiveMsg -> DataLinkC;
}

