/* 
*/

configuration SerialTest {
}
implementation {
  components Main, SerialTestM, HPLUARTC;
  Main.StdControl -> SerialTestM;
  SerialTestM.UART -> HPLUARTC;
}
