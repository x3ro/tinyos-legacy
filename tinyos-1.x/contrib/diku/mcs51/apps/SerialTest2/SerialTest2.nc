/* 
*/

configuration SerialTest2 {
}
implementation {
  components Main, SerialTest2M, HPLUARTC;
  Main.StdControl -> SerialTest2M;
  SerialTest2M.UART -> HPLUARTC;
}
