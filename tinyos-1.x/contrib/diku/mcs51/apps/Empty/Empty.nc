/* 
*/

configuration Empty {
}
implementation {
  components Main, EmptyM;
  Main.StdControl -> EmptyM.StdControl;
}
